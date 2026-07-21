import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_notifier.dart';
import '../../domain/models/staff_member_model.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  void _showInviteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _InviteStaffBottomSheet(),
    );
  }

  void _showStatusDialog(BuildContext context, StaffMemberModel staff) {
    if (staff.isPrimaryOwner) return; // Cannot change primary owner status

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Change Status: ${staff.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(ctx, staff, 'ACTIVE', Colors.green),
              _buildStatusOption(ctx, staff, 'SUSPENDED', Colors.orange),
              _buildStatusOption(ctx, staff, 'TERMINATED', Colors.red),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusOption(BuildContext context, StaffMemberModel staff, String status, Color color) {
    return ListTile(
      title: Text(status),
      textColor: color,
      trailing: staff.status == status ? Icon(Icons.check, color: color) : null,
      onTap: () async {
        Navigator.pop(context);
        if (staff.status == status) return;
        
        final success = await ref.read(staffProvider.notifier).updateStaffStatus(staff.id, status);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Status updated' : 'Failed to update status')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: staffState.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return const Center(child: Text('No staff members found.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(staffProvider.notifier).reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: staffList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                final isOwner = staff.isPrimaryOwner;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isOwner ? AppColors.primary : Colors.grey.shade200,
                      child: Text(
                        staff.name[0].toUpperCase(),
                        style: TextStyle(
                          color: isOwner ? AppColors.onPrimary : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      staff.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(staff.mobileNumber ?? staff.email ?? 'No contact info'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(staff.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            staff.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(staff.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: isOwner
                        ? const Chip(label: Text('Owner'), backgroundColor: Colors.transparent)
                        : IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showStatusDialog(context, staff),
                          ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading staff: $err'),
              ElevatedButton(
                onPressed: () => ref.read(staffProvider.notifier).reload(),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Invite Staff'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING_ONBOARDING':
        return Colors.blue;
      case 'SUSPENDED':
        return Colors.orange;
      case 'TERMINATED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _InviteStaffBottomSheet extends ConsumerStatefulWidget {
  const _InviteStaffBottomSheet();

  @override
  ConsumerState<_InviteStaffBottomSheet> createState() => _InviteStaffBottomSheetState();
}

class _InviteStaffBottomSheetState extends ConsumerState<_InviteStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedRole = '00000000-0000-0000-0000-000000000002'; // Default Manager UUID or similar
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final success = await ref.read(staffProvider.notifier).inviteStaff(
      mobileNumber: _mobileController.text.trim(),
      name: _nameController.text.trim(),
      roleId: _selectedRole, // In a real app, fetch roles from a RoleNotifier
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Invite sent successfully' : 'Failed to send invite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Invite Staff Member',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // Dummy Role Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: '00000000-0000-0000-0000-000000000002', child: Text('Manager')),
                  DropdownMenuItem(value: '00000000-0000-0000-0000-000000000003', child: Text('Receptionist')),
                  DropdownMenuItem(value: '00000000-0000-0000-0000-000000000004', child: Text('Housekeeping')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: AppColors.onPrimary)
                      : const Text('Send Invite', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
