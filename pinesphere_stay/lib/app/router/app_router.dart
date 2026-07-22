import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_scaffold.dart';
import '../../core/auth/owner_onboarding_status.dart';
import '../../core/auth/session_context.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pin_login_screen.dart';
import '../../features/auth/presentation/screens/owner_registration_screen.dart';
import '../../features/requests/presentation/screens/requests_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/rooms/presentation/screens/room_grid_screen.dart';
import '../../features/reports/presentation/screens/reports_dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/property_settings_screen.dart';
import '../../features/bookings/presentation/screens/booking_list_screen.dart';
import '../../features/accountant/presentation/screens/accountant_dashboard_screen.dart';
import '../../features/accountant/presentation/screens/accountant_guest_detail_screen.dart';
import '../../features/accountant/presentation/screens/income_detail_screen.dart';
import '../../features/accountant/presentation/screens/expense_detail_screen.dart';
import '../../features/accountant/presentation/screens/profit_loss_screen.dart';
import '../../features/accountant/presentation/screens/gst_invoice_screen.dart';
import '../../features/accountant/presentation/screens/reports_manager_screen.dart';
import '../../features/bookings/presentation/screens/pending_checkouts_screen.dart';
import '../../features/bookings/presentation/screens/todays_arrivals_screen.dart';
import '../../features/bookings/presentation/screens/todays_departures_screen.dart';
import '../../features/rooms/presentation/screens/occupied_rooms_screen.dart';
import '../../features/rooms/presentation/screens/vacant_rooms_screen.dart';
import '../../features/housekeeping/presentation/screens/housekeeping_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_screen.dart';
import '../../features/bookings/presentation/screens/pending_payments_screen.dart';
import '../../features/reports/presentation/screens/todays_revenue_screen.dart';
import '../../features/device_management/presentation/screens/device_registration_screen.dart';
import '../../features/device_management/presentation/screens/device_sync_status_screen.dart';
import '../../features/checkin/presentation/screens/checkin_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/reports/presentation/screens/pl_report_screen.dart';
import '../../features/reports/presentation/screens/daily_report_screen.dart';
import '../../features/reports/presentation/screens/monthly_report_screen.dart';
import '../../features/reports/presentation/screens/outstanding_report_screen.dart';
import '../../features/reports/presentation/screens/revenue_report_screen.dart';
import '../../features/reports/presentation/screens/placeholder_report_screen.dart';
import '../../features/payments/presentation/payment_history_screen.dart';
import '../../features/payments/presentation/payment_collection_screen.dart';
import '../../features/audit/presentation/screens/audit_logs_screen.dart';
import '../../features/splash/presentation/custom_splash_screen.dart';
import '../../features/portal/presentation/screens/portal_login_screen.dart';
import '../../features/portal/presentation/screens/guest_dashboard_screen.dart';
import '../../features/housekeeping/presentation/screens/housekeeper_dashboard_screen.dart';
import '../../features/housekeeping/presentation/screens/housekeeper_room_detail_screen.dart';
import '../../features/housekeeping/presentation/screens/housekeeper_image_upload_screen.dart';

// Owner Platform screens
import '../../features/property_onboarding/presentation/screens/property_wizard_screen.dart';
import '../../features/user_role_management/presentation/screens/user_role_dashboard_screen.dart';

import '../../features/subscription_management/presentation/screens/subscription_screen.dart';
import '../../features/subscription_management/presentation/screens/subscription_expired_screen.dart';
import '../../features/staff/presentation/screens/staff_management_screen.dart';


part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

// ─── Routes exempt from all owner-journey guards ──────────────────────────────
const _ownerJourneyExempt = {
  '/splash',
  '/login',
  '/register',
  '/pin-login',
  '/portal/login',
  '/portal/dashboard',
  '/onboarding/property',
  '/onboarding/pending-approval',
  '/onboarding/rejected',
  '/subscription',
  '/subscription/expired',
  '/settings',          // Always accessible — even expired subscription
  '/property-settings',
};

// ─── RouterNotifier: triggers re-evaluation on auth or session state change ───
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
    _ref.listen<SessionContext>(
      sessionContextProvider,
      (_, _) => notifyListeners(),
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // ── Layer 0: Splash — always passthrough ────────────────────────────────
      if (location == '/splash') return null;

      // ── Layer 0b: Portal routes — independent auth ──────────────────────────
      if (location.startsWith('/portal')) {
        final guestToken = ref.read(guestTokenProvider);
        if (guestToken == null && location != '/portal/login') {
          return '/portal/login';
        }
        if (guestToken != null && location == '/portal/login') {
          return '/portal/dashboard';
        }
        return null;
      }

      final authState = ref.read(authProvider);

      // ── Layer 1: Auth Guard — not initialising ──────────────────────────────
      if (authState == const AuthState.initial()) return null;

      final isAuth = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLocked = authState.maybeWhen(
        locked: (_) => true,
        orElse: () => false,
      );
      final isUnauthenticated = !isAuth && !isLocked;

      // Must be on an auth-permitted route if unauthenticated
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/pin-login';

      if (isUnauthenticated && !isAuthRoute) return '/login';

      // ── Layer 2: Lock Guard ─────────────────────────────────────────────────
      if (isLocked && location != '/pin-login') return '/pin-login';

      // ── Layer 3: Role-based redirect from auth screens ─────────────────────
      if (isAuth && isAuthRoute) {
        return authState.maybeWhen(
          authenticated: (user) {
            final roleCode = (user.roleCode ?? user.role.name).toUpperCase();
            // Role-specific home screens
            if (roleCode == 'HOUSEKEEPING') return '/housekeeper-dashboard';
            if (roleCode == 'KITCHEN') return '/kitchen';
            if (roleCode == 'ACCOUNTANT') return '/accountant-dashboard';
            // All other roles land on dashboard (which has its own state guard)
            return '/dashboard';
          },
          orElse: () => '/dashboard',
        );
      }

      // ── Layer 4: Owner State Machine Guard ─────────────────────────────────
      // Only apply to OWNER role users navigating to non-exempt routes
      if (isAuth && !_ownerJourneyExempt.contains(location)) {
        final session = ref.read(sessionContextProvider);

        if (session.isOwner) {
          final ownerStatus = session.ownerStatus;

          switch (ownerStatus) {
            case OwnerOnboardingStatus.draft:
              if (!location.startsWith('/onboarding')) {
                return '/onboarding/property';
              }
              break;

            case OwnerOnboardingStatus.paymentPending:
              // Force to subscription screen
              if (location != '/subscription' && location != '/subscription/expired') {
                return '/subscription';
              }
              break;

            case OwnerOnboardingStatus.subscriptionExpired:
              // Only allow settings & subscription screen
              if (location != '/subscription' &&
                  location != '/subscription/expired' &&
                  location != '/settings' &&
                  location != '/property-settings') {
                return '/subscription/expired';
              }
              break;

            case OwnerOnboardingStatus.active:
            case OwnerOnboardingStatus.suspended:
            case OwnerOnboardingStatus.unknown:
              break;
          }
        }
      }

      return null;
    },
    routes: [
      // ── Public / Pre-Auth Routes ──────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CustomSplashScreen(),
      ),
      GoRoute(
        path: '/requests',
        builder: (context, state) => const RequestsScreen(),
      ),
      GoRoute(
        path: '/requests/create',
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const OwnerRegistrationScreen(),
      ),
      GoRoute(
        path: '/pin-login',
        builder: (context, state) => const PinLoginScreen(),
      ),

      // ── Portal Routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/portal/login',
        builder: (context, state) => const PortalLoginScreen(),
      ),
      GoRoute(
        path: '/portal/dashboard',
        builder: (context, state) => const GuestDashboardScreen(),
      ),

      // ── Owner Journey Routes ──────────────────────────────────────────────
      GoRoute(
        path: '/onboarding/property',
        builder: (context, state) => const PropertyWizardScreen(),
      ),

      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/subscription/expired',
        builder: (context, state) => const SubscriptionExpiredScreen(),
      ),

      // ── Device / Utility Routes ───────────────────────────────────────────
      GoRoute(
        path: '/device-registration',
        builder: (context, state) => const DeviceRegistrationScreen(),
      ),
      GoRoute(
        path: '/device-status',
        builder: (context, state) => const DeviceSyncStatusScreen(),
      ),
      GoRoute(
        path: '/property-settings',
        builder: (context, state) => const PropertySettingsScreen(),
      ),
      GoRoute(
        path: '/audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/pl-report',
        builder: (context, state) => const PLReportScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: '/user-roles',
        builder: (context, state) => const UserRoleDashboardScreen(),
      ),
      GoRoute(
        path: '/housekeeper-dashboard',
        builder: (context, state) => const HousekeeperDashboardScreen(),
      ),
      GoRoute(
        path: '/housekeeper/room/:id',
        builder: (context, state) => HousekeeperRoomDetailScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/housekeeper/room/:id/upload',
        builder: (context, state) => HousekeeperImageUploadScreen(roomId: state.pathParameters['id']!),
      ),

      // ── Main App Shell (StatefulShellRoute) ────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell, routerState: state);
        },
        branches: [
          // Branch 0: Dashboard & operations
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
              GoRoute(
                path: '/checkin',
                builder: (context, state) => CheckInScreen(initialBookingData: state.extra as Map<String, dynamic>?),
              ),
              GoRoute(
                path: '/checkout',
                builder: (context, state) => const CheckOutScreen(),
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
                path: '/kitchen',
                builder: (context, state) => const KitchenScreen(),
              ),
              GoRoute(
                path: '/pending-payments',
                builder: (context, state) => const PendingPaymentsScreen(),
              ),
              GoRoute(
                path: '/todays-revenue',
                builder: (context, state) => const TodaysRevenueScreen(),
              ),
              GoRoute(
                path: '/payments',
                builder: (context, state) => const PaymentHistoryScreen(),
              ),
              GoRoute(
                path: '/payment-collection',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final bookingId = extra?['bookingId'] as String? ?? state.uri.queryParameters['bookingId'];
                  final invoiceId = extra?['invoiceId'] as String? ?? state.uri.queryParameters['invoiceId'];
                  final amountStr = extra?['amount'] as String? ?? state.uri.queryParameters['amount'];
                  final initialAmount = amountStr != null ? double.tryParse(amountStr) : null;
                  return PaymentCollectionScreen(
                    bookingId: bookingId,
                    invoiceId: invoiceId,
                    initialAmount: initialAmount,
                  );
                },
              ),
              GoRoute(
                path: '/accountant-dashboard',
                builder: (context, state) => const AccountantDashboardScreen(),
              ),
              GoRoute(
                path: '/accountant-guest/:id',
                builder: (context, state) => AccountantGuestDetailScreen(bookingId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/accountant/income',
                builder: (context, state) => const IncomeDetailScreen(),
              ),
              GoRoute(
                path: '/accountant/expenses',
                builder: (context, state) => const ExpenseDetailScreen(),
              ),
              GoRoute(
                path: '/accountant/profit-loss',
                builder: (context, state) => const ProfitLossScreen(),
              ),
              GoRoute(
                path: '/accountant/gst-invoices',
                builder: (context, state) => const GSTInvoiceScreen(),
              ),
              GoRoute(
                path: '/accountant/reports',
                builder: (context, state) => const ReportsManagerScreen(),
              ),
            ],
          ),
          // Branch 1: Rooms
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (context, state) => const RoomGridScreen(),
              ),
            ],
          ),
          // Branch 2: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const BookingListScreen(),
              ),
            ],
          ),
          // Branch 3: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'daily',
                    builder: (context, state) => const DailyReportScreen(),
                  ),
                  GoRoute(
                    path: 'monthly',
                    builder: (context, state) => const MonthlyReportScreen(),
                  ),
                  GoRoute(
                    path: 'outstanding',
                    builder: (context, state) => const OutstandingReportScreen(),
                  ),
                  GoRoute(
                    path: 'revenue',
                    builder: (context, state) => const RevenueReportScreen(),
                  ),
                  GoRoute(
                    path: 'occupancy',
                    builder: (context, state) => const PlaceholderReportScreen(title: 'Occupancy Report'),
                  ),
                  GoRoute(
                    path: 'collection',
                    builder: (context, state) => const PlaceholderReportScreen(title: 'Collection Report'),
                  ),
                  GoRoute(
                    path: 'expenses',
                    builder: (context, state) => const PlaceholderReportScreen(title: 'Expenses Report'),
                  ),
                  GoRoute(
                    path: 'best-customers',
                    builder: (context, state) => const PlaceholderReportScreen(title: 'Best Customers Report'),
                  ),
                  GoRoute(
                    path: 'room-utilization',
                    builder: (context, state) => const PlaceholderReportScreen(title: 'Room Utilization Report'),
                  ),
                  GoRoute(
                    path: 'staff-performance',
                    builder: (context, state) => const PlaceholderReportScreen(title: 'Staff Performance Report'),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
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
