import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class RecommendationsPage extends StatefulWidget {
  final String userId;
  final String householdId;
  final Map<String, dynamic>? performanceData; // ⭐ PRIMEȘTE DATELE DIRECT!

  const RecommendationsPage({
    super.key,
    required this.userId,
    required this.householdId,
    this.performanceData, // Opțional - dacă există, nu mai face request
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _recommendations;
  Map<String, dynamic>? _performanceData;

  @override
  void initState() {
    super.initState();
    print('🔍 RecommendationsPage initState');
    print('   userId: ${widget.userId}');
    print('   householdId: ${widget.householdId}');
    print('   performanceData: ${widget.performanceData != null ? "YES" : "NO"}');
    
    if (widget.performanceData != null) {
      print('✅ Using provided performance data');
      _performanceData = widget.performanceData;
      _generateRecommendations();
    } else {
      print('⚠️ No performance data - loading from API');
      _loadRecommendations();
    }
  }

  Future<void> _generateRecommendations() async {
    setState(() => _isLoading = true);

    try {
      print('🤖 Generating recommendations');
      print('   Performance data: ${jsonEncode(_performanceData)}');

      final recUri = Uri.parse('${Api.base}/api/ai/personal-recommendations');
      print('📤 Calling: $recUri');
      
      final recResp = await http.post(
        recUri,
        headers: {
          'Content-Type': 'application/json',
          'x-user': widget.userId,
        },
        body: jsonEncode({
          'userId': widget.userId,
          'householdId': widget.householdId,
          'performanceData': _performanceData,
        }),
      ).timeout(const Duration(seconds: 20));

      print('🤖 AI response status: ${recResp.statusCode}');
      print('🤖 AI response body: ${recResp.body}');

      if (recResp.statusCode == 200) {
        final recData = jsonDecode(recResp.body);
        setState(() {
          _recommendations = recData;
          _isLoading = false;
        });
        print('✅ Recommendations loaded successfully!');
      } else {
        print('❌ AI API error: ${recResp.statusCode}');
        print('   Response: ${recResp.body}');
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ${recResp.statusCode}: ${recResp.body}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Exception in _generateRecommendations: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 Loading performance data from /api/performance/ranking');
      
      final perfUri = Uri.parse('${Api.base}/api/performance/ranking?householdId=${widget.householdId}');
      final perfResp = await http.get(
        perfUri,
        headers: {'x-user': widget.userId},
      ).timeout(const Duration(seconds: 15));

      print('📊 Performance response status: ${perfResp.statusCode}');
      
      if (perfResp.statusCode == 200) {
        final perfData = jsonDecode(perfResp.body);
        print('📊 Performance data keys: ${perfData.keys}');
        
        final membersList = perfData['members'] as List?;
        print('👥 Members count: ${membersList?.length ?? 0}');
        
        if (membersList != null && membersList.isNotEmpty) {
          print('👥 All member IDs:');
          for (var m in membersList) {
            print('   - ${m['memberId']} (${m['memberName']})');
          }
          print('🔍 Looking for: ${widget.userId}');
          
          final myPerf = membersList.firstWhere(
            (m) {
              final match = m['memberId'] == widget.userId;
              print('   Comparing ${m['memberId']} == ${widget.userId}: $match');
              return match;
            },
            orElse: () => null,
          );

          if (myPerf != null) {
            print('✅ Found my data: ${myPerf['memberName']}');
            setState(() => _performanceData = myPerf);
            await _generateRecommendations();
          } else {
            print('❌ User not found in ranking');
            print('   Available IDs: ${membersList.map((m) => m['memberId']).toList()}');
            print('   My ID: ${widget.userId}');
            setState(() => _isLoading = false);
          }
        } else {
          print('❌ No members in ranking');
          setState(() => _isLoading = false);
        }
      } else {
        print('❌ Performance API error: ${perfResp.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Exception: $e');
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

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Personal Recommendations'),
        backgroundColor: paleRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Complete more tasks\nto receive recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadRecommendations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paleRoyalBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_recommendations!['motivationalMessage'] != null)
                          Card(
                            color: paleRoyalBlue.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: paleRoyalBlue.withOpacity(0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events, 
                                       color: Colors.amber[700], size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _recommendations!['motivationalMessage'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[800],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        if (_recommendations!['strengths'] != null &&
                            (_recommendations!['strengths'] as List).isNotEmpty)
                          _buildSection(
                            title: '💪 Your Strengths',
                            color: Colors.green,
                            icon: Icons.trending_up,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_recommendations!['strengths'] as List)
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor: Colors.green[50],
                                        labelStyle: TextStyle(color: Colors.green[900]),
                                      ))
                                  .toList(),
                            ),
                          ),

                        const SizedBox(height: 16),

                        if (_recommendations!['thisWeekRecommendations'] != null)
                          _buildSection(
                            title: '🎯 This Week\'s Recommendations',
                            color: paleRoyalBlue,
                            icon: Icons.calendar_today,
                            child: Column(
                              children: (_recommendations!['thisWeekRecommendations'] as List)
                                  .map((rec) => Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: paleRoyalBlue.withOpacity(0.2),
                                            child: Icon(Icons.task_alt, 
                                                       color: paleRoyalBlue, size: 20),
                                          ),
                                          title: Text(
                                            rec['taskTitle'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: paleRoyalBlue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  rec['category'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: paleRoyalBlue,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                rec['reason'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),

                        const SizedBox(height: 16),

                        if (_recommendations!['improvementSuggestions'] != null &&
                            (_recommendations!['improvementSuggestions'] as List).isNotEmpty)
                          _buildSection(
                            title: '📈 How to Improve',
                            color: Colors.orange,
                            icon: Icons.lightbulb_outline,
                            child: Column(
                              children: (_recommendations!['improvementSuggestions'] as List)
                                  .map((sug) => Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        color: Colors.orange[50],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.star_border, 
                                                       color: Colors.orange[700], size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    sug['category'],
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.orange[900],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                sug['suggestion'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}