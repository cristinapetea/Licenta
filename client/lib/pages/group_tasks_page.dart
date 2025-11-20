// group_tasks_page.dart
// Refactored and fixed version (null-safety, Map<String, dynamic>, clear structure)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupTasksPage extends StatefulWidget {
  final String userId;
  final String householdId;
  final String? householdName;

  const GroupTasksPage({
    Key? key,
    required this.userId,
    required this.householdId,
    this.householdName,
  }) : super(key: key);

  @override
  State<GroupTasksPage> createState() => _GroupTasksPageState();
}


class _GroupTasksPageState extends State<GroupTasksPage> {
  final List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;

  // Form state
  String? _selectedMember;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  // Replace with your actual API base
  static const String apiBase = 'https://example.com';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _createTask(Map<String, dynamic> body) async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('$apiBase/api/tasks');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        // assuming API returns created task as JSON
        final created = jsonDecode(resp.body);
        setState(() => _tasks.add(Map<String, dynamic>.from(created)));
        Navigator.of(context).pop(); // close dialog on success
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created')),
        );
      } else {
        final msg = 'Failed (${resp.statusCode}): ${resp.body}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _pointsController.clear();
    _selectedMember = null;
    _selectedDate = null;
    _selectedTime = null;
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Task (Group)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMember,
                  decoration: const InputDecoration(labelText: 'Assign to'),
                  items: <String>['Alice', 'Bob', 'Charlie', 'Unassigned']
                      .map((m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMember = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(_selectedDate == null
                          ? 'No date chosen'
                          : 'Date: ${_selectedDate!.toLocal().toIso8601String().split('T')[0]}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: const Text('Choose'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(_selectedTime == null
                          ? 'No time chosen'
                          : 'Time: ${_selectedTime!.format(context)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked =
                            await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => _selectedTime = picked);
                      },
                      child: const Text('Choose'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final title = _titleController.text.trim();
                      final description = _descriptionController.text.trim();
                      final points = int.tryParse(_pointsController.text.trim()) ?? 0;

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Title cannot be empty')));
                        return;
                      }

                      final Map<String, dynamic> body = {
                        'title': title,
                        'description': description,
                        'type': 'group',
                        'points': points,
                        // only include fields when not null
                      };

                      if (_selectedMember != null && _selectedMember!.isNotEmpty) {
                        // ensure value assigned is non-nullable and appropriate type
                        body['assignedTo'] = _selectedMember!;
                      }
                      if (_selectedDate != null) {
                        body['dueDate'] = _selectedDate!.toIso8601String();
                      }
                      if (_selectedTime != null) {
                        body['dueTime'] =
                            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                      }

                      _createTask(body);
                    },
              child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? '(no title)';
    final assigned = task['assignedTo']?.toString() ?? 'Unassigned';
    final points = task['points']?.toString() ?? '0';

    return ListTile(
      title: Text(title),
      subtitle: Text('Assigned to: $assigned • Points: $points'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTaskDialog,
          ),
        ],
      ),
      body: _isLoading && _tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No group tasks yet'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) => _buildTaskTile(_tasks[index]),
                ),
    );
  }
}
