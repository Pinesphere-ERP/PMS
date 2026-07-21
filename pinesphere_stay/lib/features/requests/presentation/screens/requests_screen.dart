import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/core/theme/app_colors.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pinesphere_stay/features/requests/data/models/service_request_model.dart';
import 'package:pinesphere_stay/features/requests/presentation/providers/request_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isManager = authState.maybeWhen(
      authenticated: (user) => user.role.name == 'manager' || user.role.name == 'owner',
      orElse: () => false,
    );
    final currentUserId = authState.maybeWhen<String>(
      authenticated: (user) => user.id,
      orElse: () => '',
    );
    final propertyId = authState.maybeWhen<String>(
      authenticated: (user) => user.propertyId ?? '',
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Service Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'My Requests'),
            const Tab(text: 'My Tasks'),
            if (isManager) const Tab(text: 'Management') else const Tab(text: ''),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyRequestsTab(currentUserId),
          _buildMyTasksTab(currentUserId),
          if (isManager) _buildManagementTab(propertyId) else const Center(child: Text("Access Denied")),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/requests/create'),
        icon: const Icon(Icons.add),
        label: const Text("New Request"),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildMyRequestsTab(String userId) {
    final repo = ref.watch(serviceRequestRepositoryProvider);
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: repo.watchMyRequests(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return _buildEmptyState("You haven't created any requests yet.");
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _RequestCard(request: snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildMyTasksTab(String userId) {
    final repo = ref.watch(serviceRequestRepositoryProvider);
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: repo.watchMyTasks(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return _buildEmptyState("You have no pending tasks assigned.");
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return _RequestCard(
              request: request,
              actionWidget: (request.status != 'completed' && request.status != 'verified')
                  ? ElevatedButton.icon(
                      onPressed: () => _markTaskCompleted(request),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Complete Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildManagementTab(String propertyId) {
    final repo = ref.watch(serviceRequestRepositoryProvider);
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: repo.watchRequestsByProperty(propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return _buildEmptyState("No requests found for this property.");
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            Widget? action;
            if (request.status == 'pending') {
              action = OutlinedButton(
                onPressed: () => _assignTask(request),
                child: const Text('Assign Staff'),
              );
            } else if (request.status == 'completed') {
              action = ElevatedButton(
                onPressed: () => _verifyTask(request),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Verify Completion'),
              );
            }

            return _RequestCard(request: request, actionWidget: action);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  void _markTaskCompleted(ServiceRequestModel request) {
    final repo = ref.read(serviceRequestRepositoryProvider);
    final authState = ref.read(authProvider);
    final userId = authState.maybeWhen(authenticated: (u) => u.id, orElse: () => '');
    
    // In a real flow, you'd open an Image Picker here.
    repo.completeRequest(request.requestId, userId, 'https://example.com/mock-photo.jpg', remarks: 'Job finished');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job marked as completed!')));
  }

  void _assignTask(ServiceRequestModel request) {
    // Hardcoded to current user for demo MVP. Should open a picker.
    final repo = ref.read(serviceRequestRepositoryProvider);
    final authState = ref.read(authProvider);
    final userId = authState.maybeWhen(authenticated: (u) => u.id, orElse: () => '');
    
    repo.assignRequest(request.requestId, userId);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Assigned successfully!')));
  }

  void _verifyTask(ServiceRequestModel request) {
    final repo = ref.read(serviceRequestRepositoryProvider);
    final authState = ref.read(authProvider);
    final userId = authState.maybeWhen(authenticated: (u) => u.id, orElse: () => '');
    
    repo.verifyRequest(request.requestId, userId, remarks: 'Verified looks good');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Verified!')));
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final Widget? actionWidget;

  const _RequestCard({required this.request, this.actionWidget});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.teal;
      case 'verified': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'assigned': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency': return Colors.red;
      case 'high': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(color: _getStatusColor(request.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  timeago.format(request.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              request.description ?? 'No description provided',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(request.requestCategory, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.flag, size: 16, color: _getPriorityColor(request.priority)),
                const SizedBox(width: 4),
                Text(request.priority.toUpperCase(), style: TextStyle(color: _getPriorityColor(request.priority), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            if (actionWidget != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [actionWidget!],
              )
            ]
          ],
        ),
      ),
    );
  }
}
