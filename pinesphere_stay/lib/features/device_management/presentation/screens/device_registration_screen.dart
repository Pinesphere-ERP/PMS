import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  State<DeviceRegistrationScreen> createState() => _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final TextEditingController _deviceNameController = TextEditingController(text: 'Reception Front Desk Pad');
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _deviceStatus = 'UNREGISTERED'; // UNREGISTERED, PENDING_APPROVAL, APPROVED
  final String _hardwareUid = 'a89c-44e1-bb20-99f1';
  bool _isLoading = false;

  void _handleRegister() async {
    if (_deviceNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a descriptive Device Name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _deviceStatus = 'PENDING_APPROVAL';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Handshake sent! Device Registration Pending Approval from Property Owner.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _inviteCodeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hardware Device Setup', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Banner
              _buildStatusBanner(),
              const SizedBox(height: 24),

              // Hardware Info Card
              _buildHardwareInfoCard(),
              const SizedBox(height: 24),

              if (_deviceStatus == 'UNREGISTERED') ...[
                const Text(
                  'Onboard Hardware Unit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register this terminal with your property cloud account. Once submitted, the Property Owner must approve this hardware unit before offline sync activates.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Device Name Input
                _buildInputLabel('Device Display Name'),
                TextField(
                  controller: _deviceNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Reception Pad #1, POS Bar Terminal',
                    prefixIcon: const Icon(Icons.tablet_mac, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                // QR / Invite Code Input
                _buildInputLabel('Property Invite / Pairing Code (Optional)'),
                TextField(
                  controller: _inviteCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter 8-digit invite code or scan property QR',
                    prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt, color: AppColors.onSurfaceVariant),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening camera scanner for property QR code...')),
                        );
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Operator PIN Confirmation
                _buildInputLabel('Operator Security PIN'),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter 4-6 digit staff PIN to bind terminal',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _isLoading ? 'Transmitting Handshake...' : 'Submit Hardware Registration',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else if (_deviceStatus == 'PENDING_APPROVAL') ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time_filled, size: 56, color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text(
                        'Handshake Transmitted Successfully',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hardware UID: $_hardwareUid\nLabel: "${_deviceNameController.text}"',
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your registration is currently queued on the property cloud console. Once the Property Owner or Super Admin clicks "Approve", the RSA offline cryptographic token will automatically download during the next check-in.',
                        style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _deviceStatus = 'APPROVED');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Simulated owner approval check: Token Verified! Device is now ACTIVE.')),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Check Approval Status'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, size: 56, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'Hardware Unit Approved & Active',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Offline cryptographic license signed and verified. This device has full permissions to operate offline and sync delta changes.',
                        style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/device-status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Go to Device Sync & Diagnostic Console'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    if (_deviceStatus == 'UNREGISTERED') {
      bgColor = AppColors.surfaceContainerLow;
      borderColor = AppColors.outlineVariant;
      textColor = AppColors.onSurfaceVariant;
      icon = Icons.phonelink_setup;
      title = 'Hardware Status: UNREGISTERED';
      subtitle = 'Terminal requires property cloud registration before offline operations.';
    } else if (_deviceStatus == 'PENDING_APPROVAL') {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      icon = Icons.hourglass_top;
      title = 'Hardware Status: PENDING APPROVAL';
      subtitle = 'Registration sent. Waiting for Property Owner approval on web console.';
    } else {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade900;
      icon = Icons.verified_user;
      title = 'Hardware Status: ACTIVE & APPROVED';
      subtitle = 'Offline RSA/HMAC license token active. Ready for synchronization.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: textColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.85), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HARDWARE FINGERPRINT (HMAC-SHA256)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.outline)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Device UID:', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
              Text(_hardwareUid, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OS / Build:', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
              Text('Android 14 (API 34) • v1.0.4', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage / Battery:', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
              Text('62 GB Free • 94% Charged', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
    );
  }
}
