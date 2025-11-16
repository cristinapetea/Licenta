import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String? userId;
  final String? userName;
  
  const HomePage({super.key, this.userId, this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userId;
  String? _householdId;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _loadHouseholdId();
  }

  Future<void> _loadHouseholdId() async {
    if (_userId == null) return;
    
    try {
      final uri = Uri.parse('${Api.base}/api/households/mine');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': _userId!,
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final households = jsonDecode(resp.body) as List;
        if (households.isNotEmpty) {
          setState(() {
            _householdId = households[0]['_id']?.toString() ?? households[0]['id']?.toString();
          });
        }
      }
    } catch (e) {
      print('Error loading household: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 3 && _userId != null) {
      // Profile tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            userId: _userId!,
            userName: widget.userName,
            householdId: _householdId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    const palePurple    = Color(0xFFD3B8FF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [paleRoyalBlue, palePurple],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                'Your household',
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 16),

              // KPI CARDS
              Row(
                children: const [
                  _KpiCard(title: 'Points', value: '0', icon: Icons.emoji_events_outlined),
                  SizedBox(width: 12),
                  _KpiCard(title: 'Completed', value: '0', icon: Icons.check_circle_outline),
                  SizedBox(width: 12),
                  _KpiCard(title: 'Today', value: '0', icon: Icons.today_outlined),
                ],
              ),

              const SizedBox(height: 16),

              // QUICK ACTIONS
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Quick actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No tasks available yet. Create tasks or start organizing your household.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: paleRoyalBlue,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              label: 'Group',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Personal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _KpiCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
