import 'package:flutter/material.dart';

/// Culorile gradientului (aceleași ca în login/signup)
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
  const CreateJoinPage({super.key});

  @override
  State<CreateJoinPage> createState() => _CreateJoinPageState();
}

class _CreateJoinPageState extends State<CreateJoinPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // CREATE controllers
  final _createForm = GlobalKey<FormState>();
  final _homeName   = TextEditingController();
  final _homeAddr   = TextEditingController();

  // JOIN controllers
  final _joinForm   = GlobalKey<FormState>();
  final _inviteCode = TextEditingController();

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

  Future<void> _createHome() async {
    if (!_createForm.currentState!.validate()) return;

    // TODO: Apelează backend-ul tău aici
    // final res = await http.post(Uri.parse('${Api.base}/homes'), body: ...)
    // if (res.ok) -> mergi mai departe în aplicație (ex. HomePage)

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Locuință creată!')),
    );

    // Exemplu navigare după succes:
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _joinHome() async {
    if (!_joinForm.currentState!.validate()) return;

    // TODO: Apelează backend-ul tău aici
    // final res = await http.post(Uri.parse('${Api.base}/homes/join'), body: {'code': _inviteCode.text.trim()})

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alăturare reușită!')),
    );

    // Exemplu navigare după succes:
    Navigator.pushReplacementNamed(context, '/home');
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
                        Tab(text: 'Creează'),
                        Tab(text: 'Alătură-te'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        // ----------------- CREATE TAB -----------------
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
                                      'Nume locuință',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _homeName,
                                      decoration: const InputDecoration(
                                        hintText: 'Casa noastră',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Completează numele'
                                              : null,
                                    ),
                                    const SizedBox(height: 18),

                                    const Text(
                                      'Adresă (opțional)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _homeAddr,
                                      decoration: const InputDecoration(
                                        hintText: 'Str. Exemplu, Nr. 123',
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
                                              'Invită membri\n'
                                              'După creare, vei primi un cod unic pe care îl poți '
                                              'partaja cu membrii locuinței.',
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
                                      onPressed: _createHome,
                                      child: const Text('Creează locuință'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ----------------- JOIN TAB -----------------
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
                                      'Cod de invitație',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _inviteCode,
                                      decoration: const InputDecoration(
                                        hintText: 'ABC-123-XYZ',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Introdu codul'
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
                                        'Cum funcționează?\n'
                                        'Cere codul de invitație de la un membru existent al '
                                        'locuinței și introdu-l mai sus.',
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
                                      onPressed: _joinHome,
                                      child: const Text('Alătură-te'),
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
