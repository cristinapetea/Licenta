import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

const Color kPaleRoyalBlue = Color(0xFF7E9BFF);
const Color kPalePurple    = Color(0xFFD3B8FF);
const Color kPalePink      = Color(0xFFFFD8F1);
const Color kDeepIndigo    = Color(0xFF4B4FA7);

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [kPalePink, kPalePurple, kPaleRoyalBlue],
        ),
      ),
      child: child,
    );
  }
}

class CreateJoinPage extends StatefulWidget {
  final String userId;
  const CreateJoinPage({super.key, required this.userId});

  @override
  State<CreateJoinPage> createState() => _CreateJoinPageState();
}

class _CreateJoinPageState extends State<CreateJoinPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _createForm = GlobalKey<FormState>();
  final _homeName   = TextEditingController();
  final _homeAddr   = TextEditingController();

  final _joinForm   = GlobalKey<FormState>();
  final _inviteCode = TextEditingController();

  bool _creating = false;
  bool _joining  = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _homeName.dispose();
    _homeAddr.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createHome() async {
    if (!_createForm.currentState!.validate()) return;

    setState(() => _creating = true);
    try {
      final uri = Uri.parse('${Api.base}/api/households');
      print('Making request to: $uri');
      print('With userId: ${widget.userId}');
      
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-user': widget.userId,
            },
            body: jsonEncode({
              'name': _homeName.text.trim(),
              'address': _homeAddr.text.trim().isEmpty
                  ? null
                  : _homeAddr.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      if (resp.statusCode == 201) {
        _toast('Home created!');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _toast('Create failed: ${resp.body}');
      }
    } catch (e) {
      print('Error creating home: $e');
      if (e.toString().contains('TimeoutException')) {
        _toast('Server timeout - verifica dacă serverul rulează pe ${Api.base}');
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        _toast('Nu se poate conecta la server - verifica dacă rulează');
      } else {
        _toast('Create failed: $e');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _joinHome() async {
    if (!_joinForm.currentState!.validate()) return;

    setState(() => _joining = true);
    try {
      final uri = Uri.parse('${Api.base}/api/households/join');
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-user': widget.userId,
            },
            body: jsonEncode({'code': _inviteCode.text.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        _toast('Successfully joined!');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _toast('Join failed: ${resp.body}');
      }
    } catch (e) {
      _toast('Join failed: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicator: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black54,
                      tabs: const [
                        Tab(text: 'Create'),
                        Tab(text: 'Join'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        // ===== CREATE TAB (layout-ul tău original) =====
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _createForm,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Home name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _homeName,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Enter a name'
                                              : null,
                                    ),
                                    const SizedBox(height: 18),

                                    const Text(
                                      'Address (optional)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _homeAddr,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF4FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.group_outlined),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Invite members\n'
                                              'After creation, you will receive a unique code that you can share with household members.',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: kDeepIndigo,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _creating ? null : _createHome,
                                      child: _creating
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Text('Create home'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ===== JOIN TAB (layout-ul tău original) =====
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _joinForm,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Invitation code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _inviteCode,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Enter the code'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),

                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'How it works?\n'
                                        'Ask an existing household member for the invitation code and enter it above.',
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: kDeepIndigo,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _joining ? null : _joinHome,
                                      child: _joining
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Text('Join'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
