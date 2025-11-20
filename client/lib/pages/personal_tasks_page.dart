// personal_tasks_page.dart
// Refactored and fixed version (null-safety, Map<String, dynamic>, clear structure)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PersonalTasksPage extends StatefulWidget {
  final String userId; // required

  const PersonalTasksPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<PersonalTasksPage> createState() => _PersonalTasksPageState();
}


class _PersonalTasksPageState extends State<PersonalTasksPage> {
  final List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

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
        final created = jsonDecode(resp.body);
        setState(() => _tasks.add(Map<String, dynamic>.from(created)));
        Navigator.of(context).pop();
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
    _dueDate = null;
    _dueTime = null;
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Personal Task'),
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
                  decoration: const InputDecoration(labelText: 'Points'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(_dueDate == null
                          ? 'No date chosen'
                          : 'Date: ${_dueDate!.toLocal().toIso8601String().split('T')[0]}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      child: const Text('Choose'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(_dueTime == null ? 'No time chosen' : 'Time: ${_dueTime!.format(context)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => _dueTime = picked);
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
                        'type': 'personal',
                        'points': points,
                      };

                      if (_dueDate != null) {
                        body['dueDate'] = _dueDate!.toIso8601String();
                      }
                      if (_dueTime != null) {
                        body['dueTime'] =
                            '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}';
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
    final due = task['dueDate']?.toString() ?? 'No due date';
    final points = task['points']?.toString() ?? '0';
    return ListTile(
      title: Text(title),
      subtitle: Text('Due: $due • Points: $points'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Tasks'),
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
              ? const Center(child: Text('No personal tasks yet'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) => _buildTaskTile(_tasks[index]),
                ),
    );
  }
}
