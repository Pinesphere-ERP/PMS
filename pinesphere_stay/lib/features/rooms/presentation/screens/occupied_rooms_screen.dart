import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OccupiedRoomsScreen extends StatelessWidget {
  const OccupiedRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Occupied Rooms'),
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
              DataColumn(label: Text('Cottage/Room Number', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cottage Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Guest Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Check-in Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Check-out Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nights Stayed', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nights Remaining', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Number of Guests', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Occupancy Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Amount Due', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Booking Source', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Housekeeping Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Special Requests', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Last Room Service', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Current Bill', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ID Verification', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Assigned Staff', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              _buildDummyRow(
                '302', 'Deluxe Suite', 'John Doe', 'BKG-10294', '+1 555-0198', 'Oct 23, 2024', 'Oct 26, 2024', '1', '2', '2',
                'Occupied', 'Paid', '\$0.00', 'Website', 'Cleaned', 'Extra pillows', '10:30 AM', '\$0.00', 'Verified',
                'Sarah (Housekeeping)', 'VIP Guest',
              ),
              _buildDummyRow(
                '105', 'Twin Room', 'Alice Smith', 'BKG-10295', '+44 7700 900077', 'Oct 24, 2024', 'Oct 25, 2024', '0', '1', '1',
                'Occupied', 'Pending', '\$85.00', 'Booking.com', 'Requested', 'Late check-out', '-', '\$105.00', 'Pending',
                'Mike', '-',
              ),
              _buildDummyRow(
                '212', 'Standard King', 'Bob Johnson', 'BKG-10296', '+1 555-0102', 'Oct 21, 2024', 'Oct 25, 2024', '3', '1', '3',
                'Occupied', 'Partial', '\$45.00', 'Airbnb', 'Do Not Disturb', 'Extra bed', 'Yesterday 4:00 PM', '\$120.00', 'Verified',
                'Sarah', 'Check AC',
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
      String c21) {
    return DataRow(
      cells: [
        DataCell(Text(c1)), DataCell(Text(c2)), DataCell(Text(c3)), DataCell(Text(c4)), DataCell(Text(c5)),
        DataCell(Text(c6)), DataCell(Text(c7)), DataCell(Text(c8)), DataCell(Text(c9)), DataCell(Text(c10)),
        DataCell(Text(c11)), DataCell(Text(c12)), DataCell(Text(c13)), DataCell(Text(c14)), DataCell(Text(c15)),
        DataCell(Text(c16)), DataCell(Text(c17)), DataCell(Text(c18)), DataCell(Text(c19)), DataCell(Text(c20)),
        DataCell(Text(c21)),
      ],
    );
  }
}
