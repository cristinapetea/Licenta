import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

const Color kPaleRoyalBlue = Color(0xFF7E9BFF);
const Color kPalePurple = Color(0xFFD3B8FF);
const Color kPalePink = Color(0xFFFFD8F1);
const Color kDeepIndigo = Color(0xFF4B4FA7);

class ProfilePage extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? householdId;
  
  const ProfilePage({
    super.key,
    required this.userId,
    this.userName,
    this.householdId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _householdData;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Obține informațiile despre utilizator
      _userData = {
        'id': widget.userId,
        'name': widget.userName,
      };
      
      // Dacă nu avem nume, îl obținem din membrii household-ului
      if (widget.userName == null) {
        // Vom încerca să obținem numele din membrii household-ului mai jos
      }

      // Dacă avem householdId, obține membrii
      if (widget.householdId != null) {
        final uri = Uri.parse('${Api.base}/api/households/${widget.householdId}/members');
        final resp = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-user': widget.userId,
          },
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          setState(() {
            _householdData = data['household'];
            _members = List<Map<String, dynamic>>.from(data['members']);
          });
        } else {
          setState(() {
            _error = 'Failed to load household data: ${resp.body}';
          });
        }
      } else {
        // Dacă nu avem householdId, încercăm să obținem household-urile utilizatorului
        final uri = Uri.parse('${Api.base}/api/households/mine');
        final resp = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-user': widget.userId,
          },
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final households = jsonDecode(resp.body) as List;
          if (households.isNotEmpty) {
            final firstHousehold = households[0];
            final householdId = firstHousehold['_id']?.toString() ?? firstHousehold['id']?.toString();
            
            if (householdId != null) {
              // Reîncarcă cu householdId-ul găsit
              final membersUri = Uri.parse('${Api.base}/api/households/$householdId/members');
              final membersResp = await http.get(
                membersUri,
                headers: {
                  'Content-Type': 'application/json',
                  'x-user': widget.userId,
                },
              ).timeout(const Duration(seconds: 10));

              if (membersResp.statusCode == 200) {
                final data = jsonDecode(membersResp.body);
                setState(() {
                  _householdData = data['household'];
                  _members = List<Map<String, dynamic>>.from(data['members']);
                  
                  // Obține numele utilizatorului din membrii household-ului dacă nu l-am primit
                  if (widget.userName == null) {
                    final currentUser = _members.firstWhere(
                      (m) => m['id']?.toString() == widget.userId,
                      orElse: () => {},
                    );
                    if (currentUser['name'] != null) {
                      _userData = {
                        'id': widget.userId,
                        'name': currentUser['name'],
                        'email': currentUser['email'],
                      };
                    }
                  }
                });
              }
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPaleRoyalBlue, kPalePurple],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                              const Expanded(
                                child: Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // User Greeting Card
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getUserName() != null 
                                        ? 'Hello, ${_getUserName()}!'
                                        : 'Hello!',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (_userData != null && _userData!['email'] != null) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow('Email', _userData!['email']),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Household Info Card
                          if (_householdData != null)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Household',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Name', _householdData!['name'] ?? 'N/A'),
                                    if (_householdData!['address'] != null)
                                      _buildInfoRow('Address', _householdData!['address']),
                                    _buildInfoRow(
                                      'Invite Code',
                                      _householdData!['inviteCode'] ?? 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Members Card
                          if (_householdData != null)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Household Members',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text('${_members.length}'),
                                          backgroundColor: kPalePurple,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_members.isEmpty)
                                      const Text(
                                        'No members yet',
                                        style: TextStyle(color: Colors.grey),
                                      )
                                    else
                                      ..._members.map((member) => _buildMemberTile(member)),
                                  ],
                                ),
                              ),
                            ),

                          if (_householdData == null)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No household yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Create or join a household to see members here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  String? _getUserName() {
    if (widget.userName != null) return widget.userName;
    if (_userData != null && _userData!['name'] != null) return _userData!['name'];
    // Încearcă să găsească numele din membrii household-ului
    if (_members.isNotEmpty) {
      final currentUser = _members.firstWhere(
        (m) => m['id']?.toString() == widget.userId,
        orElse: () => {},
      );
      return currentUser['name']?.toString();
    }
    return null;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final isOwner = member['isOwner'] ?? false;
    final isCurrentUser = member['id']?.toString() == widget.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? kPalePurple.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isOwner ? kDeepIndigo : kPaleRoyalBlue,
            child: Text(
              (member['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
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
                      member['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('You', style: TextStyle(fontSize: 10)),
                        backgroundColor: kDeepIndigo,
                        labelStyle: TextStyle(color: Colors.white),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('Owner', style: TextStyle(fontSize: 10)),
                        backgroundColor: kDeepIndigo,
                        labelStyle: TextStyle(color: Colors.white),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      ),
                    ],
                  ],
                ),
                if (member['email'] != null)
                  Text(
                    member['email'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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

