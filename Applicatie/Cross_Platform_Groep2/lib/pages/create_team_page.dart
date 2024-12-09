import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class CreateTeamPage extends StatefulWidget {
  final String token;

  const CreateTeamPage({super.key, required this.token});

  @override
  _CreateTeamPageState createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  String _teamName = '';
  String _createMessage = '';

  // Function to create a team and redirect back
  Future<void> createTeam(String teamName) async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    final response = await http.post(
      Uri.parse('https://team-management-api.dops.tech/api/v2/teams'),
      headers: headers,
      body: jsonEncode({'name': teamName}),
    );

    if (response.statusCode == 201) {
      // Redirect back to the HomePage
      Navigator.pop(context); // Return to the previous page
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
        title: const Text('Create Team'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                createTeam(_teamName); // Call create team function
              },
              child: const Text('Create Team'),
            ),
            const SizedBox(height: 20),
            Text(
              _createMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
