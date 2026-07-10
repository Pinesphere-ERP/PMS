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
import '../../features/bookings/presentation/screens/new_booking_screen.dart';
import '../../features/bookings/presentation/screens/pending_checkouts_screen.dart';
import '../../features/bookings/presentation/screens/todays_arrivals_screen.dart';
import '../../features/bookings/presentation/screens/todays_departures_screen.dart';
import '../../features/rooms/presentation/screens/occupied_rooms_screen.dart';
import '../../features/rooms/presentation/screens/vacant_rooms_screen.dart';
import '../../features/housekeeping/presentation/screens/housekeeping_screen.dart';
import '../../features/bookings/presentation/screens/pending_payments_screen.dart';
import '../../features/reports/presentation/screens/todays_revenue_screen.dart';
import '../../features/device_management/presentation/screens/device_registration_screen.dart';
import '../../features/device_management/presentation/screens/device_sync_status_screen.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final GlobalKey<NavigatorState> _roomsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rooms');
final GlobalKey<NavigatorState> _bookingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'bookings');
final GlobalKey<NavigatorState> _reportsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'reports');
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (authState == const AuthState.initial()) return null;

      final isAuth = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
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
      GoRoute(
        path: '/device-registration',
        builder: (context, state) => const DeviceRegistrationScreen(),
      ),
      GoRoute(
        path: '/device-status',
        builder: (context, state) => const DeviceSyncStatusScreen(),
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
              GoRoute(
                path: '/todays-arrivals',
                builder: (context, state) => const TodaysArrivalsScreen(),
              ),
              GoRoute(
                path: '/pending-checkouts',
                builder: (context, state) => const PendingCheckoutsScreen(),
              ),
              GoRoute(
                path: '/todays-departures',
                builder: (context, state) => const TodaysDeparturesScreen(),
              ),
              GoRoute(
                path: '/occupied-rooms',
                builder: (context, state) => const OccupiedRoomsScreen(),
              ),
              GoRoute(
                path: '/vacant-rooms',
                builder: (context, state) => const VacantRoomsScreen(),
              ),
              GoRoute(
                path: '/housekeeping',
                builder: (context, state) => const HousekeepingScreen(),
              ),
              GoRoute(
                path: '/pending-payments',
                builder: (context, state) => const PendingPaymentsScreen(),
              ),
              GoRoute(
                path: '/todays-revenue',
                builder: (context, state) => const TodaysRevenueScreen(),
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
                builder: (context, state) => const NewBookingScreen(),
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
