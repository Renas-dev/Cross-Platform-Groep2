import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_team_page.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _teams = [];
  String _fetchMessage = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // Load username from SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<void> fetchTeams() async {
    if (widget.token.isNotEmpty) {
      final headers = {
        HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
        'accept': 'application/json',
      };

      try {
        final response = await http.get(
          Uri.parse('https://team-management-api.dops.tech/api/v2/teams'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final responseJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          final allTeams = responseJson['data'] as List<dynamic>;

          // Filter teams by username
          final userTeams = allTeams.where((team) {
            final members = team['members'] as List<dynamic>;
            return members.any((member) =>
                member['name'].toString().toLowerCase() ==
                _username.toLowerCase());
          }).toList();

          setState(() {
            _teams = userTeams;
            _fetchMessage = 'Teams fetched successfully!';
          });
        } else {
          setState(() {
            _fetchMessage = 'Failed to fetch teams: ${response.body}';
          });
        }
      } catch (e) {
        setState(() {
          _fetchMessage = 'An error occurred: $e';
        });
      }
    } else {
      setState(() {
        _fetchMessage = 'No token found! Please log in first.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to the Home Page!'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchTeams,
                child: const Text('Fetch Teams'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTeamPage(
                        token: widget.token,
                      ),
                    ),
                  );
                },
                child: const Text('Create Team'),
              ),
              const SizedBox(height: 20),
              _teams.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        final members = team['members'] as List<dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text(team['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Team ID: ${team['id']}'),
                                const SizedBox(height: 8),
                                Text('Members:'),
                                for (var member in members)
                                  Text('- ${member['name']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Text(_fetchMessage),
            ],
          ),
        ),
      ),
    );
  }
}
