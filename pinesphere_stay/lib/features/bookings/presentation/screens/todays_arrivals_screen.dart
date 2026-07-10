import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TodaysArrivalsScreen extends StatelessWidget {
  const TodaysArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today\'s Arrivals'),
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
              DataColumn(label: Text('Check-in Time', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Number of Guests', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Number of Nights', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Booking Source', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Amount Due', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Booking Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Special Requests', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ID Verification', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Assigned Staff', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cottage Ready', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Arrival Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Parking Required', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Vehicle Number', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              _buildDummyRow(
                'BKG-10294', 'John Doe', '+1 555-0198', '302', 'Deluxe Suite', '14:00', '2', '3', 'Website',
                'Paid', '\$0.00', 'Confirmed', 'Honeymoon setup', 'Completed', 'Sarah (Housekeeping)', 'Ready',
                'Not Arrived', 'Yes', 'ABC-1234',
              ),
              _buildDummyRow(
                'BKG-10295', 'Alice Smith', '+44 7700 900077', '105', 'Twin Room', '15:30', '1', '1', 'Booking.com',
                'Pending', '\$85.00', 'Confirmed', 'None', 'Pending', 'Mike', 'Cleaning',
                'Not Arrived', 'No', '-',
              ),
              _buildDummyRow(
                'BKG-10296', 'Bob Johnson', '+1 555-0102', '212', 'Standard King', '13:00', '2 (1 child)', '2', 'Airbnb',
                'Partial', '\$45.00', 'Confirmed', 'Extra bed', 'Completed', 'Sarah', 'Maintenance',
                'Arrived', 'Yes', 'XYZ-9876',
              ),
              _buildDummyRow(
                'BKG-10297', 'Emma Davis', '+61 400 123 456', '401', 'Penthouse', '16:00', '4', '5', 'Walk-in',
                'Paid', '\$0.00', 'Confirmed', 'None', 'Completed', 'Jane (Manager)', 'Ready',
                'Checked In', 'Yes', 'DEF-5678',
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDummyRow(
      String c1, String c2, String c3, String c4, String c5, String c6, String c7, String c8, String c9, String c10,
      String c11, String c12, String c13, String c14, String c15, String c16, String c17, String c18, String c19) {
    return DataRow(
      cells: [
        DataCell(Text(c1)), DataCell(Text(c2)), DataCell(Text(c3)), DataCell(Text(c4)), DataCell(Text(c5)),
        DataCell(Text(c6)), DataCell(Text(c7)), DataCell(Text(c8)), DataCell(Text(c9)), DataCell(Text(c10)),
        DataCell(Text(c11)), DataCell(Text(c12)), DataCell(Text(c13)), DataCell(Text(c14)), DataCell(Text(c15)),
        DataCell(Text(c16)), DataCell(Text(c17)), DataCell(Text(c18)), DataCell(Text(c19)),
      ],
    );
  }
}
