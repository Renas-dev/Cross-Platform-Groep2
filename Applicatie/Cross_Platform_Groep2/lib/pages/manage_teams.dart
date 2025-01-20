import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'view_team.dart';
import 'edit_team.dart';

class ManageTeamsPage extends StatefulWidget {
  final String token;

  const ManageTeamsPage({super.key, required this.token});

  @override
  _ManageTeamsPageState createState() => _ManageTeamsPageState();
}

class _ManageTeamsPageState extends State<ManageTeamsPage> {
  String _teamName = '';
  String _teamDescription = '';
  String _createMessage = '';
  String _deleteMessage = '';
  String _addUserMessage = '';
  String _editMessage = '';
  String _teamIdToDelete = '';
  String _teamIdToAddUser = '';
  String _userIdToAdd = '';
  String _teamIdToEdit = '';
  String _fetchMessage = '';
  List<dynamic> _teams = [];
  String _username = '';

  final GlobalKey<FormState> _createFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _deleteFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _addUserFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    fetchTeams();
  }

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

  Future<void> createTeam(String teamName, String teamDescription) async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse('https://team-management-api.dops.tech/api/v2/teams'),
        headers: headers,
        body: jsonEncode({
          'name': teamName,
          'description': teamDescription,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _createMessage = 'Team created successfully!';
        });
        fetchTeams();
      } else {
        setState(() {
          _createMessage = 'Failed to create team: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _createMessage = 'An error occurred: $e';
      });
    }
  }

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

      if (response.statusCode == 200) {
        setState(() {
          _deleteMessage = 'Team deleted successfully!';
        });
        fetchTeams();
      } else {
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

  Future<void> addUserToTeam(String teamId, String userId) async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://team-management-api.dops.tech/api/v2/teams/$teamId/addUser'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _addUserMessage = 'User added successfully!';
        });
        fetchTeams(); // Refresh the teams list after adding the user
      } else {
        final responseJson = jsonDecode(response.body);
        final errorMessage = responseJson['error'] ?? 'Unknown error occurred';

        setState(() {
          _addUserMessage = 'Failed to add user: $errorMessage';
        });
      }
    } catch (e) {
      setState(() {
        _addUserMessage = 'An error occurred: $e';
      });
    }
  }

  String? validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
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
                'Create New Team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Form(
                key: _createFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _teamName = value;
                        });
                      },
                      validator: validateInput,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _teamDescription = value;
                        });
                      },
                      validator: validateInput,
                      decoration: const InputDecoration(
                        labelText: 'Team Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_createFormKey.currentState!.validate()) {
                          createTeam(_teamName, _teamDescription);
                        }
                      },
                      child: const Text('Create Team'),
                    ),
                    Text(
                      _createMessage,
                      style: const TextStyle(color: Colors.green),
                    ),
                    const Divider(height: 40, thickness: 1),
                  ],
                ),
              ),
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
                                Text('Description: $description'),
                                const SizedBox(height: 8),
                                const Text('Members:'),
                                for (var member in members)
                                  Text('- ${member['name']}'),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // To prevent buttons from taking up too much space
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          _teamIdToAddUser =
                                              team['id'].toString();
                                        });
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text('Add User to Team'),
                                            content: Form(
                                              key: _addUserFormKey,
                                              child: TextFormField(
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'User ID',
                                                  border: OutlineInputBorder(),
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _userIdToAdd = value;
                                                  });
                                                },
                                                validator: validateInput,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (_addUserFormKey
                                                      .currentState!
                                                      .validate()) {
                                                    addUserToTeam(
                                                        _teamIdToAddUser,
                                                        _userIdToAdd);
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                                child: const Text('Add User'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewTeamPage(
                                              token: widget.token,
                                              teamId: team['id'].toString(),
                                            ),
                                          ),
                                        ).then((_) =>
                                            fetchTeams()); // Refresh after viewing
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditTeamPage(
                                              token: widget.token,
                                              teamId: team['id'].toString(),
                                            ),
                                          ),
                                        ).then((_) =>
                                            fetchTeams()); // Refresh after editing
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        deleteTeam(team['id'].toString());
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Text(_fetchMessage),
              if (_deleteMessage.isNotEmpty) Text(_deleteMessage),
              if (_addUserMessage.isNotEmpty) Text(_addUserMessage),
            ],
          ),
        ),
      ),
    );
  }
}
