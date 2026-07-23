import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../main.dart';
import '../../../user_role_management/domain/entities.dart';
import '../../../sync/data/sync_service.dart';
import '../../../../core/network/dio_client.dart';

class AddEditUserScreen extends ConsumerStatefulWidget {
  final UserEntity? existingUser;
  const AddEditUserScreen({super.key, this.existingUser});

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  
  List<RoleEntity> _allRoles = [];
  String? _selectedRoleId;

  bool get _isEditing => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    if (_isEditing) {
      _nameController.text = widget.existingUser!.name;
      _emailController.text = widget.existingUser!.email ?? '';
      _mobileController.text = widget.existingUser!.mobileNumber ?? '';
      _selectedRoleId = widget.existingUser!.roleId;
    }
  }

  Future<void> _loadRoles() async {
    List<RoleEntity> roles = databaseService.roleDao.getAll().where((r) => !r.isDeleted).toList();
    
    if (roles.isEmpty) {
      try {
        final dio = ref.read(dioClientProvider);
        final response = await dio.get('/users/roles');
        if (response.statusCode == 200) {
          final data = response.data['data'] as List;
          roles = data.map((json) => RoleEntity(
            serverId: json['id'],
            roleCode: json['role_code'],
            roleName: json['role_name'],
          )).toList();
          
          // Save to local DB for next time
          for (var r in roles) {
             databaseService.roleDao.put(r);
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch roles: $e');
      }
    }

    if (mounted) {
      setState(() {
        _allRoles = roles;
        if (!_isEditing && roles.isNotEmpty) {
          _selectedRoleId = roles.first.serverId;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedRoleId != null) {
      final userDao = databaseService.userDao;
      final syncService = ref.read(syncServiceProvider);
      
      final serverId = _isEditing ? widget.existingUser!.serverId : const Uuid().v4();
      final operation = _isEditing ? 'UPDATE' : 'CREATE';

      final user = UserEntity(
        id: _isEditing ? widget.existingUser!.id : 0,
        serverId: serverId,
        roleId: _selectedRoleId!,
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        mobileNumber: _mobileController.text.isNotEmpty ? _mobileController.text : null,
        syncStatus: 'Pending',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        tenantId: _isEditing ? widget.existingUser!.tenantId : null,
        propertyId: _isEditing ? widget.existingUser!.propertyId : null,
        createdAt: _isEditing ? widget.existingUser!.createdAt : DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      userDao.put(user);

      syncService.enqueueMutation(
        entityType: 'User',
        entityId: serverId,
        operation: operation,
        payload: {
          'name': user.name,
          'email': user.email,
          'mobile_number': user.mobileNumber,
          'role_id': user.roleId,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'User updated successfully' : 'User created successfully')),
      );

      Navigator.pop(context);
    } else if (_selectedRoleId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit User' : 'Create User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Role'),
                initialValue: _selectedRoleId,
                items: _allRoles.map((role) {
                  return DropdownMenuItem(
                    value: role.serverId,
                    child: Text(role.roleName),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRoleId = val;
                  });
                },
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Update User' : 'Save User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
