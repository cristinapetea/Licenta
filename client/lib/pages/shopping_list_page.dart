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

  // ⭐⭐⭐ FUNCȚIE NOUĂ: Parsează textul și separă în items ⭐⭐⭐
  List<String> _parseShoppingItems(String text) {
    print('📝 Parsing text: $text');
    
    // Normalizează textul
    String normalized = text.toLowerCase().trim();
    
    // Lista de cuvinte cheie pentru separare
    final separators = [
      ' și ',
      ' si ',
      ' plus ',
      ', ',
      ' cu ',
      ' iar ',
      ' de asemenea ',
      ' mai vreau ',
      ' și mai vreau ',
      ' mai trebuie ',
    ];
    
    // Înlocuiește toți separatorii cu un separator unic
    for (var separator in separators) {
      normalized = normalized.replaceAll(separator, '|SEPARATOR|');
    }
    
    // Separă pe baza separatorului
    List<String> rawItems = normalized.split('|SEPARATOR|');
    print('🔪 Split into: $rawItems');
    
    // Curăță și procesează fiecare item
    List<String> items = [];
    for (var item in rawItems) {
      String cleaned = item.trim();
      
      // Elimină prefixe comune
      cleaned = cleaned.replaceFirst(RegExp(r'^(vreau sa cumpar|cumpar|imi trebuie|mai trebuie|trebuie|vreau)\s+'), '');
      
      // Normalizează cantități și măsuri
      cleaned = _normalizeQuantities(cleaned);
      
      if (cleaned.isNotEmpty && cleaned.length > 2) {
        // Capitalize prima literă
        cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
        items.add(cleaned);
      }
    }
    
    print('✅ Final items: $items');
    return items;
  }

  // ⭐ Normalizează cantități (transformă cuvinte în cifre)
  String _normalizeQuantities(String text) {
    // Înlocuiește "doua" cu "2", "trei" cu "3", etc.
    final numbers = {
      'un ': '1 ',
      'unu ': '1 ',
      'o ': '1 ',
      'doi ': '2 ',
      'doua ': '2 ',
      'două ': '2 ',
      'trei ': '3 ',
      'patru ': '4 ',
      'cinci ': '5 ',
      'sase ': '6 ',
      'șase ': '6 ',
      'șapte ': '7 ',
      'sapte ': '7 ',
      'opt ': '8 ',
      'noua ': '9 ',
      'nouă ': '9 ',
      'zece ': '10 ',
    };
    
    String result = text;
    numbers.forEach((word, num) {
      result = result.replaceAll(word, num);
    });
    
    // Normalizează unități de măsură
    result = result.replaceAll('kilograme', 'kg');
    result = result.replaceAll('kilogram', 'kg');
    result = result.replaceAll('grame', 'g');
    result = result.replaceAll('gram', 'g');
    result = result.replaceAll('litri', 'l');
    result = result.replaceAll('litru', 'l');
    
    return result;
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

      if (resp.statusCode == 200) {
        final task = jsonDecode(resp.body);
        setState(() {
          _items = task['shoppingList'] ?? [];
          _isLoading = false;
        });
        print('Loaded ${_items.length} items');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading shopping list: $e');
      setState(() => _isLoading = false);
    }
  }

  // ⭐ Adaugă un singur item
  Future<void> _addSingleItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

    try {
      final uri = Uri.parse('${Api.base}/api/tasks/${widget.taskId}/shopping');
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
        body: jsonEncode({'item': itemName.trim()}),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 201 && resp.statusCode != 200) {
        print('Failed to add item: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  // ⭐⭐⭐ FUNCȚIE NOUĂ: Adaugă mai multe items dintr-o dată ⭐⭐⭐
  Future<void> _addMultipleItems(List<String> items) async {
    if (items.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      print('🛒 Adding ${items.length} items: $items');
      
      // Adaugă fiecare item
      for (String item in items) {
        await _addSingleItem(item);
      }

      // Reîncarcă lista
      await _loadShoppingList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${items.length} items added: ${items.join(", ")}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error adding multiple items: $e');
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

  // ⭐⭐⭐ FUNCȚIE ACTUALIZATĂ: Detectează automat dacă e un item sau mai multe ⭐⭐⭐
  Future<void> _addItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

    // Verifică dacă textul conține separatori (și, si, plus, virgulă)
    if (itemName.contains(RegExp(r' și | si | plus |, '))) {
      print('🔍 Detected multiple items in text');
      // Parsează și adaugă multiple items
      List<String> items = _parseShoppingItems(itemName);
      await _addMultipleItems(items);
      _itemController.clear();
    } else {
      print('📦 Adding single item');
      // Adaugă un singur item
      await _addSingleItem(itemName);
      _itemController.clear();
      await _loadShoppingList();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "$itemName" added'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
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
      final resp = await http.delete(
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
      print('Error deleting item: $e');
    }
  }

  // ⭐⭐⭐ FUNCȚIE ACTUALIZATĂ: Voice input cu parsing inteligent ⭐⭐⭐
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
          
          // Când vorbirea s-a terminat
          if (result.finalResult) {
            String spokenText = _itemController.text;
            print('🎤 Spoken text: $spokenText');
            
            // ⭐ Parsează și adaugă items automat!
            _addItem(spokenText);
            
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: InputDecoration(
                          hintText: 'e.g., "2 kg mere și 500g zahăr"',
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
                // ⭐ Hint text pentru voice input
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '🎤 Listening...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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