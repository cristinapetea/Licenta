import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class RankingPage extends StatefulWidget {
  final String userId;
  final String householdId;

  const RankingPage({
    super.key,
    required this.userId,
    required this.householdId,
  });

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  bool _loading = true;
  Map<String, dynamic>? _rankingData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

 Future<void> _loadRanking() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
   final uri = Uri.parse(
  '${Api.base}/api/ai/ranking?householdId=${widget.householdId}'
);
    
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-user': widget.userId,
      },
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      setState(() {
        _rankingData = jsonDecode(resp.body);
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load ranking';
        _loading = false;
      });
    }
  } catch (e) {
    setState(() {
      _error = 'Error: $e';
      _loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    const palePurple = Color(0xFFD3B8FF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [paleRoyalBlue, palePurple],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        '🏆 Performance Ranking',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 64, color: Colors.white70),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadRanking,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _buildRankingList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    if (_rankingData == null || _rankingData!['members'] == null) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final members = _rankingData!['members'] as List;
    final currentUserId = widget.userId;

    return RefreshIndicator(
      onRefresh: _loadRanking,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final isCurrentUser = member['memberId'] == currentUserId;

          return _MemberRankCard(
            rank: member['rank'],
            name: member['memberName'],
            completionRate: member['overallCompletionRate'],
            totalTasks: member['totalTasks'],
            completedTasks: member['totalCompleted'],
            top3Strengths: member['top3Strengths'] as List,
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }
}

class _MemberRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final int completionRate;
  final int totalTasks;
  final int completedTasks;
  final List top3Strengths;
  final bool isCurrentUser;

  const _MemberRankCard({
    required this.rank,
    required this.name,
    required this.completionRate,
    required this.totalTasks,
    required this.completedTasks,
    required this.top3Strengths,
    required this.isCurrentUser,
  });

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank.';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentUser
            ? const BorderSide(color: Color(0xFF7E9BFF), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rank and name
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getRankEmoji(rank),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7E9BFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '$completedTasks/$totalTasks tasks ($completionRate%)',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF7E9BFF),
                minHeight: 8,
              ),
            ),

            if (top3Strengths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '⭐ Top 3 Strengths',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...top3Strengths.asMap().entries.map((entry) {
                final idx = entry.key;
                final strength = entry.value;
                return _StrengthItem(
                  index: idx + 1,
                  name: strength['displayName'],
                  score: strength['score'].toDouble(),
                  completionRate: strength['completionRate'],
                  onTimeRate: strength['onTimeRate'],
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StrengthItem extends StatelessWidget {
  final int index;
  final String name;
  final double score;
  final int completionRate;
  final int onTimeRate;

  const _StrengthItem({
    required this.index,
    required this.name,
    required this.score,
    required this.completionRate,
    required this.onTimeRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF7E9BFF).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E9BFF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Score: ${score.toStringAsFixed(1)}/100 • $completionRate% done • $onTimeRate% on-time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}