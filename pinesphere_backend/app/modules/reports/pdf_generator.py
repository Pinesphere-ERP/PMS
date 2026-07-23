import uuid
from datetime import date, datetime
from typing import Optional
from io import BytesIO

from fastapi import HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.infra.models import Property
from app.modules.reports import service


async def _get_property_info(db: AsyncSession, property_id: uuid.UUID) -> dict:
    result = await db.execute(select(Property).where(Property.property_id == property_id))
    prop = result.scalars().first()
    if not prop:
        return {"name": "Property", "address": ""}
    return {"name": prop.property_name, "address": getattr(prop, "address", "") or ""}


def _build_pdf_header(property_info: dict, report_title: str, generated_at: str, filters: dict):
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import mm
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

    styles = getSampleStyleSheet()
    elements = []

    title_style = ParagraphStyle(
        'ReportTitle', parent=styles['Title'],
        fontSize=22, textColor=colors.HexColor('#004D40'),
        spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        'Subtitle', parent=styles['Normal'],
        fontSize=12, textColor=colors.HexColor('#666666'),
        spaceAfter=2
    )
    filter_style = ParagraphStyle(
        'FilterText', parent=styles['Normal'],
        fontSize=9, textColor=colors.HexColor('#888888'),
    )

    elements.append(Paragraph(property_info["name"], title_style))
    elements.append(Paragraph(report_title, subtitle_style))
    elements.append(Paragraph(f"Generated: {generated_at}", filter_style))

    filter_parts = []
    for k, v in filters.items():
        if v is not None:
            filter_parts.append(f"{k}: {v}")
    if filter_parts:
        elements.append(Paragraph("Filters: " + " | ".join(filter_parts), filter_style))

    elements.append(Spacer(1, 8 * mm))
    return elements


def _build_pdf_table(headers: list, rows: list, col_widths: list = None):
    from reportlab.lib import colors
    from reportlab.platypus import Table, TableStyle

    data = [headers] + rows
    t = Table(data, colWidths=col_widths, repeatRows=1)
    style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#004D40')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('ALIGN', (1, 1), (-1, -1), 'RIGHT'),
        ('ALIGN', (0, 1), (0, -1), 'LEFT'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 4),
        ('TOPPADDING', (0, 1), (-1, -1), 4),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F5F5F5')]),
        ('LINEBELOW', (0, 0), (-1, 0), 1, colors.HexColor('#004D40')),
        ('LINEBELOW', (0, -1), (-1, -1), 0.5, colors.HexColor('#CCCCCC')),
        ('GRID', (0, 0), (-1, -1), 0.25, colors.HexColor('#E0E0E0')),
    ])
    t.setStyle(style)
    return t


def _build_pdf_footer():
    from reportlab.platypus import Spacer
    from reportlab.lib.units import mm
    return [Spacer(1, 10 * mm)]


def _build_and_return(pdf_doc, filename: str):
    buffer = BytesIO()
    pdf_doc.build(buffer)
    buffer.seek(0)
    return StreamingResponse(
        buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


async def generate_report_pdf(
    db: AsyncSession,
    report_type: str,
    property_id: uuid.UUID,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    report_date: Optional[date] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    room_type: Optional[str] = None,
    category: Optional[str] = None,
    staff_id: Optional[uuid.UUID] = None,
):
    from reportlab.lib.pagesizes import A4
    from reportlab.platypus import SimpleDocTemplate, Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet

    property_info = await _get_property_info(db, property_id)
    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M")
    buf = BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, leftMargin=25 * 1.0, rightMargin=25 * 1.0,
                            topMargin=20 * 1.0, bottomMargin=20 * 1.0)
    styles = getSampleStyleSheet()
    elements = []

    if report_type == "daily":
        rd = report_date or date.today()
        result = await service.get_daily_report(db, property_id, rd)
        filters = {"Date": str(rd)}
        elements = _build_pdf_header(property_info, "Daily Report", generated_at, filters)
        elements.extend(_build_daily_pdf(result))

    elif report_type == "monthly":
        if not month or not year:
            raise HTTPException(400, "month and year required")
        result = await service.get_monthly_report(db, property_id, month, year)
        filters = {"Month": month, "Year": year}
        elements = _build_pdf_header(property_info, "Monthly Report", generated_at, filters)
        elements.extend(_build_monthly_pdf(result))

    elif report_type == "occupancy":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_occupancy_report(db, property_id, start_date, end_date, room_type)
        filters = {"From": str(start_date), "To": str(end_date), "Room Type": room_type}
        elements = _build_pdf_header(property_info, "Occupancy Report", generated_at, filters)
        elements.extend(_build_occupancy_pdf(result))

    elif report_type == "revenue":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_revenue_report(db, property_id, start_date, end_date)
        filters = {"From": str(start_date), "To": str(end_date)}
        elements = _build_pdf_header(property_info, "Revenue Report", generated_at, filters)
        elements.extend(_build_revenue_pdf(result))

    elif report_type == "collection":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_collection_report(db, property_id, start_date, end_date)
        filters = {"From": str(start_date), "To": str(end_date)}
        elements = _build_pdf_header(property_info, "Collection Report", generated_at, filters)
        elements.extend(_build_collection_pdf(result))

    elif report_type == "outstanding":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_outstanding_report(db, property_id, start_date, end_date)
        filters = {"From": str(start_date), "To": str(end_date)}
        elements = _build_pdf_header(property_info, "Outstanding Report", generated_at, filters)
        elements.extend(_build_outstanding_pdf(result))

    elif report_type == "expenses":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_expenses_report(db, property_id, start_date, end_date, category)
        filters = {"From": str(start_date), "To": str(end_date), "Category": category}
        elements = _build_pdf_header(property_info, "Expenses Report", generated_at, filters)
        elements.extend(_build_expenses_pdf(result))

    elif report_type == "best_customers":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_best_customers_report(db, property_id, start_date, end_date)
        filters = {"From": str(start_date), "To": str(end_date)}
        elements = _build_pdf_header(property_info, "Best Customers Report", generated_at, filters)
        elements.extend(_build_best_customers_pdf(result))

    elif report_type == "room_utilization":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_room_utilization_report(db, property_id, start_date, end_date, room_type)
        filters = {"From": str(start_date), "To": str(end_date), "Room Type": room_type}
        elements = _build_pdf_header(property_info, "Room Utilization Report", generated_at, filters)
        elements.extend(_build_room_utilization_pdf(result))

    elif report_type == "staff_performance":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_staff_performance_report(db, property_id, start_date, end_date, staff_id)
        filters = {"From": str(start_date), "To": str(end_date)}
        elements = _build_pdf_header(property_info, "Staff Performance Report", generated_at, filters)
        elements.extend(_build_staff_performance_pdf(result))

    elif report_type == "pl":
        if not start_date or not end_date:
            raise HTTPException(400, "start_date and end_date required")
        result = await service.get_pl_report(db, property_id, start_date, end_date)
        filters = {"From": str(start_date), "To": str(end_date)}
        elements = _build_pdf_header(property_info, "Profit & Loss Report", generated_at, filters)
        elements.extend(_build_pl_pdf(result))

    else:
        raise HTTPException(404, f"PDF not available for report type: {report_type}")

    elements.extend(_build_pdf_footer())
    doc.build(elements)
    buf.seek(0)
    filename = f"{property_info['name'].replace(' ', '_')}_{report_type}_report.pdf"
    return StreamingResponse(
        buf, media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


def _fmt(val):
    if isinstance(val, float):
        return f"₹{val:,.2f}"
    return str(val)


def _build_daily_pdf(r):
    from reportlab.platypus import Table, Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    kpi_data = [
        ["Metric", "Value"],
        ["Report Date", str(r.report_date)],
        ["Total Rooms", str(r.total_rooms)],
        ["Occupied Rooms", str(r.occupied_rooms)],
        ["Vacant Rooms", str(r.vacant_rooms)],
        ["Occupancy %", f"{r.occupancy_pct}%"],
        ["Total Check-ins", str(r.total_checkins)],
        ["Total Check-outs", str(r.total_checkouts)],
        ["New Bookings", str(r.new_bookings)],
        ["Cancelled Bookings", str(r.cancelled_bookings)],
        ["Revenue Collected", _fmt(r.revenue_collected)],
        ["Pending Payments", _fmt(r.pending_payments)],
        ["Housekeeping Completed", str(r.housekeeping_completed)],
        ["Housekeeping Pending", str(r.housekeeping_pending)],
    ]
    elements.append(_build_pdf_table(kpi_data[0], kpi_data[1:], col_widths=[200, 200]))
    return elements


def _build_monthly_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(
        f"Summary: {r.total_bookings} bookings | Occupancy: {r.occupancy_pct}% | "
        f"Revenue: {_fmt(r.total_revenue)} | Expenses: {_fmt(r.total_expenses)}",
        styles['Normal']
    ))
    elements.append(Spacer(1, 4 * mm))

    if r.daily_revenue_trend:
        headers = ["Date", "Revenue"]
        rows = [[str(d["date"]), _fmt(d["revenue"])] for d in r.daily_revenue_trend]
        elements.append(_build_pdf_table(headers, rows, col_widths=[200, 200]))

    return elements


def _build_occupancy_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(
        f"Average Occupancy: {r.avg_occupancy_pct}% | "
        f"Occupied Room-Nights: {r.occupied_room_nights} / {r.available_room_nights} | "
        f"Reserved Today: {r.reserved_rooms_today}",
        styles['Normal']
    ))
    elements.append(Spacer(1, 4 * mm))

    if r.by_room_type:
        headers = ["Room Type", "Count", "Occupancy %"]
        rows = [[str(t["room_type"]), str(t["count"]), f"{t.get('occupancy_pct', 0)}%"] for t in r.by_room_type]
        elements.append(_build_pdf_table(headers, rows, col_widths=[180, 120, 120]))

    if r.daily_occupancy:
        elements.append(Spacer(1, 4 * mm))
        headers = ["Date", "Occupied", "Vacant", "%"]
        rows = [[str(d["date"]), str(d["occupied"]), str(d["vacant"]), f"{d['pct']}%"] for d in r.daily_occupancy[:30]]
        elements.append(_build_pdf_table(headers, rows, col_widths=[120, 100, 100, 100]))

    return elements


def _build_revenue_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(
        f"Total Revenue: {_fmt(r.total_revenue)} | Taxes: {_fmt(r.taxes_collected)} | Discounts: {_fmt(r.discounts_given)}",
        styles['Normal']
    ))
    elements.append(Spacer(1, 4 * mm))

    if r.by_room_type:
        elements.append(Paragraph("Revenue by Room Type", styles['Heading3']))
        headers = ["Room Type", "Revenue"]
        rows = [[str(t["room_type"]), _fmt(t["revenue"])] for t in r.by_room_type]
        elements.append(_build_pdf_table(headers, rows, col_widths=[200, 200]))
        elements.append(Spacer(1, 3 * mm))

    if r.by_booking_source:
        elements.append(Paragraph("Revenue by Booking Source", styles['Heading3']))
        headers = ["Source", "Revenue"]
        rows = [[str(s["source"]), _fmt(s["revenue"])] for s in r.by_booking_source]
        elements.append(_build_pdf_table(headers, rows, col_widths=[200, 200]))
        elements.append(Spacer(1, 3 * mm))

    if r.by_payment_method:
        elements.append(Paragraph("Revenue by Payment Method", styles['Heading3']))
        headers = ["Method", "Revenue"]
        rows = [[str(m["method"]), _fmt(m["revenue"])] for m in r.by_payment_method]
        elements.append(_build_pdf_table(headers, rows, col_widths=[200, 200]))

    return elements


def _build_collection_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(f"Total Collections: {_fmt(r.total_collections)}", styles['Normal']))
    elements.append(Spacer(1, 3 * mm))

    summary_data = [
        ["Payment Method", "Amount"],
        ["Cash", _fmt(r.cash_collections)],
        ["Card", _fmt(r.card_collections)],
        ["UPI", _fmt(r.upi_collections)],
        ["Bank Transfer", _fmt(r.bank_transfer_collections)],
        ["Other", _fmt(r.other_collections)],
    ]
    elements.append(_build_pdf_table(summary_data[0], summary_data[1:], col_widths=[200, 200]))
    elements.append(Spacer(1, 4 * mm))

    if r.daily_collections:
        elements.append(Paragraph("Daily Collections", styles['Heading3']))
        headers = ["Date", "Amount"]
        rows = [[str(d["date"]), _fmt(d["amount"])] for d in r.daily_collections]
        elements.append(_build_pdf_table(headers, rows, col_widths=[200, 200]))

    return elements


def _build_outstanding_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(
        f"Total Outstanding: {_fmt(r.total_outstanding)} | "
        f"Pending Invoices: {r.pending_invoices_count} | "
        f"Overdue: {r.overdue_count}",
        styles['Normal']
    ))
    elements.append(Spacer(1, 3 * mm))

    if r.ageing:
        elements.append(Paragraph("Ageing Analysis", styles['Heading3']))
        headers = ["Ageing Bucket", "Amount"]
        rows = [[k, _fmt(v)] for k, v in r.ageing.items()]
        elements.append(_build_pdf_table(headers, rows, col_widths=[200, 200]))
        elements.append(Spacer(1, 3 * mm))

    if r.customer_wise:
        elements.append(Paragraph("Customer-wise Outstanding", styles['Heading3']))
        headers = ["Guest Name", "Amount", "Booking Ref", "Due Date"]
        rows = [[str(c["guest_name"]), _fmt(c["amount"]), str(c["booking_ref"]), str(c["due_date"])] for c in r.customer_wise[:30]]
        elements.append(_build_pdf_table(headers, rows, col_widths=[130, 100, 100, 100]))

    return elements


def _build_expenses_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(f"Total Expenses: {_fmt(r.total_expenses)}", styles['Normal']))
    elements.append(Spacer(1, 3 * mm))

    if r.by_category:
        elements.append(Paragraph("Expenses by Category", styles['Heading3']))
        headers = ["Category", "Amount", "Count"]
        rows = [[str(c["category"]), _fmt(c["amount"]), str(c["count"])] for c in r.by_category]
        elements.append(_build_pdf_table(headers, rows, col_widths=[180, 120, 100]))
        elements.append(Spacer(1, 3 * mm))

    if r.recent_expenses:
        elements.append(Paragraph("Recent Expenses", styles['Heading3']))
        headers = ["Date", "Category", "Description", "Amount"]
        rows = [
            [str(e.expense_date), str(e.category), str(e.description)[:40], _fmt(e.amount)]
            for e in r.recent_expenses[:20]
        ]
        elements.append(_build_pdf_table(headers, rows, col_widths=[80, 90, 160, 90]))

    return elements


def _build_best_customers_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    if r.customers:
        headers = ["#", "Guest Name", "Bookings", "Nights", "Total Revenue", "Avg Value", "Last Stay"]
        rows = [
            [str(i + 1), str(c.guest_name), str(c.total_bookings), str(c.total_nights),
             _fmt(c.total_revenue), _fmt(c.avg_booking_value), str(c.last_stay_date or "N/A")]
            for i, c in enumerate(r.customers)
        ]
        elements.append(_build_pdf_table(headers, rows, col_widths=[25, 100, 55, 50, 80, 70, 80]))

    return elements


def _build_room_utilization_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    if r.most_utilized:
        elements.append(Paragraph(
            f"Most Utilized: {r.most_utilized} | Least Utilized: {r.least_utilized or 'N/A'}",
            styles['Normal']
        ))
        elements.append(Spacer(1, 3 * mm))

    if r.rooms:
        headers = ["Room #", "Type", "Bookings", "Occupied Nights", "Idle Days", "Occupancy %", "Revenue"]
        rows = [
            [str(room.room_number), str(room.room_type), str(room.total_bookings),
             str(room.occupied_nights), str(room.idle_days), f"{room.occupancy_pct}%", _fmt(room.revenue)]
            for room in r.rooms
        ]
        elements.append(_build_pdf_table(headers, rows, col_widths=[50, 70, 55, 70, 55, 65, 80]))

    return elements


def _build_staff_performance_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(
        f"Total Tasks Completed: {r.total_tasks_completed} | Total Pending: {r.total_tasks_pending}",
        styles['Normal']
    ))
    elements.append(Spacer(1, 3 * mm))

    if r.staff:
        headers = ["Staff Name", "Role", "Completed", "Pending", "HK Tasks", "Bookings"]
        rows = [
            [str(s.staff_name), str(s.role), str(s.tasks_completed), str(s.tasks_pending),
             str(s.housekeeping_tasks), str(s.bookings_handled)]
            for s in r.staff
        ]
        elements.append(_build_pdf_table(headers, rows, col_widths=[100, 80, 65, 55, 65, 65]))

    return elements


def _build_pl_pdf(r):
    from reportlab.platypus import Spacer, Paragraph
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm

    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(
        f"Total Revenue: {_fmt(r.summary_total_revenue)} | "
        f"Total Expenses: {_fmt(r.summary_total_expenses)} | "
        f"Net Profit: {_fmt(r.summary_net_profit)}",
        styles['Normal']
    ))
    elements.append(Spacer(1, 4 * mm))

    if r.monthly_breakdown:
        headers = ["Month", "Room Rent", "Addons", "Revenue", "Expenses", "Net Profit", "GST", "Outstanding"]
        rows = [
            [str(m.month), _fmt(m.total_room_rent), _fmt(m.total_addons), _fmt(m.total_revenue),
             _fmt(m.total_expenses), _fmt(m.net_profit), _fmt(m.gst_collected), _fmt(m.outstanding)]
            for m in r.monthly_breakdown
        ]
        elements.append(_build_pdf_table(headers, rows, col_widths=[65, 60, 50, 60, 60, 60, 50, 55]))

    return elements
