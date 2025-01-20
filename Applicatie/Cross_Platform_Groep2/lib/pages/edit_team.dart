import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class EditTeamPage extends StatefulWidget {
  final String token;
  final String teamId;

  const EditTeamPage({super.key, required this.token, required this.teamId});

  @override
  _EditTeamPageState createState() => _EditTeamPageState();
}

class _EditTeamPageState extends State<EditTeamPage> {
  String _teamName = '';
  String _teamDescription = '';
  String _message = '';
  Map<String, dynamic> _team = {};

  @override
  void initState() {
    super.initState();
    fetchTeamDetails();
  }

  // Fetch team details for editing
  Future<void> fetchTeamDetails() async {
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'accept': 'application/json',
    };

    try {
      final response = await http.get(
        Uri.parse(
            'https://team-management-api.dops.tech/api/v2/teams/${widget.teamId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _team = responseJson['data'];
          _teamName = _team['name'];
          _teamDescription = _team['description'];
        });
      } else {
        setState(() {
          _message = 'Failed to fetch team details: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred: $e';
      });
    }
  }

  // Update team details
  Future<void> updateTeam() async {
    if (_teamName.isEmpty || _teamDescription.isEmpty) {
      setState(() {
        _message = 'Please fill in both the Team Name and Description';
      });
      return;
    }

    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    final response = await http.put(
      Uri.parse(
          'https://team-management-api.dops.tech/api/v2/teams/${widget.teamId}'),
      headers: headers,
      body: jsonEncode({
        'name': _teamName,
        'description': _teamDescription,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _message = 'Team updated successfully!';
      });
    } else {
      setState(() {
        _message = 'Failed to update team: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Team'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Edit Team Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => _teamName = value,
                controller: TextEditingController(text: _teamName),
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => _teamDescription = value,
                controller: TextEditingController(text: _teamDescription),
                decoration: const InputDecoration(
                  labelText: 'Team Description',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateTeam,
                child: const Text('Update Team'),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_message, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
