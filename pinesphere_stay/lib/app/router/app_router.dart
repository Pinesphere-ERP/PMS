import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_scaffold.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/pin_login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/rooms/presentation/screens/room_grid_screen.dart';
import '../../features/reports/presentation/screens/reports_dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final GlobalKey<NavigatorState> _roomsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rooms');
final GlobalKey<NavigatorState> _bookingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'bookings');
final GlobalKey<NavigatorState> _reportsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'reports');
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState == const AuthState.initial()) return null;

      final isAuth = authState == const AuthState.authenticated();
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }

      if (isAuth && isGoingToLogin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const PinLoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _roomsNavigatorKey,
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (context, state) => const RoomGridScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _bookingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Bookings'))),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _reportsNavigatorKey,
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
