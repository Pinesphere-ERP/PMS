import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/audit_log_entity.dart';

class AuditLogDetailScreen extends StatelessWidget {
  final AuditLogEntity log;

  const AuditLogDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final oldValue = _tryParseJson(log.oldValueSnapshot);
    final newValue = _tryParseJson(log.newValueSnapshot);

    return Scaffold(
      appBar: AppBar(
        title: Text(log.actionType ?? 'Audit Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTargetSection(),
          const SizedBox(height: 16),
          _buildUserSection(),
          const SizedBox(height: 16),
          if (oldValue != null || newValue != null)
            _buildChangeSection(oldValue, newValue),
          const SizedBox(height: 16),
          _buildHashSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final action = log.actionType ?? '';
    final color = _actionColor(action);
    final icon = _actionIcon(action);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatActionType(action),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.moduleName ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection() {
    return _buildCard(
      title: 'Target',
      children: [
        _buildRow('Entity', log.targetEntity ?? '-'),
        _buildRow('Record ID', log.targetRecordId ?? '-', copyable: true),
        if (log.propertyId != null)
          _buildRow('Property ID', log.propertyId!, copyable: true),
        _buildRow('Timestamp', _formatTimestamp(log.timestamp)),
      ],
    );
  }

  Widget _buildUserSection() {
    return _buildCard(
      title: 'User',
      children: [
        _buildRow('User ID', log.userId ?? 'System'),
        if (log.deviceId != null && log.deviceId!.isNotEmpty)
          _buildRow('Device ID', log.deviceId!, copyable: true),
        if (log.ipAddress != null && log.ipAddress!.isNotEmpty)
          _buildRow('IP Address', log.ipAddress!),
      ],
    );
  }

  Widget _buildChangeSection(Map<String, dynamic>? oldVal, Map<String, dynamic>? newVal) {
    return _buildCard(
      title: 'Change Details',
      children: [
        if (newVal != null) ...[
          Text(
            'New Values',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          ...newVal.entries.map((e) => _buildRow(e.key, e.value?.toString() ?? '-')),
        ],
        if (oldVal != null && oldVal.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Previous Values',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          ...oldVal.entries.map((e) => _buildRow(e.key, e.value?.toString() ?? '-')),
        ],
        if (newVal == null && (oldVal == null || oldVal.isEmpty))
          const Text('No change details recorded.', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildHashSection() {
    final prevHash = log.previousLogHash ?? '';
    final entryHash = log.entryHash ?? '';

    return _buildCard(
      title: 'Hash Chain',
      children: [
        _buildRow('Previous Hash', prevHash.length > 16 ? '${prevHash.substring(0, 16)}...' : prevHash, copyable: true, fullValue: prevHash),
        const SizedBox(height: 4),
        _buildRow('Entry Hash', entryHash.length > 16 ? '${entryHash.substring(0, 16)}...' : entryHash, copyable: true, fullValue: entryHash),
        const SizedBox(height: 4),
        _buildRow('Log ID', log.logId, copyable: true),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool copyable = false, String? fullValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: fullValue ?? value));
                    }
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: copyable ? Colors.blue[700] : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatActionType(String action) {
    return action
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatTimestamp(DateTime ts) {
    final local = ts.toLocal();
    final date = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Map<String, dynamic>? _tryParseJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  IconData _actionIcon(String action) {
    if (action.contains('create') || action.contains('add') || action.contains('register')) return Icons.add_circle;
    if (action.contains('update') || action.contains('modify') || action.contains('status')) return Icons.edit;
    if (action.contains('delete') || action.contains('cancel') || action.contains('revoke')) return Icons.delete;
    if (action.contains('login') || action.contains('biometric')) return Icons.login;
    if (action.contains('logout')) return Icons.logout;
    if (action.contains('check_in') || action.contains('walk_in')) return Icons.login;
    if (action.contains('check_out')) return Icons.logout;
    return Icons.info_outline;
  }

  Color _actionColor(String action) {
    if (action.contains('create') || action.contains('add') || action.contains('register') || action.contains('success')) return Colors.green;
    if (action.contains('update') || action.contains('modify')) return Colors.blue;
    if (action.contains('delete') || action.contains('cancel') || action.contains('revoke')) return Colors.red;
    if (action.contains('failure') || action.contains('error')) return Colors.orange;
    return Colors.grey;
  }
}
