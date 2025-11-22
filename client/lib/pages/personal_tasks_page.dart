// client/lib/pages/personal_tasks_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class PersonalTasksPage extends StatefulWidget {
  final String userId;

  const PersonalTasksPage({super.key, required this.userId});

  @override
  State<PersonalTasksPage> createState() => _PersonalTasksPageState();
}

class _PersonalTasksPageState extends State<PersonalTasksPage> {
  List<dynamic> _tasks = [];
  Map<String, int> _categoryStats = {};
  String _currentTab = 'astazi'; // astazi, saptamana, toate
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Sport', 'icon': Icons.fitness_center, 'color': Colors.orange},
    {'name': 'Hobby', 'icon': Icons.palette, 'color': Colors.purple},
    {'name': 'Muncă', 'icon': Icons.work, 'color': Colors.blue},
    {'name': 'Învățat', 'icon': Icons.school, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('${Api.base}/api/tasks?type=personal&status=all');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final allTasks = jsonDecode(resp.body) as List;
        
        // Calculează statistici pe categorii
        final stats = <String, int>{};
        for (var task in allTasks) {
          final cat = task['category'] ?? 'Altele';
          stats[cat] = (stats[cat] ?? 0) + 1;
        }

        setState(() {
          _tasks = allTasks;
          _categoryStats = stats;
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
    String? selectedCategory;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Task nou personal'),
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
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categorie'),
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c['name'] as String,
                      child: Row(
                        children: [
                          Icon(c['icon'] as IconData, color: c['color'] as Color, size: 20),
                          const SizedBox(width: 8),
                          Text(c['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: selectedDate != null ? Colors.blue : null,
                        ),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Alege data',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedDate != null ? Colors.blue : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        icon: Icon(
                          Icons.access_time,
                          size: 16,
                          color: selectedTime != null ? Colors.blue : null,
                        ),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Alege ora',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedTime != null ? Colors.blue : null,
                          ),
                        ),
                      ),
                    ),
                  ],
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

                final body = <String, dynamic>{
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': 'personal',
                  'category': selectedCategory ?? 'Altele',
                };

               // FIX DATE HERE (VARIANTA 1)
                if (selectedDate != null) {
                  body['dueDate'] =
                      "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                }

                if (selectedTime != null) {
                  body['dueTime'] =
                      '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}';
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

  List<dynamic> _getFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return _tasks.where((task) {
      if (_currentTab == 'astazi') {
        if (task['dueDate'] == null) return false;
        final dueDate = DateTime.parse(task['dueDate']);
        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return dueDay == today;
      } else if (_currentTab == 'saptamana') {
        if (task['dueDate'] == null) return false;
        final dueDate = DateTime.parse(task['dueDate']);
        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return dueDay.isAfter(today.subtract(const Duration(days: 1))) && dueDay.isBefore(weekEnd);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    final filteredTasks = _getFilteredTasks();
    final completedCount = filteredTasks.where((t) => t['status'] == 'completed').length;
    final completionRate = filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Task-uri Personale'),
        backgroundColor: paleRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                      label: 'Rată finalizare',
                      value: '${(completionRate * 100).toInt()}%',
                    ),
                    _StatBox(
                      label: 'Săptămâna asta',
                      value: '${_getFilteredTasks().length}',
                    ),
                    _StatBox(
                      label: 'Astăzi',
                      value: '${_tasks.where((t) {
                        if (t['dueDate'] == null) return false;
                        try {
                          final dueDate = DateTime.parse(t['dueDate']);
                          final today = DateTime.now();
                          return dueDate.year == today.year &&
                              dueDate.month == today.month &&
                              dueDate.day == today.day;
                        } catch (e) {
                          return false;
                        }
                      }).length}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Categorii
                if (_categoryStats.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final count = _categoryStats[cat['name'] as String] ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat['icon'] as IconData, size: 16, color: cat['color'] as Color),
                            const SizedBox(width: 4),
                            Text('${cat['name']}: $count', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TabButton(
                  label: 'Astăzi',
                  selected: _currentTab == 'astazi',
                  onTap: () => setState(() => _currentTab = 'astazi'),
                ),
                _TabButton(
                  label: 'Săptămâna',
                  selected: _currentTab == 'saptamana',
                  onTap: () => setState(() => _currentTab = 'saptamana'),
                ),
                _TabButton(
                  label: 'Toate',
                  selected: _currentTab == 'toate',
                  onTap: () => setState(() => _currentTab = 'toate'),
                ),
              ],
            ),
          ),

          // Lista task-uri
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
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
                        itemCount: filteredTasks.length,
                        itemBuilder: (ctx, i) {
                          final task = filteredTasks[i];
                          final isCompleted = task['status'] == 'completed';
                          final categoryName = task['category'] ?? 'Altele';
                          final category = _categories.firstWhere(
                            (c) => c['name'] == categoryName,
                            orElse: () => {'icon': Icons.task, 'color': Colors.grey, 'name': 'Altele'},
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(
                                category['icon'] as IconData,
                                color: category['color'] as Color,
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
                                  if (task['description']?.toString().isNotEmpty == true)
                                    Text(task['description'].toString()),
                                  if (task['dueDate'] != null || task['dueTime'] != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(task['dueDate'], task['dueTime']),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: isCompleted,
                                  onChanged: (_) => _toggleComplete(task['_id'], isCompleted),
                                  activeColor: paleRoyalBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
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

  String _formatDateTime(dynamic isoDate, dynamic time) {
    if (isoDate == null) return time?.toString() ?? '';
    try {
      final date = DateTime.parse(isoDate.toString());
      final dateStr = '${date.day}/${date.month}/${date.year}';
      return time != null ? '$dateStr, $time' : dateStr;
    } catch (e) {
      return '';
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

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