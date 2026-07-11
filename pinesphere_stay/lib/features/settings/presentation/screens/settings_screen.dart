import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: replace with real propertyId and deviceUid from auth state
      ref.read(settingsProvider.notifier).loadPropertySettings('demo-property-id', 'demo-device-uid');
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(context),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Account & Property'),
                  _buildMenuGroup(context, [
                    _buildMenuItem(context, Icons.domain, 'Property Information'),
                    _buildMenuItem(context, Icons.badge_outlined, 'Staff Management'),
                    _buildMenuItem(context, Icons.credit_card, 'Subscription', isLast: true),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Property Settings'),
                  _buildPropertySettingsSection(context, settingsState),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'App Preferences'),
                  _buildDeviceSettingsSection(context, settingsState),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Hardware & Device Management'),
                  _buildMenuGroup(context, [
                    _buildMenuItem(
                      context,
                      Icons.devices_other,
                      'Hardware Sync & Security Console',
                      onTap: () => context.push('/device-status'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                        child: Text('Active', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSecondaryFixedVariant, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      Icons.phonelink_setup,
                      'Register / Bind Hardware Unit',
                      onTap: () => context.push('/device-registration'),
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Data Management'),
                  _buildMenuGroup(context, [
                    _buildMenuItem(
                      context,
                      Icons.cloud_done_outlined,
                      'Offline Database Status',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                        child: Text('Synced', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSecondaryFixedVariant)),
                      ),
                    ),
                    _buildMenuItem(context, Icons.backup_outlined, 'Backup'),
                    _buildMenuItem(context, Icons.restore, 'Restore', isLast: true),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Support'),
                  _buildMenuGroup(context, [
                    _buildMenuItem(context, Icons.info_outline, 'About Application'),
                    _buildMenuItem(context, Icons.description_outlined, 'Terms & Conditions', isLast: true),
                  ]),
                  const SizedBox(height: 32),
                  _buildSignOutButton(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySettingsSection(BuildContext context, SettingsState state) {
    if (state is SettingsStateLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is SettingsStateError) {
      return _buildMenuGroup(context, [
        _buildMenuItem(context, Icons.error_outline, 'Failed to load settings: ${state.message}'),
      ]);
    }
    if (state is SettingsStateLoaded) {
      final settings = state.propertySettings;
      if (settings.isEmpty) {
        return _buildMenuGroup(context, [
          _buildMenuItem(context, Icons.add_circle_outline, 'No property settings configured', isLast: true),
        ]);
      }
      return _buildMenuGroup(context, [
        for (int i = 0; i < settings.length; i++)
          _buildMenuItem(
            context,
            _iconForSettingKey(settings[i]['setting_key'] ?? ''),
            _labelForSettingKey(settings[i]['setting_key'] ?? ''),
            trailing: Text(
              settings[i]['setting_value']?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            isLast: i == settings.length - 1,
          ),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _buildDeviceSettingsSection(BuildContext context, SettingsState state) {
    bool biometricEnabled = false;
    if (state is SettingsStateLoaded) {
      biometricEnabled = state.deviceConfig.biometricEnabled;
    }
    return _buildMenuGroup(context, [
      _buildMenuItem(
        context,
        Icons.fingerprint,
        'Biometric Authentication',
        trailing: Switch(
          value: biometricEnabled,
          onChanged: (v) {
            ref.read(settingsProvider.notifier).updateDeviceConfig(
              'demo-device-uid',
              biometricEnabled: v,
            );
          },
          activeColor: AppColors.primary,
        ),
      ),
      _buildMenuItem(context, Icons.dark_mode_outlined, 'Dark Mode', trailing: Switch(value: false, onChanged: (v) {}, activeColor: AppColors.primary)),
      _buildMenuItem(context, Icons.print_outlined, 'Printer Settings', isLast: true),
    ]);
  }

  IconData _iconForSettingKey(String key) {
    switch (key) {
      case 'CHECK_IN_TIME':
      case 'CHECK_OUT_TIME':
        return Icons.access_time;
      case 'TAX_PERCENT':
      case 'GST_NUMBER':
        return Icons.receipt_long;
      case 'CURRENCY':
        return Icons.monetization_on;
      case 'ACCEPTED_IDS':
        return Icons.badge;
      case 'PET_POLICY':
        return Icons.pets;
      case 'COUPLE_FRIENDLY':
        return Icons.favorite_outline;
      default:
        return Icons.settings;
    }
  }

  String _labelForSettingKey(String key) {
    switch (key) {
      case 'CHECK_IN_TIME':
        return 'Check-In Time';
      case 'CHECK_OUT_TIME':
        return 'Check-Out Time';
      case 'TAX_PERCENT':
        return 'Tax Percentage';
      case 'GST_NUMBER':
        return 'GST Number';
      case 'CURRENCY':
        return 'Default Currency';
      case 'ACCEPTED_IDS':
        return 'Accepted ID Types';
      case 'PET_POLICY':
        return 'Pet Policy';
      case 'COUPLE_FRIENDLY':
        return 'Couple Friendly';
      case 'EXTRA_ADULT_CHARGE':
        return 'Extra Adult Charge';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
      title: Text(
        'Pinesphere Stay',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer,
              border: Border.all(color: AppColors.outlineVariant),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDHDTQ9zQMQv36v5MruggzGzEYYivoRLG2o5ebi4VCmuGM7rCYdx5hazoFqXGvRG6MFcM94o8UsYiXo6EHN2YwPJzuCdhZ9MOy1N_fV_5mrHrJtu9nLwMf4PAXbaLwW-u3P-XXn6OrvyMCzRdOTx2hvm4EEViCooVpI2bUyrv_WMEoszFIdd4bovbvvxSHiK-PxiJqHZfZPwybir7BXMIdyUNY5w3Li0OWrbZzi7PtBeyoeJgYW2srBrA'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_florist, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pinesphere Admin', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurface)),
              Text('Property Manager • v1.0.4', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              letterSpacing: 2.0,
            ),
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {bool isLast = false, Widget? trailing, VoidCallback? onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
                  ),
                ),
                trailing ?? const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.surfaceVariant),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Pinesphere Stay Android v1.0.4-stable',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant.withOpacity(0.5)),
        ),
      ],
    );
  }
}
