import os

base_path = "lib/features/manager"

# Models
models = {
    "booking_model.dart": "class Booking { final String id; final String status; Booking({required this.id, required this.status}); factory Booking.fromJson(Map<String, dynamic> json) => Booking(id: json['id'] ?? '', status: json['status'] ?? ''); }",
    "checkin_model.dart": "class Checkin { final String id; Checkin({required this.id}); factory Checkin.fromJson(Map<String, dynamic> json) => Checkin(id: json['id'] ?? ''); }",
    "housekeeping_model.dart": "class HousekeepingTask { final String id; final String status; HousekeepingTask({required this.id, required this.status}); factory HousekeepingTask.fromJson(Map<String, dynamic> json) => HousekeepingTask(id: json['id'] ?? '', status: json['status'] ?? ''); }",
    "maintenance_model.dart": "class MaintenanceTicket { final String id; final String status; MaintenanceTicket({required this.id, required this.status}); factory MaintenanceTicket.fromJson(Map<String, dynamic> json) => MaintenanceTicket(id: json['id'] ?? '', status: json['status'] ?? ''); }",
    "note_model.dart": "class ManagerNote { final String id; final String content; final bool isResolved; ManagerNote({required this.id, required this.content, required this.isResolved}); factory ManagerNote.fromJson(Map<String, dynamic> json) => ManagerNote(id: json['note_id'] ?? '', content: json['content'] ?? '', isResolved: json['is_resolved'] ?? false); }",
    "checklist_model.dart": "class DailyChecklist { final String id; final String status; DailyChecklist({required this.id, required this.status}); factory DailyChecklist.fromJson(Map<String, dynamic> json) => DailyChecklist(id: json['checklist_id'] ?? '', status: json['status'] ?? ''); }",
    "room_block_model.dart": "class RoomBlock { final String id; final String reason; RoomBlock({required this.id, required this.reason}); factory RoomBlock.fromJson(Map<String, dynamic> json) => RoomBlock(id: json['block_id'] ?? '', reason: json['reason'] ?? ''); }",
}

for name, content in models.items():
    with open(os.path.join(base_path, "models", name), "w") as f:
        f.write(content)

# Providers
providers_code = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

{model_imports}

final manager{name}Provider = FutureProvider.autoDispose<List<{model}>>((ref) async {{
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.get{endpoint}();
  return data.map((e) => {model}.fromJson(e as Map<String, dynamic>)).toList();
}});
"""

providers = [
    ("Bookings", "Booking", "Bookings", "booking_model.dart"),
    ("Checkins", "Checkin", "CheckinFeed", "checkin_model.dart"),
    ("Housekeeping", "HousekeepingTask", "HousekeepingProgress", "housekeeping_model.dart"),
    ("Maintenance", "MaintenanceTicket", "MaintenanceTickets", "maintenance_model.dart"),
    ("Notes", "ManagerNote", "Notes", "note_model.dart"),
    ("Checklists", "DailyChecklist", "Checklists", "checklist_model.dart"),
    ("RoomBlocks", "RoomBlock", "RoomBlocks", "room_block_model.dart"),
]

for name, model, endpoint, model_file in providers:
    content = providers_code.format(
        name=name, 
        model=model, 
        endpoint=endpoint,
        model_imports=f"import 'package:pinesphere_stay/features/manager/models/{model_file}';"
    )
    file_name = f"{name.lower()}_provider.dart"
    with open(os.path.join(base_path, "providers", file_name), "w") as f:
        f.write(content)

# Screens
screens_code = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/providers/{provider_file}';

class Manager{name}Screen extends ConsumerWidget {{
  const Manager{name}Screen({{Key? key}}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {{
    final state = ref.watch(manager{name}Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager {name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(manager{name}Provider),
          )
        ],
      ),
      body: state.when(
        data: (list) {{
          if (list.isEmpty) return const Center(child: Text('No records found.'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => ListTile(title: Text(list[index].id.toString())),
          );
        }},
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }}
}}
"""

for name, model, endpoint, model_file in providers:
    provider_file = f"{name.lower()}_provider.dart"
    content = screens_code.format(name=name, provider_file=provider_file)
    file_name = f"manager_{name.lower()}_screen.dart"
    with open(os.path.join(base_path, "screens", file_name), "w") as f:
        f.write(content)

print("Scaffolding completed.")
