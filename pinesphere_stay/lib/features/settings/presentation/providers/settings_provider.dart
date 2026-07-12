import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/settings_service.dart';
import '../../domain/models/device_config_entity.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

// ── State ──────────────────────────────────────────────────────

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = SettingsStateInitial;
  const factory SettingsState.loading() = SettingsStateLoading;
  const factory SettingsState.loaded({
    required List<Map<String, dynamic>> propertySettings,
    required DeviceConfigEntity deviceConfig,
  }) = SettingsStateLoaded;
  const factory SettingsState.error(String message) = SettingsStateError;
  const factory SettingsState.saved() = SettingsStateSaved;
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
      if (current is SettingsStateLoaded) {
        state = current.copyWith(deviceConfig: deviceConfig);
      }
    } catch (e) {
      state = SettingsState.error(e.toString());
    }
  }
}
