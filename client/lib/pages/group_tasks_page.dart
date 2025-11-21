// client/lib/pages/group_tasks_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class GroupTasksPage extends StatefulWidget {
  final String userId;
  final String householdId;
  final String? householdName;

  const GroupTasksPage({
    super.key,
    required this.userId,
    required this.householdId,
    this.householdName,
  });

  @override
  State<GroupTasksPage> createState() => _GroupTasksPageState();
}

class _GroupTasksPageState extends State<GroupTasksPage> {
  List<dynamic> _tasks = [];
  List<dynamic> _members = [];
  String _currentFilter = 'active'; // active, completed, all
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTasks(), _loadMembers()]);
  }

  Future<void> _loadMembers() async {
    try {
      final uri = Uri.parse('${Api.base}/api/households/${widget.householdId}/members');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _members = data['members'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(
        '${Api.base}/api/tasks?type=group&householdId=${widget.householdId}&status=$_currentFilter',
      );
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        setState(() {
          _tasks = jsonDecode(resp.body) as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleComplete(String taskId, bool isCompleted) async {
    try {
      final uri = Uri.parse('${Api.base}/api/tasks/$taskId');
      final resp = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
        body: jsonEncode({'status': isCompleted ? 'active' : 'completed'}),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        _loadTasks();
      }
    } catch (e) {
      print('Error toggling task: $e');
    }
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '10');
    String? selectedMember;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Task nou de grup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titlu *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descriere'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMember,
                  decoration: const InputDecoration(labelText: 'Asignat către'),
                  items: _members.map<DropdownMenuItem<String>>((m) {
                    return DropdownMenuItem(
                      value: m['id'].toString(),
                      child: Text(m['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedMember = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child:                       TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Alege data',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:                       TextButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Alege ora',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  decoration: const InputDecoration(labelText: 'Puncte'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;

                final body = {
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': 'group',
                  'householdId': widget.householdId,
                  'points': int.tryParse(pointsCtrl.text) ?? 10,
                };

                if (selectedMember != null && selectedMember!.isNotEmpty) {
                  body['assignedTo'] = selectedMember!;
                }
                if (selectedDate != null) body['dueDate'] = selectedDate!.toIso8601String();
                if (selectedTime != null) {
                  body['dueTime'] = '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                }

                try {
                  final uri = Uri.parse('${Api.base}/api/tasks');
                  final resp = await http.post(
                    uri,
                    headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
                    body: jsonEncode(body),
                  ).timeout(const Duration(seconds: 10));

                  if (resp.statusCode == 201) {
                    Navigator.pop(dialogContext);
                    _loadTasks();
                  } else {
                    print('Failed to create task: ${resp.statusCode} - ${resp.body}');
                  }
                } catch (e) {
                  print('Error creating task: $e');
                }
              },
              child: const Text('Creează'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.householdName ?? 'Task-uri Grup'),
        backgroundColor: paleRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtre
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FilterChip(
                  label: 'Active',
                  selected: _currentFilter == 'active',
                  onTap: () {
                    setState(() => _currentFilter = 'active');
                    _loadTasks();
                  },
                ),
                _FilterChip(
                  label: 'Finalizate',
                  selected: _currentFilter == 'completed',
                  onTap: () {
                    setState(() => _currentFilter = 'completed');
                    _loadTasks();
                  },
                ),
                _FilterChip(
                  label: 'Toate',
                  selected: _currentFilter == 'all',
                  onTap: () {
                    setState(() => _currentFilter = 'all');
                    _loadTasks();
                  },
                ),
              ],
            ),
          ),

          // Lista task-uri
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.task_alt, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Niciun task încă', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = _tasks[i];
                          final isCompleted = task['status'] == 'completed';
                          final assignedName = task['assignedTo']?['name'] ?? 'Neasignat';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Checkbox(
                                value: isCompleted,
                                onChanged: (_) => _toggleComplete(task['_id'], isCompleted),
                                activeColor: paleRoyalBlue,
                              ),
                              title: Text(
                                task['title'] ?? '',
                                style: TextStyle(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task['description']?.isNotEmpty == true)
                                    Text(task['description']),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(assignedName, style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 12),
                                      if (task['dueDate'] != null) ...[
                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(task['dueDate']),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: task['points'] != null
                                  ? Chip(
                                      label: Text('${task['points']}p'),
                                      backgroundColor: paleRoyalBlue.withOpacity(0.2),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: paleRoyalBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7E9BFF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}