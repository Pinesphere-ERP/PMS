import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../providers/housekeeping_provider.dart';

class HousekeepingScreen extends ConsumerStatefulWidget {
  const HousekeepingScreen({super.key});

  @override
  ConsumerState<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends ConsumerState<HousekeepingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTabIndex = 0;
  final String _propertyId = '1234';

  String _taskStatusFilter = 'All';
  String _ticketStatusFilter = 'All';
  String _ticketCategoryFilter = 'All';

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic> _dashboard = {};

  final Map<String, TextEditingController> _taskRemarksControllers = {};
  final Map<String, TextEditingController> _taskInspectionRemarksControllers = {};
  final TextEditingController _createTaskRoomController = TextEditingController();
  final TextEditingController _createTaskStaffController = TextEditingController();
  final TextEditingController _createTaskRemarksController = TextEditingController();
  final TextEditingController _createTicketDescriptionController = TextEditingController();
  final TextEditingController _createTicketRoomController = TextEditingController();
  final TextEditingController _createTicketTechController = TextEditingController();
  final TextEditingController _ticketRepairCostController = TextEditingController();
  final TextEditingController _ticketAssignTechController = TextEditingController();

  String _createTaskPriority = 'medium';
  String _createTicketCategory = 'Electrical';
  String _createTicketPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
      if (_selectedTabIndex == 0) _loadDashboard();
      if (_selectedTabIndex == 1) _loadTasks();
      if (_selectedTabIndex == 2) _loadTickets();
    });
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _taskRemarksControllers.values) {
      c.dispose();
    }
    for (final c in _taskInspectionRemarksControllers.values) {
      c.dispose();
    }
    _createTaskRoomController.dispose();
    _createTaskStaffController.dispose();
    _createTaskRemarksController.dispose();
    _createTicketDescriptionController.dispose();
    _createTicketRoomController.dispose();
    _createTicketTechController.dispose();
    _ticketRepairCostController.dispose();
    _ticketAssignTechController.dispose();
    super.dispose();
  }

  void _loadDashboard() {
    ref.read(housekeepingProvider.notifier).getDashboard(_propertyId);
  }

  void _loadTasks() {
    final status = _taskStatusFilter == 'All' ? null : _taskStatusFilter.toLowerCase().replaceAll(' ', '_');
    ref.read(housekeepingProvider.notifier).getTasks(_propertyId, status: status);
  }

  void _loadTickets() {
    final status = _ticketStatusFilter == 'All' ? null : _ticketStatusFilter.toLowerCase();
    final category = _ticketCategoryFilter == 'All' ? null : _ticketCategoryFilter;
    ref.read(housekeepingProvider.notifier).getMaintenanceTickets(_propertyId, status: status, category: category);
  }

  void _onStateChanged(HousekeepingState? prev, HousekeepingState next) {
    next.maybeWhen(
      loadedDashboard: (d) => setState(() => _dashboard = d),
      loadedTasks: (t) => setState(() => _tasks = t),
      loadedMaintenanceTickets: (t) => setState(() => _tickets = t),
      success: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.tertiary),
        );
        if (_selectedTabIndex == 0) _loadDashboard();
        if (_selectedTabIndex == 1) _loadTasks();
        if (_selectedTabIndex == 2) _loadTickets();
      },
      error: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HousekeepingState>(housekeepingProvider, _onStateChanged);

    final state = ref.watch(housekeepingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Housekeeping',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Tasks'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: SafeArea(
        child: state.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          orElse: () => _buildCurrentTab(),
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? null
          : _selectedTabIndex == 1
              ? FloatingActionButton(
                  onPressed: () => _showCreateTaskSheet(),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.add),
                )
              : FloatingActionButton(
                  onPressed: () => _showCreateTicketSheet(),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.add),
                ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildTasksTab();
      case 2:
        return _buildMaintenanceTab();
      default:
        return _buildDashboardTab();
    }
  }

  // ──────────────────────────── DASHBOARD TAB ────────────────────────────

  Widget _buildDashboardTab() {
    final pending = _dashboard['pending_tasks'] ?? 0;
    final inProgress = _dashboard['in_progress'] ?? 0;
    final completedToday = _dashboard['completed_today'] ?? 0;
    final openMaintenance = _dashboard['open_maintenance'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardCard(
                'Pending Tasks',
                '$pending',
                Icons.pending_actions,
                const Color(0xFFFF9800),
              ),
              _buildDashboardCard(
                'In Progress',
                '$inProgress',
                Icons.autorenew,
                AppColors.primary,
              ),
              _buildDashboardCard(
                'Completed Today',
                '$completedToday',
                Icons.check_circle_outline,
                const Color(0xFF4CAF50),
              ),
              _buildDashboardCard(
                'Maintenance Open',
                '$openMaintenance',
                Icons.build,
                AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BentoCard(
                  onTap: () {
                    _tabController.animateTo(1);
                    Future.delayed(const Duration(milliseconds: 300), _showCreateTaskSheet);
                  },
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.add_task, color: AppColors.primary, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Create Task',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BentoCard(
                  onTap: () {
                    _tabController.animateTo(2);
                    Future.delayed(const Duration(milliseconds: 300), _showCreateTicketSheet);
                  },
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.report_problem, color: AppColors.error, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Report Issue',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, Color color) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── TASKS TAB ────────────────────────────

  Widget _buildTasksTab() {
    return Column(
      children: [
        _buildTaskFilters(),
        Expanded(
          child: _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cleaning_services, size: 64, color: AppColors.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildTaskFilters() {
    final filters = ['All', 'Pending', 'In Progress', 'Completed', 'Inspection Pending'];
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isActive = _taskStatusFilter == f;
          return FilterChip(
            label: Text(f),
            selected: isActive,
            onSelected: (_) {
              setState(() => _taskStatusFilter = f);
              _loadTasks();
            },
            selectedColor: AppColors.primaryContainer,
            labelStyle: TextStyle(
              color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: AppColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isActive ? AppColors.primary : AppColors.outlineVariant),
            ),
            checkmarkColor: AppColors.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final roomNumber = task['room_number'] ?? task['roomNumber'] ?? '';
    final status = task['status'] ?? 'pending';
    final priority = task['priority'] ?? 'medium';
    final staffName = task['assigned_staff_name'] ?? task['assignedStaffName'] ?? 'Unassigned';
    final createdAt = task['created_at'] ?? task['createdAt'] ?? '';

    return BentoCard(
      onTap: () => _showTaskDetailSheet(task),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Room $roomNumber',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildTaskPriorityBadge(priority),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTaskStatusChip(status),
              const Spacer(),
              Icon(Icons.person_outline, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                staffName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (createdAt.isNotEmpty)
            Text(
              _formatTimeAgo(createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'Pending';
        break;
      case 'in_progress':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        label = 'In Progress';
        break;
      case 'completed':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Completed';
        break;
      case 'inspected':
        bgColor = const Color(0xFFE0F2F1);
        textColor = const Color(0xFF00695C);
        label = 'Inspected';
        break;
      default:
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildTaskPriorityBadge(String priority) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (priority) {
      case 'high':
        bgColor = const Color(0xFFFFEBEE);
        textColor = AppColors.error;
        label = 'High';
        icon = Icons.arrow_upward;
        break;
      case 'medium':
        bgColor = const Color(0xFFFFFDE7);
        textColor = const Color(0xFFF9A825);
        label = 'Medium';
        icon = Icons.remove;
        break;
      case 'low':
      default:
        bgColor = AppColors.surfaceContainerLow;
        textColor = AppColors.onSurfaceVariant;
        label = 'Low';
        icon = Icons.arrow_downward;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  // ──────────────────── TASK DETAIL BOTTOM SHEET ────────────────────

  void _showTaskDetailSheet(Map<String, dynamic> task) {
    final taskId = task['id']?.toString() ?? task['uuid']?.toString() ?? '';
    final roomNumber = task['room_number'] ?? task['roomNumber'] ?? '';
    final status = task['status'] ?? 'pending';
    final priority = task['priority'] ?? 'medium';
    final staffName = task['assigned_staff_name'] ?? task['assignedStaffName'] ?? '';
    final remarks = task['remarks'] ?? '';
    final beforePhoto = task['before_photo'] ?? task['beforePhoto'] ?? '';
    final afterPhoto = task['after_photo'] ?? task['afterPhoto'] ?? '';
    final inspectionResult = task['inspection_result'] ?? task['inspectionResult'] ?? '';
    final inspectionRemarks = task['inspection_remarks'] ?? task['inspectionRemarks'] ?? '';
    final createdAt = task['created_at'] ?? task['createdAt'] ?? '';

    _taskRemarksControllers.putIfAbsent(taskId, () => TextEditingController(text: remarks));
    _taskInspectionRemarksControllers.putIfAbsent(taskId, () => TextEditingController(text: inspectionRemarks));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Room $roomNumber',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _buildTaskPriorityBadge(priority),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailInfoRow(Icons.circle, 'Status', _statusLabel(status), _statusColor(status)),
                const SizedBox(height: 12),
                _buildDetailInfoRow(Icons.person, 'Staff', staffName.isEmpty ? 'Unassigned' : staffName, AppColors.onSurface),
                const SizedBox(height: 12),
                _buildDetailInfoRow(Icons.access_time, 'Created', createdAt.isNotEmpty ? _formatTimeAgo(createdAt) : 'N/A', AppColors.onSurfaceVariant),
                const SizedBox(height: 24),

                // ──── Update Status ────
                Text(
                  'Update Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusUpdateButtons(taskId, status, setSheetState),
                const SizedBox(height: 24),

                // ──── Photos ────
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildPhotoPlaceholder('Before', beforePhoto)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPhotoPlaceholder('After', afterPhoto)),
                  ],
                ),
                const SizedBox(height: 24),

                // ──── Remarks ────
                Text(
                  'Remarks',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _taskRemarksControllers[taskId],
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add remarks...',
                    hintStyle: TextStyle(color: AppColors.outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                  ),
                ),
                const SizedBox(height: 24),

                // ──── Action Button ────
                if (status == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(housekeepingProvider.notifier).updateTask(taskId, {'status': 'in_progress'});
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Cleaning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                else if (status == 'in_progress')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(housekeepingProvider.notifier).updateTask(taskId, {
                          'status': 'completed',
                          'remarks': _taskRemarksControllers[taskId]?.text ?? '',
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                // ──── Inspection Section ────
                if (status == 'completed') ...[
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Inspection',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (inspectionResult.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          inspectionResult == 'pass' ? Icons.check_circle : Icons.cancel,
                          color: inspectionResult == 'pass' ? const Color(0xFF4CAF50) : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Result: ${inspectionResult.toUpperCase()}',
                          style: TextStyle(
                            color: inspectionResult == 'pass' ? const Color(0xFF4CAF50) : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Inspection Remarks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taskInspectionRemarksControllers[taskId],
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Inspection notes...',
                        hintStyle: TextStyle(color: AppColors.outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(housekeepingProvider.notifier).inspectTask(taskId, {
                                'result': 'pass',
                                'remarks': _taskInspectionRemarksControllers[taskId]?.text ?? '',
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Pass'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(housekeepingProvider.notifier).inspectTask(taskId, {
                                'result': 'fail',
                                'remarks': _taskInspectionRemarksControllers[taskId]?.text ?? '',
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Fail'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusUpdateButtons(String taskId, String currentStatus, StateSetter setSheetState) {
    final nextStatuses = <String, String>{
      'pending': 'in_progress',
      'in_progress': 'completed',
      'completed': 'inspected',
    };

    final nextLabels = <String, String>{
      'pending': 'Start Cleaning',
      'in_progress': 'Mark Complete',
      'completed': 'Mark Inspected',
    };

    final nextIcons = <String, IconData>{
      'pending': Icons.play_arrow,
      'in_progress': Icons.check_circle,
      'completed': Icons.verified,
    };

    final nextColors = <String, Color>{
      'pending': AppColors.primary,
      'in_progress': const Color(0xFF4CAF50),
      'completed': const Color(0xFF00897B),
    };

    final next = nextStatuses[currentStatus];
    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.outline, size: 18),
            const SizedBox(width: 8),
            Text(
              'Task is in final state',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final data = <String, dynamic>{'status': next};
          if (next == 'completed') {
            data['remarks'] = _taskRemarksControllers[taskId]?.text ?? '';
          }
          ref.read(housekeepingProvider.notifier).updateTask(taskId, data);
          Navigator.pop(context);
        },
        icon: Icon(nextIcons[next], size: 18),
        label: Text(nextLabels[next]!),
        style: ElevatedButton.styleFrom(
          backgroundColor: nextColors[next],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.outline),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(String label, String photoUrl) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: photoUrl.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, color: AppColors.primary, size: 32),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: AppColors.outlineVariant, size: 28),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
    );
  }

  // ──────────────────── CREATE TASK BOTTOM SHEET ────────────────────

  void _showCreateTaskSheet() {
    _createTaskRoomController.clear();
    _createTaskStaffController.clear();
    _createTaskRemarksController.clear();
    _createTaskPriority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Task',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Text('Room Number', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createTaskRoomController,
                  decoration: _inputDecoration('e.g. 101'),
                ),
                const SizedBox(height: 16),

                Text('Priority', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityOption('low', 'Low', setSheetState),
                    const SizedBox(width: 8),
                    _buildPriorityOption('medium', 'Medium', setSheetState),
                    const SizedBox(width: 8),
                    _buildPriorityOption('high', 'High', setSheetState),
                  ],
                ),
                const SizedBox(height: 16),

                Text('Assign Staff', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createTaskStaffController,
                  decoration: _inputDecoration('Staff name'),
                ),
                const SizedBox(height: 16),

                Text('Remarks', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createTaskRemarksController,
                  maxLines: 3,
                  decoration: _inputDecoration('Optional remarks...'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final room = _createTaskRoomController.text.trim();
                      if (room.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room number is required'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      ref.read(housekeepingProvider.notifier).createTask(data: {
                        'property_id': _propertyId,
                        'room_number': room,
                        'priority': _createTaskPriority,
                        'assigned_staff_name': _createTaskStaffController.text.trim(),
                        'remarks': _createTaskRemarksController.text.trim(),
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Create Task'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String value, String label, StateSetter setSheetState) {
    final isActive = _createTaskPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheetState(() => _createTaskPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.outlineVariant,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.outline),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
    );
  }

  // ──────────────────────────── MAINTENANCE TAB ────────────────────────────

  Widget _buildMaintenanceTab() {
    return Column(
      children: [
        _buildMaintenanceFilters(),
        Expanded(
          child: _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle, size: 64, color: AppColors.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No maintenance tickets',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) => _buildTicketCard(_tickets[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceFilters() {
    final statusFilters = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];
    final categoryFilters = ['All', 'Electrical', 'AC', 'Plumbing', 'TV', 'Furniture', 'Other'];

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final f = statusFilters[index];
              final isActive = _ticketStatusFilter == f;
              return FilterChip(
                label: Text(f),
                selected: isActive,
                onSelected: (_) {
                  setState(() => _ticketStatusFilter = f);
                  _loadTickets();
                },
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isActive ? AppColors.primary : AppColors.outlineVariant),
                ),
                checkmarkColor: AppColors.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categoryFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final f = categoryFilters[index];
              final isActive = _ticketCategoryFilter == f;
              return FilterChip(
                label: Text(f),
                selected: isActive,
                onSelected: (_) {
                  setState(() => _ticketCategoryFilter = f);
                  _loadTickets();
                },
                selectedColor: AppColors.secondaryContainer,
                labelStyle: TextStyle(
                  color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isActive ? AppColors.secondary : AppColors.outlineVariant),
                ),
                checkmarkColor: AppColors.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final roomNumber = ticket['room_number'] ?? ticket['roomNumber'] ?? '';
    final category = ticket['category'] ?? '';
    final priority = ticket['priority'] ?? 'medium';
    final description = ticket['issue_description'] ?? ticket['issueDescription'] ?? '';
    final status = ticket['status'] ?? 'open';
    final createdAt = ticket['created_at'] ?? ticket['createdAt'] ?? '';

    return BentoCard(
      onTap: () => _showTicketDetailSheet(ticket),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Room $roomNumber',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              const Spacer(),
              _buildTicketPriorityBadge(priority),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTicketStatusChip(status),
              const Spacer(),
              if (createdAt.isNotEmpty)
                Text(
                  _formatTimeAgo(createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketPriorityBadge(String priority) {
    Color bgColor;
    Color textColor;
    String label;

    switch (priority) {
      case 'critical':
        bgColor = AppColors.error;
        textColor = AppColors.onError;
        label = 'Critical';
        break;
      case 'high':
        bgColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        label = 'High';
        break;
      case 'medium':
        bgColor = const Color(0xFFFFF9C4);
        textColor = const Color(0xFFF57F17);
        label = 'Medium';
        break;
      case 'low':
      default:
        bgColor = AppColors.surfaceContainerLow;
        textColor = AppColors.onSurfaceVariant;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildTicketStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'open':
        bgColor = const Color(0xFFFFEBEE);
        textColor = AppColors.error;
        label = 'Open';
        break;
      case 'in_progress':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        label = 'In Progress';
        break;
      case 'resolved':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Resolved';
        break;
      case 'closed':
        bgColor = AppColors.surfaceContainerLow;
        textColor = AppColors.onSurfaceVariant;
        label = 'Closed';
        break;
      default:
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  // ──────────────────── TICKET DETAIL BOTTOM SHEET ────────────────────

  void _showTicketDetailSheet(Map<String, dynamic> ticket) {
    final ticketId = ticket['id']?.toString() ?? ticket['uuid']?.toString() ?? '';
    final roomNumber = ticket['room_number'] ?? ticket['roomNumber'] ?? '';
    final category = ticket['category'] ?? '';
    final priority = ticket['priority'] ?? 'medium';
    final description = ticket['issue_description'] ?? ticket['issueDescription'] ?? '';
    final status = ticket['status'] ?? 'open';
    final assignedTo = ticket['assigned_to_name'] ?? ticket['assignedToName'] ?? '';
    final repairCost = ticket['repair_cost'] ?? ticket['repairCost'] ?? 0;
    final createdAt = ticket['created_at'] ?? ticket['createdAt'] ?? '';

    _ticketAssignTechController.text = assignedTo;
    _ticketRepairCostController.text = repairCost.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Room $roomNumber',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildTicketPriorityBadge(priority),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    _buildTicketStatusChip(status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailInfoRow(Icons.circle, 'Status', status.toUpperCase(), _statusColor(status)),
                const SizedBox(height: 12),
                _buildDetailInfoRow(Icons.person, 'Assigned To', assignedTo.isEmpty ? 'Unassigned' : assignedTo, AppColors.onSurface),
                const SizedBox(height: 12),
                _buildDetailInfoRow(Icons.attach_money, 'Repair Cost', '\$${repairCost.toString()}', AppColors.onSurface),
                const SizedBox(height: 12),
                _buildDetailInfoRow(Icons.access_time, 'Reported', createdAt.isNotEmpty ? _formatTimeAgo(createdAt) : 'N/A', AppColors.onSurfaceVariant),
                const SizedBox(height: 24),

                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface)),
                ),
                const SizedBox(height: 24),

                Text(
                  'Assign Technician',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ticketAssignTechController,
                  decoration: _inputDecoration('Technician name'),
                ),
                const SizedBox(height: 16),

                // ──── Status Update Buttons ────
                Text(
                  'Update Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTicketStatusButtons(ticketId, status, setSheetState),

                // ──── Repair Cost (when resolving) ────
                if (status == 'in_progress') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Repair Cost',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ticketRepairCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('\$0.00'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final cost = double.tryParse(_ticketRepairCostController.text) ?? 0;
                        ref.read(housekeepingProvider.notifier).updateMaintenanceTicket(ticketId, {
                          'status': 'resolved',
                          'assigned_to_name': _ticketAssignTechController.text.trim(),
                          'repair_cost': cost,
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                if (status == 'resolved') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(housekeepingProvider.notifier).updateMaintenanceTicket(ticketId, {
                          'status': 'closed',
                          'assigned_to_name': _ticketAssignTechController.text.trim(),
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.lock, size: 18),
                      label: const Text('Close Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.onSurfaceVariant,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketStatusButtons(String ticketId, String currentStatus, StateSetter setSheetState) {
    final nextStatuses = <String, String>{
      'open': 'in_progress',
      'in_progress': 'resolved',
      'resolved': 'closed',
    };

    final nextLabels = <String, String>{
      'open': 'Start Working',
      'in_progress': 'Resolve',
      'closed': 'Close',
    };

    final nextIcons = <String, IconData>{
      'open': Icons.play_arrow,
      'in_progress': Icons.build,
      'closed': Icons.lock,
    };

    final nextColors = <String, Color>{
      'open': AppColors.primary,
      'in_progress': const Color(0xFFFF9800),
      'resolved': const Color(0xFF4CAF50),
    };

    final next = nextStatuses[currentStatus];
    if (next == null || currentStatus == 'closed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.outline, size: 18),
            const SizedBox(width: 8),
            Text('Ticket is ${currentStatus.toUpperCase()}', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(housekeepingProvider.notifier).updateMaintenanceTicket(ticketId, {
            'status': next,
            'assigned_to_name': _ticketAssignTechController.text.trim(),
          });
          Navigator.pop(context);
        },
        icon: Icon(nextIcons[currentStatus] ?? Icons.arrow_forward, size: 18),
        label: Text(nextLabels[currentStatus]!),
        style: ElevatedButton.styleFrom(
          backgroundColor: nextColors[currentStatus] ?? AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ──────────────────── CREATE TICKET BOTTOM SHEET ────────────────────

  void _showCreateTicketSheet() {
    _createTicketRoomController.clear();
    _createTicketDescriptionController.clear();
    _createTicketTechController.clear();
    _createTicketCategory = 'Electrical';
    _createTicketPriority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Report Issue',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Text('Room Number', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createTicketRoomController,
                  decoration: _inputDecoration('e.g. 101'),
                ),
                const SizedBox(height: 16),

                Text('Category', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _createTicketCategory,
                  decoration: _inputDecoration('Select category'),
                  items: ['Electrical', 'AC', 'Plumbing', 'TV', 'Furniture', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => _createTicketCategory = v ?? 'Electrical'),
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),

                Text('Priority', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _createTicketPriority,
                  decoration: _inputDecoration('Select priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (v) => setSheetState(() => _createTicketPriority = v ?? 'medium'),
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),

                Text('Issue Description', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createTicketDescriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration('Describe the issue...'),
                ),
                const SizedBox(height: 16),

                Text('Assign Technician (Optional)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createTicketTechController,
                  decoration: _inputDecoration('Technician name'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final room = _createTicketRoomController.text.trim();
                      final desc = _createTicketDescriptionController.text.trim();
                      if (room.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room number is required'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      if (desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Description is required'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      ref.read(housekeepingProvider.notifier).createMaintenanceTicket(data: {
                        'property_id': _propertyId,
                        'room_number': room,
                        'category': _createTicketCategory,
                        'priority': _createTicketPriority,
                        'issue_description': desc,
                        'assigned_to_name': _createTicketTechController.text.trim(),
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Create Ticket'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────── HELPERS ────────────────────────────

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'inspected':
        return 'Inspected';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'inspected':
        return const Color(0xFF00897B);
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _formatTimeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, y').format(date);
    } catch (_) {
      return isoDate;
    }
  }
}
