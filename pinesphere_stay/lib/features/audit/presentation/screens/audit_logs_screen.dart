import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audit_service.dart';
import '../../domain/models/audit_log_entity.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  List<AuditLogEntity> _logs = [];
  bool _chainValid = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    final auditService = ref.read(auditServiceProvider);
    setState(() {
      _logs = auditService.queryLogs(limit: 100);
      _chainValid = auditService.verifyChain();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: Icon(
              _chainValid ? Icons.verified : Icons.warning,
              color: _chainValid ? Colors.green : Colors.red,
            ),
            onPressed: () {
              setState(() => _chainValid = ref.read(auditServiceProvider).verifyChain());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_chainValid
                      ? 'Hash chain verified: intact'
                      : 'Hash chain BROKEN: tampering detected'),
                  backgroundColor: _chainValid ? Colors.green : Colors.red,
                ),
              );
            },
            tooltip: 'Verify hash chain',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text('No audit logs recorded yet.'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      _actionIcon(log.actionType),
                      color: _actionColor(log.actionType),
                    ),
                    title: Text('${log.moduleName} - ${log.actionType}'),
                    subtitle: Text(
                      '${log.targetEntity} | ${log.timestamp.toLocal()}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }

  IconData _actionIcon(String? action) {
    if (action == null) return Icons.info;
    if (action.contains('create') || action.contains('register')) return Icons.add_circle;
    if (action.contains('update') || action.contains('modify')) return Icons.edit;
    if (action.contains('delete') || action.contains('cancel') || action.contains('revoke')) return Icons.delete;
    if (action.contains('login')) return Icons.login;
    if (action.contains('logout')) return Icons.logout;
    return Icons.info;
  }

  Color _actionColor(String? action) {
    if (action == null) return Colors.grey;
    if (action.contains('create') || action.contains('register')) return Colors.green;
    if (action.contains('update') || action.contains('modify')) return Colors.blue;
    if (action.contains('delete') || action.contains('cancel') || action.contains('revoke')) return Colors.red;
    if (action.contains('failure')) return Colors.orange;
    return Colors.grey;
  }
}
