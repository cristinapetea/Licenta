import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../api.dart';

class ShoppingListPage extends StatefulWidget {
  final String userId;
  final String taskId;
  final String taskTitle;

  const ShoppingListPage({
    super.key,
    required this.userId,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final TextEditingController _itemController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadShoppingList();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);
    
    try {
      print('Loading shopping list for task: ${widget.taskId}');
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final task = jsonDecode(resp.body);
        setState(() {
          _items = task['shoppingList'] ?? [];
          _isLoading = false;
        });
        print('Loaded ${_items.length} items');
      } else {
        print('Failed to load: ${resp.statusCode}');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load: ${resp.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading shopping list: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

    try {
      print('Adding item: $itemName');
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping');
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
        body: jsonEncode({'item': itemName.trim()}),
      ).timeout(const Duration(seconds: 10));

      print('Add item response: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        _itemController.clear();
        await _loadShoppingList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ "$itemName" added to shopping list'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('Failed to add item: ${resp.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding item: ${resp.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleItem(String itemId, bool currentState) async {
    try {
      print('Toggling item: $itemId');
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping/$itemId/toggle');
      final resp = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
      ).timeout(const Duration(seconds: 10));

      print('Toggle response: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        await _loadShoppingList();
      }
    } catch (e) {
      print('Error toggling item: $e');
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      print('Deleting item: $itemId');
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping/$itemId');
      final resp = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
      ).timeout(const Duration(seconds: 10));

      print('Delete response: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        await _loadShoppingList();
      }
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _itemController.text = result.recognizedWords;
          });
          
          
          if (result.finalResult) {
            _addItem(_itemController.text);
            _stopListening();
          }
        },
        localeId: 'ro_RO', 
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.taskTitle),
        backgroundColor: paleRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Input for adding items
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Add item...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _addItem,
                  ),
                ),
                const SizedBox(width: 8),
                // Microphone button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : paleRoyalBlue,
                  ),
                  iconSize: 32,
                  onPressed: _isListening ? _stopListening : _startListening,
                  tooltip: _isListening ? 'Stop' : 'Speak',
                ),
                // Add button
                IconButton(
                  icon: const Icon(Icons.add_circle, color: paleRoyalBlue),
                  iconSize: 32,
                  onPressed: () => _addItem(_itemController.text),
                  tooltip: 'Add',
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shopping_basket, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No items yet',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the microphone to dictate',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final itemId = item['_id'] ?? '';
                          final itemName = item['item'] ?? '';
                          final isChecked = item['checked'] ?? false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: isChecked,
                                onChanged: (_) => _toggleItem(itemId, isChecked),
                                activeColor: paleRoyalBlue,
                              ),
                              title: Text(
                                itemName,
                                style: TextStyle(
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isChecked ? Colors.grey : Colors.black,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteItem(itemId),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
