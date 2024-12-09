import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../main.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _teams = [];
  String _fetchMessage = '';

  // Function to fetch teams
  Future<void> fetchTeams() async {
    final headers = {
      HttpHeaders.authorizationHeader:
          'Bearer ${widget.token}', // Add token here
      'accept': 'application/json',
    };

    final response = await http.get(
      Uri.parse('https://team-management-api.dops.tech/api/v2/teams'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _teams =
            responseJson['data'] as List<dynamic>; // Store teams in the list
        _fetchMessage = 'Teams fetched successfully';
      });
    } else {
      setState(() {
        _fetchMessage = 'Failed to fetch teams: ${response.body}';
      });
    }
  }

  // Function to handle logout
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyApp(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Remove the fetchTeams call from here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        // Removed the actions section to remove the logout button in the top corner
      ),
      body: SingleChildScrollView(
        // Wrap the body content with SingleChildScrollView
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to the Home Page!'),
              const SizedBox(height: 20),

              // Logout button
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),

              // Button to fetch teams
              ElevatedButton(
                onPressed: fetchTeams, // Fetch teams when the button is pressed
                child: const Text('Fetch Teams'),
              ),

              const SizedBox(height: 20),

              // Display fetched teams
              _teams.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_teams[index]['name']),
                          subtitle: Text('Team ID: ${_teams[index]['id']}'),
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
