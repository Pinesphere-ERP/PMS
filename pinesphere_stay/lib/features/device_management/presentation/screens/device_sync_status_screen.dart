import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class DeviceSyncStatusScreen extends StatefulWidget {
  const DeviceSyncStatusScreen({super.key});

  @override
  State<DeviceSyncStatusScreen> createState() => _DeviceSyncStatusScreenState();
}

class _DeviceSyncStatusScreenState extends State<DeviceSyncStatusScreen> {
  String _authorizationState = 'ACTIVE'; // ACTIVE, PENDING_APPROVAL, LOCKED, REVOKED
  bool _isSyncing = false;
  int _pendingDeltaCount = 14;
  final int _roomsCount = 45;
  final int _bookingsCount = 128;
  final int _guestsCount = 310;
  String _lastSyncTime = 'Just now';

  final List<Map<String, String>> _localSyncLogs = [
    {'time': '10:14 AM', 'type': 'SYNC_CHECKIN', 'status': 'SUCCESS', 'msg': 'Pushed 14 bookings, pulled 2 room updates. RSA license valid.'},
    {'time': '09:00 AM', 'type': 'HEARTBEAT', 'status': 'SUCCESS', 'msg': 'Background sync check. Verified token signature with cloud.'},
    {'time': '08:30 AM', 'type': 'LOGIN', 'status': 'SUCCESS', 'msg': 'Operator Alicia (Receptionist) authenticated via PIN.'},
    {'time': 'Yesterday, 06:00 PM', 'type': 'OFFLINE_MODE', 'status': 'INFO', 'msg': 'Network disconnected. ObjectBox local fallback active.'},
  ];

  void _handleForceSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
      _pendingDeltaCount = 0;
      _lastSyncTime = 'Just now (Forced)';
      _localSyncLogs.insert(0, {
        'time': 'Just now',
        'type': 'FORCE_SYNC',
        'status': 'SUCCESS',
        'msg': 'Transmitted all pending local deltas. Database 100% aligned with cloud.',
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Force check-in completed! All offline records synced.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _simulateRemoteLockout() {
    setState(() => _authorizationState = 'LOCKED');
  }

  void _simulateRemoteRevoke() {
    setState(() => _authorizationState = 'REVOKED');
  }

  void _resetStatus() {
    setState(() {
      _authorizationState = 'ACTIVE';
      _pendingDeltaCount = 14;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Device Sync & Security Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _isSyncing ? null : _handleForceSync,
            tooltip: 'Force Sync Check-in',
          )
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Authorization Card
                  _buildAuthorizationCard(),
                  const SizedBox(height: 20),

                  // ObjectBox Offline DB Stats
                  _buildDatabaseStatsCard(),
                  const SizedBox(height: 20),

                  // Force Check-In Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isSyncing || _authorizationState != 'ACTIVE') ? null : _handleForceSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        _isSyncing ? 'Synchronizing with Cloud...' : 'Manual Force Check-In ($_pendingDeltaCount deltas pending)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Simulation Controls for Testing Admin/Mobile Interaction
                  _buildSimulationControls(),
                  const SizedBox(height: 28),

                  // Local Sync Log Inspector
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Immutable Local Telemetry Log',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      Text('Last 50 entries', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLogInspector(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Security Lockout / Revoked Overlay
          if (_authorizationState == 'LOCKED' || _authorizationState == 'REVOKED')
            _buildSecurityLockOverlay(),
        ],
      ),
    );
  }

  Widget _buildAuthorizationCard() {
    Color bgColor;
    Color borderColor;
    Color iconBg;
    Color textColor;
    IconData icon;
    String statusLabel;
    String desc;

    if (_authorizationState == 'ACTIVE') {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      iconBg = Colors.green.shade600;
      textColor = Colors.green.shade900;
      icon = Icons.verified;
      statusLabel = 'HARDWARE AUTHORIZED (ACTIVE)';
      desc = 'Terminal is cryptographically bound to Grand Plaza Hotel. Full offline operation and delta synchronization permitted.';
    } else if (_authorizationState == 'PENDING_APPROVAL') {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      iconBg = Colors.amber.shade700;
      textColor = Colors.amber.shade900;
      icon = Icons.hourglass_top;
      statusLabel = 'PENDING PROPERTY APPROVAL';
      desc = 'Hardware registration transmitted. Awaiting approval by property owner.';
    } else if (_authorizationState == 'LOCKED') {
      bgColor = Colors.purple.shade50;
      borderColor = Colors.purple.shade300;
      iconBg = Colors.purple.shade700;
      textColor = Colors.purple.shade900;
      icon = Icons.lock;
      statusLabel = 'REMOTE DEVICE LOCKOUT ACTIVE';
      desc = 'This device was locked remotely by the Property Owner or Super Admin.';
    } else {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      iconBg = Colors.red.shade700;
      textColor = Colors.red.shade900;
      icon = Icons.delete_forever;
      statusLabel = 'LICENSE REVOKED & WIPED';
      desc = 'Hardware license token invalidated. Local ObjectBox database purged per security protocol.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('UID: a89c-44e1-bb20-99f1 • Android 14', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.8), fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: TextStyle(fontSize: 13, color: textColor, height: 1.35)),
        ],
      ),
    );
  }

  Widget _buildDatabaseStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('ObjectBox Offline Database Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Text('LOCAL STORE OK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryFixedVariant)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatMetric('Rooms Count', '$_roomsCount items', Icons.hotel_outlined),
              const SizedBox(width: 12),
              _buildStatMetric('Active Bookings', '$_bookingsCount records', Icons.book_outlined),
              const SizedBox(width: 12),
              _buildStatMetric('Guest Profiles', '$_guestsCount cached', Icons.person_outline),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _pendingDeltaCount > 0 ? Colors.amber.shade50 : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pendingDeltaCount > 0 ? Colors.amber.shade300 : AppColors.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_sync, color: _pendingDeltaCount > 0 ? Colors.amber.shade800 : AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _pendingDeltaCount > 0 ? 'Pending Delta Records Waiting Sync:' : 'All Delta Records Synchronized',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _pendingDeltaCount > 0 ? Colors.amber.shade900 : AppColors.onSurface),
                    ),
                  ],
                ),
                Text(
                  '$_pendingDeltaCount items',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _pendingDeltaCount > 0 ? Colors.amber.shade900 : AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Last check-in completed: $_lastSyncTime', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 18, color: AppColors.onSurface),
              SizedBox(width: 8),
              Text('Developer / QA Simulation Controls', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Test how the offline mobile app reacts when remote commands are triggered from the Property Owner or Super Admin dashboard:',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateRemoteLockout,
                  icon: const Icon(Icons.lock, size: 16, color: Colors.purple),
                  label: const Text('Simulate Lockout', style: TextStyle(fontSize: 12, color: Colors.purple)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateRemoteRevoke,
                  icon: const Icon(Icons.delete_forever, size: 16, color: Colors.red),
                  label: const Text('Simulate Revoke', style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _resetStatus,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogInspector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _localSyncLogs.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.outlineVariant),
        itemBuilder: (context, idx) {
          final log = _localSyncLogs[idx];
          return Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: log['status'] == 'SUCCESS' ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log['type']!,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: log['status'] == 'SUCCESS' ? AppColors.onSecondaryFixedVariant : AppColors.onSurface),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log['msg']!, style: const TextStyle(fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(log['time']!, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityLockOverlay() {
    final isRevoked = _authorizationState == 'REVOKED';

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRevoked ? Icons.delete_forever_rounded : Icons.lock_person_rounded,
            size: 80,
            color: isRevoked ? Colors.red.shade400 : Colors.purple.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            isRevoked ? 'LICENSE REVOKED & DATA WIPED' : 'REMOTE DEVICE LOCKOUT ACTIVE',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isRevoked ? Colors.red.shade400 : Colors.purple.shade300, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isRevoked
                ? 'Your property hardware license (PINE-STAY-88B12A4F) has been revoked by the Property Owner or Super Admin.\n\nPer security compliance protocol (Section 4.3 & 8), all local ObjectBox database records (`rooms`, `bookings`, `guests`) have been permanently erased from internal flash memory.'
                : 'This terminal has been temporarily locked remotely from the Property Console. All local operator actions are blocked until the owner clicks "Unlock" on the administrative dashboard.',
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To unlock or re-activate, contact property management or call support at +1 (800) PINE-STAY.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          OutlinedButton.icon(
            onPressed: _resetStatus,
            icon: const Icon(Icons.developer_mode, color: Colors.white),
            label: const Text('Developer Override: Unlock Simulation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
