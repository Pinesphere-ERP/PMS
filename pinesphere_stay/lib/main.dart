import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pinesphere_stay/app/app.dart';
import 'package:pinesphere_stay/core/database/database_service.dart';

late final IDatabaseService databaseService;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    databaseService = DatabaseService();
    await databaseService.init();
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize DatabaseService: $e');
    debugPrint(stackTrace.toString());
  }

  runApp(
    const ProviderScope(
      child: PinesphereApp(),
    ),
  );
}
