// client/lib/pages/group_tasks_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../api.dart';
import 'shopping_list_page.dart';

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
  String _currentFilter = 'active';
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

  Future<void> _completeWithPhoto(String taskId) async {
    final ImagePicker picker = ImagePicker();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final uri = Uri.parse('${Api.base}/api/tasks/$taskId/photo');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['x-user'] = widget.userId;
      request.fields['status'] = 'completed';
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completed with photo proof!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          title: const Text('New Group Task'),
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
                  value: selectedMember,
                  decoration: const InputDecoration(labelText: 'Assign to'),
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
                      child: TextButton.icon(
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
                              : 'Choose date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
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
                              : 'Choose time',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  decoration: const InputDecoration(labelText: 'Points'),
                  keyboardType: TextInputType.number,
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openShoppingList() async {
    // Search for existing shopping task
    String? shoppingTaskId;
    String? shoppingTaskTitle;
    
    for (var task in _tasks) {
      if (task['title']?.toLowerCase().contains('shopping') == true ||
          task['title']?.toLowerCase().contains('cumpărături') == true ||
          task['title']?.toLowerCase().contains('cumparaturi') == true) {
        shoppingTaskId = task['_id'];
        shoppingTaskTitle = task['title'];
        break;
      }
    }
    
    // If it doesn't exist, create one
    if (shoppingTaskId == null) {
      try {
        final uri = Uri.parse('${Api.base}/api/tasks');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json', 'x-user': widget.userId},
          body: jsonEncode({
            'title': 'Shopping List',
            'description': 'Task for shopping list',
            'type': 'group',
            'householdId': widget.householdId,
            'points': 0,
          }),
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 201) {
          final newTask = jsonDecode(resp.body);
          shoppingTaskId = newTask['_id'];
          shoppingTaskTitle = newTask['title'];
          _loadTasks(); // Reload list
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not create shopping task'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        print('Error creating shopping task: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Navigate to shopping list
    if (shoppingTaskId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingListPage(
            userId: widget.userId,
            taskId: shoppingTaskId!,
            taskTitle: 'Shopping List',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.householdName ?? 'Group Tasks'),
        backgroundColor: paleRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ SHOPPING CART BUTTON
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _openShoppingList,
            tooltip: 'Shopping List',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
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
                        label: 'Completed',
                        selected: _currentFilter == 'completed',
                        onTap: () {
                          setState(() => _currentFilter = 'completed');
                          _loadTasks();
                        },
                      ),
                      _FilterChip(
                        label: 'Failed',
                        selected: _currentFilter == 'failed',
                        onTap: () {
                          setState(() => _currentFilter = 'failed');
                          _loadTasks();
                        },
                      ),
                _FilterChip(
                  label: 'All',
                  selected: _currentFilter == 'all',
                  onTap: () {
                    setState(() => _currentFilter = 'all');
                    _loadTasks();
                  },
                ),
              ],
            ),
          ),

          // Task list
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
                            Text('No tasks yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = _tasks[i];
                          final isCompleted = task['status'] == 'completed';
                          final assignedName = task['assignedTo']?['name'] ?? 'Unassigned';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Checkbox + Title + Points
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isCompleted,
                                        onChanged: (_) => _toggleComplete(task['_id'], isCompleted),
                                        activeColor: paleRoyalBlue,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 12),
                                            Text(
                                              task['title'] ?? '',
                                              style: TextStyle(
                                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (task['description']?.isNotEmpty == true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                task['description'],
                                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Points badge
                                      if (task['points'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: paleRoyalBlue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${task['points']}p',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Info row: Person + Date
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          assignedName,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if (task['dueDate'] != null) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(task['dueDate']),
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  
                                  // Photo if exists
                                  if (task['photo'] != null) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '${Api.base}${task['photo']}',
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 200,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.broken_image, size: 48),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  
                                  // Camera button for active tasks
                                  if (!isCompleted) ...[
                                    const SizedBox(height: 8),
                                    Center(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _completeWithPhoto(task['_id']),
                                        icon: const Icon(Icons.camera_alt, size: 18),
                                        label: const Text('Add photo'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: paleRoyalBlue,
                                        ),
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