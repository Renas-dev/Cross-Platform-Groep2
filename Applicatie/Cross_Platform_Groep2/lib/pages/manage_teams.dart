import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CreateTeamPage extends StatefulWidget {
  final String token;

  const CreateTeamPage({super.key, required this.token});

  @override
  _CreateTeamPageState createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  String _teamName = '';
  String _teamDescription = '';
  String _createMessage = '';
  String _deleteMessage = '';
  String _editMessage = '';
  String _teamIdToEdit = '';
  String _newTeamName = '';
  String _newTeamDescription = '';
  String _teamIdToDelete = '';
  String _fetchMessage = '';
  List<dynamic> _teams = [];
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    fetchTeams(); // Initial fetch
  }

  // Load username from SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  // Function to fetch teams
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

  // Function to edit a team
  Future<void> editTeam(
      String teamId, String newTeamName, String newTeamDescription) async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    try {
      final response = await http.put(
        Uri.parse('https://team-management-api.dops.tech/api/v2/teams/$teamId'),
        headers: headers,
        body: jsonEncode({
          'name': newTeamName,
          'description': newTeamDescription,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _editMessage = 'Team updated successfully!';
        });
        fetchTeams(); // Refresh the teams list after editing
      } else {
        setState(() {
          _editMessage = 'Failed to update team: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _editMessage = 'An error occurred: $e';
      });
    }
  }

  // Function to delete a team
  Future<void> deleteTeam(String teamId) async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'accept': 'application/json',
    };

    try {
      final response = await http.delete(
        Uri.parse('https://team-management-api.dops.tech/api/v2/teams/$teamId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _deleteMessage = 'Team deleted successfully';
        });
        fetchTeams(); // Re-fetch teams after deletion
      } else {
        // Parse response body for detailed error message
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            responseBody['message']?.toString() ?? 'Unknown error';

        // Check for specific error cases
        if (errorMessage.toLowerCase().contains('teamnotfound')) {
          setState(() {
            _deleteMessage = 'Failed to delete team: Team not found';
          });
        } else {
          setState(() {
            _deleteMessage = 'Failed to delete team: Team does not exist.';
          });
        }
        setState(() {
          _deleteMessage = 'Failed to delete team: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _deleteMessage = 'An error occurred: $e';
      });
    }
  }

  // Function to create a team
  Future<void> createTeam(String teamName, String teamDescription) async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    final response = await http.post(
      Uri.parse('https://team-management-api.dops.tech/api/v2/teams'),
      headers: headers,
      body: jsonEncode({
        'name': teamName,
        'description': teamDescription,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        _createMessage = 'Team created successfully';
      });
      fetchTeams(); // Refresh teams after creation
    } else {
      setState(() {
        _createMessage = 'Failed to create team: ${response.body}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create Team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _teamName = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _teamDescription = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Team Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  createTeam(_teamName, _teamDescription);
                },
                child: const Text('Create Team'),
              ),
              Text(
                _createMessage,
                style: const TextStyle(color: Colors.green),
              ),
              const Divider(height: 40, thickness: 1),
              const Text(
                'Edit Team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _teamIdToEdit = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Team ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _newTeamName = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'New Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _newTeamDescription = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'New Team Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  editTeam(_teamIdToEdit, _newTeamName, _newTeamDescription);
                },
                child: const Text('Edit Team'),
              ),
              Text(
                _editMessage,
                style: const TextStyle(color: Colors.blue),
              ),
              const Divider(height: 40, thickness: 1),
              const Text(
                'Delete Team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _teamIdToDelete = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Team ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  deleteTeam(_teamIdToDelete);
                },
                child: const Text('Delete Team'),
              ),
              Text(
                _deleteMessage,
                style: const TextStyle(color: Colors.red),
              ),
              const Divider(height: 40, thickness: 1),
              ElevatedButton(
                onPressed: fetchTeams,
                child: const Text('Fetch your Teams'),
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
                        final description =
                            team['description'] ?? 'No description available';

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
                                const Text('Members:'),
                                Text('Description: $description'),
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
