import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/theme/app_theme.dart';
import 'package:pinesphere_stay/app/router/app_router.dart';
import 'package:pinesphere_stay/features/notifications/presentation/widgets/notification_overlay.dart';

class PinesphereApp extends ConsumerWidget {
  const PinesphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PineStay',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return NotificationOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
