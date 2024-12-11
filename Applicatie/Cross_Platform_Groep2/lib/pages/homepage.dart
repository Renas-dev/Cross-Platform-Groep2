import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manage_teams.dart';
import 'manage_events.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
              Text('Hello, $_username!'),
              const SizedBox(height: 20),
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
                child: const Text('Manage your teams'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to CreateEventScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageEventsPage(
                        token: widget.token,
                      ),
                    ),
                  );
                },
                child: const Text('Manage Events'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
