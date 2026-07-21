import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dio_client.dart';

final accessiblePropertiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final str = await storage.read(key: 'accessible_properties');
  if (str != null) {
    return List<Map<String, dynamic>>.from(jsonDecode(str));
  }
  return [];
});

class TenantNotifier extends Notifier<String?> {
  late final FlutterSecureStorage _storage;

  @override
  String? build() {
    _storage = ref.watch(secureStorageProvider);
    _init();
    return null; // initial state before async init completes
  }

  Future<void> _init() async {
    final tenantId = await _storage.read(key: 'tenant_id');
    if (tenantId != null && tenantId.isNotEmpty) {
      state = tenantId;
    } else {
      final userStr = await _storage.read(key: 'cached_user');
      if (userStr != null) {
        try {
          final Map<String, dynamic> json = jsonDecode(userStr);
          final pId = json['property_id'] ?? json['propertyId'];
          if (pId != null && pId.toString().isNotEmpty) {
            state = pId.toString();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> setTenantId(String tenantId) async {
    await _storage.write(key: 'tenant_id', value: tenantId);
    state = tenantId;
  }
}

final tenantProvider = NotifierProvider<TenantNotifier, String?>(() {
  return TenantNotifier();
});
