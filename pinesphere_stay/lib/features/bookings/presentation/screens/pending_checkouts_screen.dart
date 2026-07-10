import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PendingCheckoutsScreen extends StatelessWidget {
  const PendingCheckoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Checkouts'),
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
              DataColumn(label: Text('Room/Cottage Number', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Guest Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Check-in Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Scheduled Check-out Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Expected Check-out Time', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Number of Adults', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Number of Children', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Nights Stayed', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Booking Source', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Room Charges', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Additional Charges', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Taxes', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Bill Amount', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Security Deposit', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Deposit Refund Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Key Return Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ID Verification/Return Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Housekeeping Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Checkout Status', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              _buildDummyRow(
                '302', 'BKG-10101', 'James Smith', '+1 555-0991', 'Oct 20, 2024', 'Oct 24, 2024', '11:00 AM',
                '2', '0', '4', 'Website', '\$400.00', '\$40.00', '\$40.00', '\$0.00', '\$480.00', '\$480.00', '\$0.00',
                'Paid', '\$50.00', 'Refund Pending', 'Pending', 'Returned', 'Cleaning Started', 'Pending',
              ),
              _buildDummyRow(
                '105', 'BKG-10105', 'Maria Garcia', '+44 7700 900011', 'Oct 22, 2024', 'Oct 24, 2024', '10:30 AM',
                '1', '0', '2', 'Booking.com', '\$150.00', '\$10.00', '\$10.00', '\$0.00', '\$170.00', '\$150.00', '\$20.00',
                'Partial', '\$0.00', 'N/A', 'Pending', 'N/A', 'Pending', 'Pending',
              ),
              _buildDummyRow(
                '212', 'BKG-10112', 'David Chen', '+61 400 123 789', 'Oct 19, 2024', 'Oct 24, 2024', '12:00 PM',
                '2', '1', '5', 'Airbnb', '\$450.00', '\$0.00', '\$45.00', '\$20.00', '\$475.00', '\$475.00', '\$0.00',
                'Paid', '\$100.00', 'Refund Pending', 'Returned', 'Pending', 'Pending', 'Pending',
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
      String c21, String c22, String c23, String c24, String c25) {
    return DataRow(
      cells: [
        DataCell(Text(c1)), DataCell(Text(c2)), DataCell(Text(c3)), DataCell(Text(c4)), DataCell(Text(c5)),
        DataCell(Text(c6)), DataCell(Text(c7)), DataCell(Text(c8)), DataCell(Text(c9)), DataCell(Text(c10)),
        DataCell(Text(c11)), DataCell(Text(c12)), DataCell(Text(c13)), DataCell(Text(c14)), DataCell(Text(c15)),
        DataCell(Text(c16)), DataCell(Text(c17)), DataCell(Text(c18)), DataCell(Text(c19)), DataCell(Text(c20)),
        DataCell(Text(c21)), DataCell(Text(c22)), DataCell(Text(c23)), DataCell(Text(c24)), DataCell(Text(c25)),
      ],
    );
  }
}
