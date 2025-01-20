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
      _username = prefs.getString('username') ?? 'Guest';
    });
  }

  // Log out user and redirect to login page
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username'); // Clear username
    await prefs.remove('token'); // Clear token

    Navigator.pushReplacementNamed(context, '/'); // Navigate to login page
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
              Text(
                'Welcome, $_username!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text('Hello, $_username!'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageTeamsPage(
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
                  // Navigate to ManageEventsPage
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout, // Now this only handles logout
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red color for logout button
                ),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
