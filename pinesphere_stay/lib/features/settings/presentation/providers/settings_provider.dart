import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/settings_service.dart';
import '../domain/models/property_setting_entity.dart';
import '../domain/models/device_config_entity.dart';

part 'settings_provider.freezed.dart';

// ── State ──────────────────────────────────────────────────────

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = _Initial;
  const factory SettingsState.loading() = _Loading;
  const factory SettingsState.loaded({
    required List<Map<String, dynamic>> propertySettings,
    required DeviceConfigEntity deviceConfig,
  }) = _Loaded;
  const factory SettingsState.error(String message) = _Error;
  const factory SettingsState.saved() = _Saved;
}

// ── Notifier ───────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() => const SettingsState.initial();

  SettingsService get _service => ref.read(settingsServiceProvider);

  Future<void> loadPropertySettings(String propertyId, String deviceUid) async {
    state = const SettingsState.loading();
    try {
      final settings = await _service.getPropertySettings(propertyId);
      final deviceConfig = await _service.getDeviceConfig(deviceUid);
      state = SettingsState.loaded(
        propertySettings: settings,
        deviceConfig: deviceConfig,
      );
    } catch (e) {
      state = SettingsState.error(e.toString());
    }
  }

  Future<void> createPropertySetting(String propertyId, Map<String, dynamic> data) async {
    try {
      await _service.createPropertySetting(propertyId, data);
      state = const SettingsState.saved();
    } catch (e) {
      state = SettingsState.error(e.toString());
    }
  }

  Future<void> updatePropertySetting(
    String propertyId,
    String settingId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _service.updatePropertySetting(propertyId, settingId, data);
      state = const SettingsState.saved();
    } catch (e) {
      state = SettingsState.error(e.toString());
    }
  }

  Future<void> updateDeviceConfig(String deviceUid, {
    bool? biometricEnabled,
    int? syncIntervalMins,
    String? thermalPrinterMac,
    String? localLogLevel,
  }) async {
    try {
      await _service.updateDeviceConfig(
        deviceUid,
        biometricEnabled: biometricEnabled,
        syncIntervalMins: syncIntervalMins,
        thermalPrinterMac: thermalPrinterMac,
        localLogLevel: localLogLevel,
      );
      final deviceConfig = await _service.getDeviceConfig(deviceUid);
      final current = state;
      if (current is _Loaded) {
        state = current.copyWith(deviceConfig: deviceConfig);
      }
    } catch (e) {
      state = SettingsState.error(e.toString());
    }
  }
}
