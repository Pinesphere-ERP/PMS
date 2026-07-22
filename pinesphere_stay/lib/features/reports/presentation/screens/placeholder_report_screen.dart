import 'package:flutter/material.dart';

class PlaceholderReportScreen extends StatelessWidget {
  final String title;
  const PlaceholderReportScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title is currently being generated.\nPlease check back later.'),
      ),
    );
  }
}
