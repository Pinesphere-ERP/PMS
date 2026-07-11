import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

class PropertySettingsScreen extends ConsumerStatefulWidget {
  const PropertySettingsScreen({super.key});

  @override
  ConsumerState<PropertySettingsScreen> createState() => _PropertySettingsScreenState();
}

class _PropertySettingsScreenState extends ConsumerState<PropertySettingsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadPropertySettings('demo-property-id', 'demo-device-uid');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Property Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: state is Loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state is ErrorState
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                )
              : _buildSettingsList(context, state),
    );
  }

  Widget _buildSettingsList(BuildContext context, SettingsState state) {
    final settings = state is Loaded ? state.propertySettings : <Map<String, dynamic>>[];

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in settings) {
      final group = _groupForKey(s['setting_key'] ?? '');
      grouped.putIfAbsent(group, () => []).add(s);
    }

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 64, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text('No property settings configured', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Contact your Super Admin to configure property settings.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in grouped.entries) ...[
          _buildGroupTitle(context, entry.key),
          const SizedBox(height: 8),
          _buildMenuGroup(context, [
            for (int i = 0; i < entry.value.length; i++)
              _buildSettingItem(context, entry.value[i], i == entry.value.length - 1),
          ]),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  String _groupForKey(String key) {
    if (key.startsWith('CHECK_') || key == 'EXTRA_ADULT_CHARGE') return 'Hotel Rules';
    if (key.startsWith('TAX_') || key == 'GST_NUMBER' || key == 'GST_PERCENT') return 'Tax & GST';
    if (key == 'CURRENCY' || key.startsWith('PAYMENT_') || key.startsWith('INVOICE_')) return 'Financial';
    if (key == 'PET_POLICY' || key == 'COUPLE_FRIENDLY' || key == 'ACCEPTED_IDS') return 'Policies';
    return 'General';
  }

  Widget _buildGroupTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
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
      child: Column(children: items),
    );
  }

  Widget _buildSettingItem(BuildContext context, Map<String, dynamic> setting, bool isLast) {
    final key = setting['setting_key'] ?? '';
    final value = setting['setting_value']?.toString() ?? '';

    return Column(
      children: [
        ListTile(
          leading: Icon(_iconForSettingKey(key), color: AppColors.onSurfaceVariant),
          title: Text(_labelForSettingKey(key), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.outlineVariant, size: 20),
            ],
          ),
          onTap: () {},
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.surfaceVariant),
      ],
    );
  }

  IconData _iconForSettingKey(String key) {
    switch (key) {
      case 'CHECK_IN_TIME': return Icons.login;
      case 'CHECK_OUT_TIME': return Icons.logout;
      case 'TAX_PERCENT': return Icons.percent;
      case 'GST_NUMBER': return Icons.receipt;
      case 'CURRENCY': return Icons.monetization_on;
      case 'ACCEPTED_IDS': return Icons.badge;
      case 'PET_POLICY': return Icons.pets;
      case 'COUPLE_FRIENDLY': return Icons.favorite_outline;
      case 'EXTRA_ADULT_CHARGE': return Icons.person_add;
      default: return Icons.settings;
    }
  }

  String _labelForSettingKey(String key) {
    switch (key) {
      case 'CHECK_IN_TIME': return 'Check-In Time';
      case 'CHECK_OUT_TIME': return 'Check-Out Time';
      case 'TAX_PERCENT': return 'Tax Percentage';
      case 'GST_NUMBER': return 'GST Number';
      case 'CURRENCY': return 'Default Currency';
      case 'ACCEPTED_IDS': return 'Accepted ID Types';
      case 'PET_POLICY': return 'Pet Policy';
      case 'COUPLE_FRIENDLY': return 'Couple Friendly';
      case 'EXTRA_ADULT_CHARGE': return 'Extra Adult Charge';
      default: return key.replaceAll('_', ' ');
    }
  }
}
