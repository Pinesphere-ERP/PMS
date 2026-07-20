import 'package:pinesphere_stay/main.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import 'package:pinesphere_stay/objectbox.g.dart';
import '../../audit/data/audit_service.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/property_setting_entity.dart';
import '../domain/models/device_config_entity.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  final service = SettingsService(
    dio: ref.watch(dioClientProvider),
  );
  service.initialize(databaseService.store, ref.read(syncServiceProvider), ref.read(auditServiceProvider));
  return service;
}

class SettingsService {
  final Dio _dio;
  late final Store _store;
  late final Box<PropertySettingEntity> _propertySettingsBox;
  late final Box<DeviceConfigEntity> _deviceConfigBox;
  late final SyncService _syncService;
  late final AuditService _audit;

  SettingsService({required this._dio});

  void initialize(Store store, SyncService syncService, AuditService audit) {
    _store = store;
    _propertySettingsBox = _store.box<PropertySettingEntity>();
    _deviceConfigBox = _store.box<DeviceConfigEntity>();
    _syncService = syncService;
    _audit = audit;
  }

  // ── Property Settings (synced) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getPropertySettings(String propertyId) async {
    try {
      final response = await _dio.get('/settings/property/$propertyId');
      final body = response.data as Map<String, dynamic>;
      final items = (body['items'] as List).cast<Map<String, dynamic>>();

      for (final item in items) {
        final entity = PropertySettingEntity(
          serverId: item['id']?.toString() ?? '',
          propertyId: propertyId,
          settingKey: item['setting_key']?.toString() ?? '',
          settingValue: item['setting_value']?.toString() ?? '',
          valueType: item['value_type']?.toString() ?? 'string',
          description: item['description']?.toString() ?? '',
          updatedBy: item['updated_by']?.toString() ?? '',
          version: item['version'] ?? 1,
          lastModifiedHlc: item['updated_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        );
        _propertySettingsBox.put(entity);
      }
      return items;
    } on DioException catch (e) {
      AppLogger.w('getPropertySettings network failed, falling back to ObjectBox', e);
      final locals = _propertySettingsBox
          .query(PropertySettingEntity_.propertyId.equals(propertyId))
          .build()
          .find();
      return locals.map((e) => {
        'id': e.serverId,
        'property_id': e.propertyId,
        'setting_key': e.settingKey,
        'setting_value': e.settingValue,
        'value_type': e.valueType,
        'description': e.description,
        'version': e.version,
      }).toList();
    } catch (e) {
      AppLogger.e('getPropertySettings unexpected error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPropertySetting(
    String propertyId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/settings/property/$propertyId', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = PropertySettingEntity(
          serverId: body['id']?.toString() ?? '',
          propertyId: propertyId,
        settingKey: data['setting_key'] ?? '',
        settingValue: data['setting_value'] ?? '',
        valueType: data['value_type'] ?? 'string',
        description: data['description'] ?? '',
        version: body['version'] ?? 1,
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      _propertySettingsBox.put(entity);
      return body;
    } on DioException catch (e) {
      AppLogger.w('createPropertySetting network failed, storing locally and queuing sync', e);
      final localUuid = const Uuid().v4();
      final entity = PropertySettingEntity(
        serverId: localUuid,
        propertyId: propertyId,
        settingKey: data['setting_key'] ?? '',
        settingValue: data['setting_value'] ?? '',
        valueType: data['value_type'] ?? 'string',
        description: data['description'] ?? '',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );

      _syncService.enqueueMutation(
        entityType: 'PropertySetting',
        entityId: localUuid,
        operation: 'CREATE',
        payload: {...data, 'id': localUuid},
      );
      
      _audit.log(
        moduleName: 'settings',
        actionType: 'create_property_setting',
        targetEntity: 'property_setting',
        targetRecordId: localUuid,
        propertyId: propertyId,
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('createPropertySetting unexpected error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePropertySetting(
    String propertyId,
    String settingId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch('/settings/property/$propertyId/$settingId', data: data);
      final body = response.data as Map<String, dynamic>;

      final query = _propertySettingsBox
          .query(PropertySettingEntity_.serverId.equals(settingId))
          .build();
      final locals = query.find();
      query.close();
      if (locals.isNotEmpty) {
        final local = locals.first;
        local.settingValue = data['setting_value']?.toString() ?? local.settingValue;
        if (data['value_type'] != null) local.valueType = data['value_type'];
        if (data['description'] != null) local.description = data['description'];
        local.version = (body['version'] ?? local.version + 1);
        local.lastModifiedHlc = DateTime.now().toUtc().toIso8601String();
        _propertySettingsBox.put(local);
      }

      return body;
    } on DioException catch (e) {
      AppLogger.w('updatePropertySetting network failed, updating locally and queuing sync', e);

      final query = _propertySettingsBox
          .query(PropertySettingEntity_.serverId.equals(settingId))
          .build();
      final locals = query.find();
      query.close();
      if (locals.isNotEmpty) {
        final local = locals.first;
        local.settingValue = data['setting_value']?.toString() ?? local.settingValue;
        if (data['value_type'] != null) local.valueType = data['value_type'];
        if (data['description'] != null) local.description = data['description'];
        local.version += 1;
        local.lastModifiedHlc = DateTime.now().toUtc().toIso8601String();
        _propertySettingsBox.put(local);
      }

      _syncService.enqueueMutation(
        entityType: 'PropertySetting',
        entityId: settingId,
        operation: 'UPDATE',
        payload: {'id': settingId, ...data},
      );
      
      _audit.log(
        moduleName: 'settings',
        actionType: 'update_property_setting',
        targetEntity: 'property_setting',
        targetRecordId: settingId,
        propertyId: propertyId,
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('updatePropertySetting unexpected error', e);
      rethrow;
    }
  }

  // ── Device Configuration (local-only, never synced) ─────────

  Future<DeviceConfigEntity> getDeviceConfig(String deviceUid) async {
    final query = _deviceConfigBox
        .query(DeviceConfigEntity_.deviceUid.equals(deviceUid))
        .build();
    final results = query.find();
    query.close();

    if (results.isNotEmpty) return results.first;

    final defaultConfig = DeviceConfigEntity(
      deviceUid: deviceUid,
      lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
    );
    _deviceConfigBox.put(defaultConfig);
    return defaultConfig;
  }

  Future<void> updateDeviceConfig(String deviceUid, {
    bool? biometricEnabled,
    int? syncIntervalMins,
    String? thermalPrinterMac,
    String? localLogLevel,
  }) async {
    final query = _deviceConfigBox
        .query(DeviceConfigEntity_.deviceUid.equals(deviceUid))
        .build();
    final results = query.find();
    query.close();

    final config = results.isNotEmpty ? results.first : DeviceConfigEntity(
      deviceUid: deviceUid,
      lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
    );

    if (biometricEnabled != null) config.biometricEnabled = biometricEnabled;
    if (syncIntervalMins != null) config.syncIntervalMins = syncIntervalMins;
    if (thermalPrinterMac != null) config.thermalPrinterMac = thermalPrinterMac;
    if (localLogLevel != null) config.localLogLevel = localLogLevel;
    config.lastModifiedHlc = DateTime.now().toUtc().toIso8601String();

    _deviceConfigBox.put(config);
  }
}
