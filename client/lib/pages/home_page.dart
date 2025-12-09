import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import 'profile_page.dart';
import 'group_tasks_page.dart';
import 'personal_tasks_page.dart';
import 'ranking_page.dart';

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
  String? _householdName;
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

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
            _householdName = households[0]['name'];
          });
          _loadStats();
        }
      }
    } catch (e) {
      print('Error loading household: $e');
    }
  }

  Future<void> _loadStats() async {
    if (_userId == null || _householdId == null) return;
    
    setState(() => _loadingStats = true);
    try {
      final uri = Uri.parse('${Api.base}/api/tasks/stats?householdId=$_householdId');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': _userId!,
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(resp.body);
          _loadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _loadingStats = false);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_userId == null) return;

    if (index == 1 && _householdId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupTasksPage(
            userId: _userId!,
            householdId: _householdId!,
            householdName: _householdName,
          ),
        ),
      ).then((_) => _loadStats());
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalTasksPage(userId: _userId!),
        ),
      ).then((_) => _loadStats());
    } else if (index == 3) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome${widget.userName != null ? ', ${widget.userName}' : ''}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (_householdName != null)
                        Text(
                          _householdName!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // KPI CARDS
              if (_loadingStats)
                const Center(child: CircularProgressIndicator(color: Colors.white))
              else
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        title: 'Points',
                        value: '${_stats['points'] ?? 0}',
                        icon: Icons.emoji_events_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'Completed',
                        value: '${_stats['completed'] ?? 0}',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'Today',
                        value: '${_stats['today'] ?? 0}',
                        icon: Icons.today_outlined,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // QUICK ACTIONS
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.group,
                              label: 'Group\nTasks',
                              color: paleRoyalBlue,
                              onTap: () => _onTabTapped(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.person,
                              label: 'Personal\nTasks',
                              color: palePurple,
                              onTap: () => _onTabTapped(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.emoji_events,
                              label: 'Ranking',
                              color: const Color(0xFFFFD700),
                              onTap: () {
                                if (_householdId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RankingPage(
                                        userId: _userId!,
                                        householdId: _householdId!,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PROGRESS INDICATOR
              if (!_loadingStats && _stats['total'] != null && _stats['total'] > 0)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Weekly Progress',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${_stats['completed']}/${_stats['total']}',
                              style: const TextStyle(
                                color: paleRoyalBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_stats['completed'] ?? 0) / (_stats['total'] ?? 1),
                            backgroundColor: Colors.grey[200],
                            color: paleRoyalBlue,
                            minHeight: 8,
                          ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7E9BFF)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}