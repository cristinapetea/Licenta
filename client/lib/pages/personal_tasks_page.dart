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
  String _currentFilter = 'today'; // today, week, active, completed, failed
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Sport', 'icon': Icons.fitness_center, 'color': Colors.orange},
    {'name': 'Hobby', 'icon': Icons.palette, 'color': Colors.purple},
    {'name': 'Work', 'icon': Icons.work, 'color': Colors.blue},
    {'name': 'Study', 'icon': Icons.school, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      // Load ALL tasks to filter client-side
      final uri = Uri.parse('${Api.base}/api/tasks?type=personal&status=all');
      
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final allTasks = jsonDecode(resp.body) as List;
        
        // Calculate category statistics
        final stats = <String, int>{};
        for (var task in allTasks) {
          final cat = task['category'] ?? 'Other';
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
      } else if (resp.statusCode == 403) {
        final error = jsonDecode(resp.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Cannot modify this task'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          title: const Text('New Personal Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
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
                              : 'Choose date',
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
                              : 'Choose time',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;

                final body = <String, dynamic>{
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': 'personal',
                  'category': selectedCategory ?? 'Other',
                };

                // FIX: Store date in UTC to avoid timezone issues
                if (selectedDate != null) {
                  final utcDate = DateTime.utc(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                  );
                  body['dueDate'] = utcDate.toIso8601String();
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // Get tasks filtered by current week AND filter
  List<dynamic> _getFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get start of week (Monday)
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _tasks.where((task) {
      // First filter: Only show tasks from current week
      if (task['dueDate'] != null) {
        try {
          final dueDate = DateTime.parse(task['dueDate']);
          final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          
          // Skip if not in current week
          if (dueDay.isBefore(weekStart) || dueDay.isAfter(weekEnd.subtract(const Duration(days: 1)))) {
            return false;
          }
        } catch (e) {
          return false;
        }
      } else {
        // Tasks without due date are excluded
        return false;
      }

      // Second filter: Apply current tab filter
      if (_currentFilter == 'today') {
        try {
          final dueDate = DateTime.parse(task['dueDate']);
          final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          return dueDay == today;
        } catch (e) {
          return false;
        }
      } else if (_currentFilter == 'week') {
        return true; // Already filtered by week above
      } else if (_currentFilter == 'active') {
        return task['status'] == 'active';
      } else if (_currentFilter == 'completed') {
        return task['status'] == 'completed';
      } else if (_currentFilter == 'failed') {
        return task['status'] == 'failed';
      }
      
      return true;
    }).toList();
  }

  // Get stats for current week only
  Map<String, int> _getWeekStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStart0 = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStart0.add(const Duration(days: 7));

    int activeCount = 0;
    int completedCount = 0;
    int failedCount = 0;

    for (var task in _tasks) {
      if (task['dueDate'] == null) continue;
      
      try {
        final dueDate = DateTime.parse(task['dueDate']);
        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        
        // Check if task is in current week
        if (dueDay.isAfter(weekStart0.subtract(const Duration(days: 1))) && 
            dueDay.isBefore(weekEnd)) {
          if (task['status'] == 'active') activeCount++;
          else if (task['status'] == 'completed') completedCount++;
          else if (task['status'] == 'failed') failedCount++;
        }
      } catch (e) {
        continue;
      }
    }

    return {
      'active': activeCount,
      'completed': completedCount,
      'failed': failedCount,
    };
  }

  String _getWeekRangeText() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
  }

  IconData _getEmptyIcon() {
    switch (_currentFilter) {
      case 'today':
        return Icons.today;
      case 'week':
        return Icons.calendar_view_week;
      case 'failed':
        return Icons.check_circle;
      default:
        return Icons.task_alt;
    }
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case 'today':
        return 'No tasks for today';
      case 'week':
        return 'No tasks this week';
      case 'failed':
        return 'No failed tasks this week';
      case 'completed':
        return 'No completed tasks this week';
      case 'active':
        return 'No active tasks this week';
      default:
        return 'No tasks this week';
    }
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    final weekStats = _getWeekStats();
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Personal Tasks'),
        backgroundColor: paleRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats header - Current Week
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Week Stats',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _getWeekRangeText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                      label: 'Active',
                      value: '${weekStats['active']}',
                      color: paleRoyalBlue,
                    ),
                    _StatBox(
                      label: 'Completed',
                      value: '${weekStats['completed']}',
                      color: Colors.green,
                    ),
                    _StatBox(
                      label: 'Failed',
                      value: '${weekStats['failed']}',
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Categories
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

          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Today',
                    selected: _currentFilter == 'today',
                    onTap: () => setState(() => _currentFilter = 'today'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Week',
                    selected: _currentFilter == 'week',
                    onTap: () => setState(() => _currentFilter = 'week'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    selected: _currentFilter == 'active',
                    onTap: () => setState(() => _currentFilter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    selected: _currentFilter == 'completed',
                    onTap: () => setState(() => _currentFilter = 'completed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Failed',
                    selected: _currentFilter == 'failed',
                    onTap: () => setState(() => _currentFilter = 'failed'),
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Task list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getEmptyIcon(),
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getEmptyMessage(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (ctx, i) {
                          final task = filteredTasks[i];
                          final isCompleted = task['status'] == 'completed';
                          final isFailed = task['status'] == 'failed';
                          final categoryName = task['category'] ?? 'Other';
                          final category = _categories.firstWhere(
                            (c) => c['name'] == categoryName,
                            orElse: () => {'icon': Icons.task, 'color': Colors.grey, 'name': 'Other'},
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isFailed ? Colors.red[50] : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        category['icon'] as IconData,
                                        color: isFailed 
                                            ? Colors.red[700] 
                                            : category['color'] as Color,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isFailed) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  '❌ FAILED - Deadline passed',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Text(
                                              task['title'] ?? '',
                                              style: TextStyle(
                                                decoration: isCompleted || isFailed 
                                                    ? TextDecoration.lineThrough 
                                                    : null,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: isFailed ? Colors.red[700] : null,
                                              ),
                                            ),
                                            if (task['description']?.toString().isNotEmpty == true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                task['description'].toString(),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isFailed ? Colors.red[400] : Colors.grey,
                                                ),
                                              ),
                                            ],
                                            if (task['dueDate'] != null || task['dueTime'] != null) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule, 
                                                    size: 14, 
                                                    color: isFailed ? Colors.red[700] : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDateTime(task['dueDate'], task['dueTime']),
                                                    style: TextStyle(
                                                      fontSize: 12, 
                                                      color: isFailed ? Colors.red[700] : Colors.grey,
                                                      fontWeight: isFailed ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: 1.2,
                                        child: Checkbox(
                                          value: isFailed ? false : isCompleted,
                                          onChanged: isFailed 
                                              ? null 
                                              : (_) => _toggleComplete(task['_id'], isCompleted),
                                          activeColor: paleRoyalBlue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  if (isFailed) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red[300]!),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.info_outline, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'This task cannot be completed because the deadline has passed.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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
  final Color? color;
  
  const _StatBox({
    required this.label, 
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF7E9BFF);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.grey[200],
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