import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize ObjectBox
  // TODO: Initialize WorkManager
  // TODO: Initialize Shared Preferences / Secure Storage

  runApp(
    const ProviderScope(
      child: PinesphereApp(),
    ),
  );
}
