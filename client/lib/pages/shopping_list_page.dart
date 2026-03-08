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

  Future<List<String>> _parseShoppingItemsWithAI(String text) async {
    try {
      final uri = Uri.parse('${Api.base}/api/ai/parse-shopping-list');
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
        body: jsonEncode({'spokenText': text}),
      ).timeout(const Duration(seconds: 10));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return List<String>.from(data['items']);
      }
      
      return _parseShoppingItemsFallback(text);
    } catch (e) {
      return _parseShoppingItemsFallback(text);
    }
  }

  List<String> _parseShoppingItemsFallback(String text) {
    final separators = RegExp(r'\s+și\s+|\s+si\s+|,\s*|\s+plus\s+|\s+cu\s+', 
                              caseSensitive: false);
    
    return text.split(separators)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.length > 2)
      .map((s) => s[0].toUpperCase() + s.substring(1))
      .toList();
  }

  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);
    
    try {
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final task = jsonDecode(resp.body);
        setState(() {
          _items = task['shoppingList'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSingleItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

    try {
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
        body: jsonEncode({'item': itemName.trim()}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  Future<void> _addMultipleItems(List<String> items) async {
    if (items.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      for (String item in items) {
        await _addSingleItem(item);
      }

      await _loadShoppingList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${items.length} items added'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

    List<String> items = await _parseShoppingItemsWithAI(itemName);
    
    if (items.isEmpty) {
      await _addSingleItem(itemName);
      _itemController.clear();
      await _loadShoppingList();
    } else if (items.length == 1) {
      await _addSingleItem(items[0]);
      _itemController.clear();
      await _loadShoppingList();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${items[0]}" added'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      await _addMultipleItems(items);
      _itemController.clear();
    }
  }

  Future<void> _toggleItem(String itemId, bool currentState) async {
    try {
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping/$itemId/toggle');
      final resp = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        await _loadShoppingList();
      }
    } catch (e) {
      print('Error toggling item: $e');
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping/$itemId');
      await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
      ).timeout(const Duration(seconds: 10));

      await _loadShoppingList();
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      
      _speech.listen(
        onResult: (result) {
          setState(() {
            _itemController.text = result.recognizedWords;
          });
          
          if (result.finalResult) {
            String spokenText = _itemController.text;
            _addItem(spokenText);
            _stopListening();
          }
        },
        localeId: 'ro_RO',
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: InputDecoration(
                          hintText: 'Speak or type items...',
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
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : paleRoyalBlue,
                      ),
                      iconSize: 32,
                      onPressed: _isListening ? _stopListening : _startListening,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: paleRoyalBlue),
                      iconSize: 32,
                      onPressed: () => _addItem(_itemController.text),
                    ),
                  ],
                ),
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.mic, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Listening...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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
                              'Tap microphone to add items',
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