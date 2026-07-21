import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinesphere_stay/app/app.dart';
import 'package:pinesphere_stay/core/database/database_service.dart';

late final IDatabaseService databaseService;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  GoogleFonts.config.allowRuntimeFetching = true;

  // Suppress font fetch network logs when offline
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('google_fonts') || details.exceptionAsString().contains('fonts.gstatic.com')) {
      return;
    }
    if (originalOnError != null) {
      originalOnError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('google_fonts') || error.toString().contains('fonts.gstatic.com')) {
      return true;
    }
    return false;
  };

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
