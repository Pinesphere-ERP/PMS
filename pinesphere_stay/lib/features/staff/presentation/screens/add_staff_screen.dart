import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../main.dart';
import '../../../user_role_management/domain/entities.dart';
import '../../../sync/data/sync_service.dart';

class AddStaffScreen extends ConsumerStatefulWidget {
  final UserEntity? existingStaff;
  const AddStaffScreen({super.key, this.existingStaff});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedRole = 'housekeeper';
  
  bool get _isEditing => widget.existingStaff != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingStaff!.name;
      _emailController.text = widget.existingStaff!.email ?? '';
      _mobileController.text = widget.existingStaff!.mobileNumber ?? '';
      
      // Ensure the role is valid before setting it
      if (['manager', 'receptionist', 'housekeeper'].contains(widget.existingStaff!.roleId)) {
        _selectedRole = widget.existingStaff!.roleId;
      }
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
    if (_formKey.currentState!.validate()) {
      final userDao = databaseService.userDao;
      final syncService = ref.read(syncServiceProvider);
      
      final serverId = _isEditing ? widget.existingStaff!.serverId : const Uuid().v4();
      final operation = _isEditing ? 'UPDATE' : 'CREATE';

      final user = UserEntity(
        id: _isEditing ? widget.existingStaff!.id : 0,
        serverId: serverId,
        roleId: _selectedRole,
        name: _nameController.text,
        email: _emailController.text,
        mobileNumber: _mobileController.text,
        status: _isEditing ? widget.existingStaff!.status : 'ACTIVE',
        isPrimaryOwner: _isEditing ? widget.existingStaff!.isPrimaryOwner : false,
        syncStatus: 'Pending',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        tenantId: _isEditing ? widget.existingStaff!.tenantId : null,
        propertyId: _isEditing ? widget.existingStaff!.propertyId : null,
        createdAt: _isEditing ? widget.existingStaff!.createdAt : DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      // Save to ObjectBox
      userDao.put(user);

      // Queue the mutation in Sync Engine
      syncService.enqueueMutation(
        entityType: 'User',
        entityId: serverId,
        operation: operation,
        payload: {
          'name': user.name,
          'email': user.email,
          'mobile_number': user.mobileNumber,
          'role_id': user.roleId,
          'status': user.status,
          'is_primary_owner': user.isPrimaryOwner,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Staff updated successfully' : 'Staff created successfully')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Staff' : 'Add Staff')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
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
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'receptionist', child: Text('Receptionist')),
                  DropdownMenuItem(value: 'housekeeper', child: Text('Housekeeper')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Update Staff Member' : 'Save Staff Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
