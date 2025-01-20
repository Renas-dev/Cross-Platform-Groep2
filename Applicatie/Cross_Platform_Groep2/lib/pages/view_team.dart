import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ViewTeamPage extends StatefulWidget {
  final String token;
  final String teamId;

  const ViewTeamPage({super.key, required this.token, required this.teamId});

  @override
  _ViewTeamPageState createState() => _ViewTeamPageState();
}

class _ViewTeamPageState extends State<ViewTeamPage> {
  Map<String, dynamic> _team = {};
  List<dynamic> _teamMembers = [];
  String _message = '';

  @override
  void initState() {
    super.initState();
    fetchTeamDetails();
  }

  // Fetch team details
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
          _team = responseJson['data'] ?? {}; // Ensure data is not null
          _teamMembers = _team['members'] ?? []; // Ensure members are available
          _message = 'Team details fetched successfully!';
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

  @override
  Widget build(BuildContext context) {
    // Sort the team members by placing the owner at the top
    List<dynamic> sortedMembers = [];
    if (_teamMembers.isNotEmpty) {
      final ownerId = _team['ownerId'];

      // Separate the owner from other members
      final owner = _teamMembers.firstWhere(
        (member) => member['id'] == ownerId,
        orElse: () => null,
      );

      // Add the owner to the top of the list if found
      if (owner != null) {
        sortedMembers.add({
          'name': owner['name'],
          'role': 'Owner',
        });
      }

      // Add all other members with "Member" role
      sortedMembers.addAll(
          _teamMembers.where((member) => member['id'] != ownerId).map((member) {
        return {
          'name': member['name'],
          'role': 'Member',
        };
      }));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Team'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                _team.isNotEmpty
                    ? _team['name'] ?? 'No name available'
                    : 'Loading...',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _team.isNotEmpty
                    ? _team['description'] ?? 'No description available'
                    : 'Loading...',
              ),
              const SizedBox(height: 20),
              Text(
                'Members:',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (sortedMembers.isEmpty)
                const Text('No members in this team yet.')
              else
                ...sortedMembers.map((member) {
                  return ListTile(
                    title: Text(member['name'] ?? 'Unknown Member'),
                    subtitle: Text(member['role'] ?? 'Member'),
                  );
                }),
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
