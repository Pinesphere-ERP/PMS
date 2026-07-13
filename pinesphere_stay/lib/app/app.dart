import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/theme/app_theme.dart';
import 'package:pinesphere_stay/app/router/app_router.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

class PinesphereApp extends ConsumerWidget {
  const PinesphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Remove splash screen once the app is ready to render
    FlutterNativeSplash.remove();

    return MaterialApp.router(
      title: 'PineStay',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
