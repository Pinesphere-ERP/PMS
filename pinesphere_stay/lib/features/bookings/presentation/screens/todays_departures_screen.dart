import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TodaysDeparturesScreen extends StatelessWidget {
  const TodaysDeparturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today\'s Departures'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerLowest),
            columns: const [
              DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Guest Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cottage/Room Number', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cottage Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Check-in Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Check-out Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Check-out Time', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Number of Guests', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Bill', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Amount Due', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Security Deposit', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Extra Charges', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Invoice Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Checkout Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Key Returned', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ID Returned', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Housekeeping Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cottage Availability', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Feedback Submitted', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              _buildDummyRow(
                'BKG-10101', 'James Smith', '+1 555-0991', '302', 'Deluxe Suite', 'Oct 20, 2024', 'Oct 24, 2024', '11:00 AM',
                '2', '\$480.00', '\$0.00', 'Paid', 'Refunded', 'None', 'Generated', 'Checked Out',
                'Yes', 'Yes', 'Cleaning Started', 'Cleaning', 'Yes', 'Great stay',
              ),
              _buildDummyRow(
                'BKG-10105', 'Maria Garcia', '+44 7700 900011', '105', 'Twin Room', 'Oct 22, 2024', 'Oct 24, 2024', '10:30 AM',
                '1', '\$170.00', '\$20.00', 'Partial', 'Refund Pending', 'Room Service', 'Pending', 'Pending',
                'No', 'No', 'Pending', 'Occupied', 'No', 'Needs early checkout',
              ),
              _buildDummyRow(
                'BKG-10112', 'David Chen', '+61 400 123 789', '212', 'Standard King', 'Oct 19, 2024', 'Oct 24, 2024', '12:00 PM',
                '3', '\$475.00', '\$0.00', 'Paid', 'Refund Pending', 'Laundry', 'Generated', 'Pending',
                'No', 'Yes', 'Pending', 'Occupied', 'No', '-',
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDummyRow(
      String c1, String c2, String c3, String c4, String c5, String c6, String c7, String c8, String c9, String c10,
      String c11, String c12, String c13, String c14, String c15, String c16, String c17, String c18, String c19, String c20,
      String c21, String c22) {
    return DataRow(
      cells: [
        DataCell(Text(c1)), DataCell(Text(c2)), DataCell(Text(c3)), DataCell(Text(c4)), DataCell(Text(c5)),
        DataCell(Text(c6)), DataCell(Text(c7)), DataCell(Text(c8)), DataCell(Text(c9)), DataCell(Text(c10)),
        DataCell(Text(c11)), DataCell(Text(c12)), DataCell(Text(c13)), DataCell(Text(c14)), DataCell(Text(c15)),
        DataCell(Text(c16)), DataCell(Text(c17)), DataCell(Text(c18)), DataCell(Text(c19)), DataCell(Text(c20)),
        DataCell(Text(c21)), DataCell(Text(c22)),
      ],
    );
  }
}
