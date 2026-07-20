import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../main.dart';
import '../../../user_role_management/domain/entities.dart';
import '../../../sync/data/sync_service.dart';

class AddEditRoleScreen extends ConsumerStatefulWidget {
  final RoleEntity? existingRole;
  const AddEditRoleScreen({super.key, this.existingRole});

  @override
  ConsumerState<AddEditRoleScreen> createState() => _AddEditRoleScreenState();
}

class _AddEditRoleScreenState extends ConsumerState<AddEditRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<PermissionEntity> _allPermissions = [];
  Set<String> _selectedPermissionIds = {};

  bool get _isEditing => widget.existingRole != null;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    if (_isEditing) {
      _nameController.text = widget.existingRole!.roleName;
      _descriptionController.text = widget.existingRole!.description ?? '';
    }
  }

  void _loadPermissions() {
    final perms = databaseService.permDao.getAll();
    setState(() {
      _allPermissions = perms;
    });

    if (_isEditing) {
      final rolePerms = databaseService.rolePermDao.getAll().where((rp) => rp.roleId == widget.existingRole!.serverId);
      setState(() {
        _selectedPermissionIds = rolePerms.map((rp) => rp.permissionId).toSet();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final roleDao = databaseService.roleDao;
      final rolePermDao = databaseService.rolePermDao;
      final syncService = ref.read(syncServiceProvider);
      
      final serverId = _isEditing ? widget.existingRole!.serverId : const Uuid().v4();
      final roleCode = _isEditing ? widget.existingRole!.roleCode : _nameController.text.toLowerCase().replaceAll(' ', '_');
      final operation = _isEditing ? 'UPDATE' : 'CREATE';

      final role = RoleEntity(
        id: _isEditing ? widget.existingRole!.id : 0,
        serverId: serverId,
        roleCode: roleCode,
        roleName: _nameController.text,
        description: _descriptionController.text,
        isSystemRole: false,
        syncStatus: 'Pending',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        tenantId: _isEditing ? widget.existingRole!.tenantId : null,
        propertyId: _isEditing ? widget.existingRole!.propertyId : null,
        createdAt: _isEditing ? widget.existingRole!.createdAt : DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      roleDao.put(role);

      syncService.enqueueMutation(
        entityType: 'Role',
        entityId: serverId,
        operation: operation,
        payload: {
          'name': role.roleName,
          'role_code': role.roleCode,
          'description': role.description,
          'is_system': role.isSystemRole,
        },
      );

      // Handle Permissions (Simplistic sync strategy: delete old, create new)
      if (_isEditing) {
        final existingRolePerms = rolePermDao.getAll().where((rp) => rp.roleId == serverId);
        for (var rp in existingRolePerms) {
          if (!_selectedPermissionIds.contains(rp.permissionId)) {
             rp.isDeleted = true;
             rp.syncStatus = 'Pending';
             rolePermDao.put(rp);
             syncService.enqueueMutation(
                entityType: 'RolePermission',
                entityId: rp.serverId,
                operation: 'DELETE',
                payload: {'is_deleted': true},
             );
          }
        }
      }

      for (var permId in _selectedPermissionIds) {
        final existing = _isEditing ? rolePermDao.getAll().where((rp) => rp.roleId == serverId && rp.permissionId == permId && !rp.isDeleted).firstOrNull : null;
        if (existing == null) {
          final rpServerId = const Uuid().v4();
          final rp = RolePermissionEntity(
            serverId: rpServerId,
            roleId: serverId,
            permissionId: permId,
            accessLevel: 'READ_WRITE',
            syncStatus: 'Pending',
            lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
          );
          rolePermDao.put(rp);
          syncService.enqueueMutation(
            entityType: 'RolePermission',
            entityId: rpServerId,
            operation: 'CREATE',
            payload: {
              'role_id': serverId,
              'permission_id': permId,
            },
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Role updated successfully' : 'Role created successfully')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Role' : 'Create Role')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Role Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _allPermissions.isEmpty
                    ? const Center(child: Text('No permissions available to assign.'))
                    : ListView.builder(
                        itemCount: _allPermissions.length,
                        itemBuilder: (context, index) {
                          final perm = _allPermissions[index];
                          return CheckboxListTile(
                            title: Text(perm.permissionCode),
                            subtitle: Text(perm.moduleName),
                            value: _selectedPermissionIds.contains(perm.serverId),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPermissionIds.add(perm.serverId);
                                } else {
                                  _selectedPermissionIds.remove(perm.serverId);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Update Role' : 'Save Role'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
