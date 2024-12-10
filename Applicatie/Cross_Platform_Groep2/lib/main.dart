import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamFormer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'TeamFormer Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _registerName = '';
  String _registerPassword = '';
  String _loginName = '';
  String _loginPassword = '';
  String _message = '';
  String? _token;
  bool _showRegisterForm = false;

  // Save username to SharedPreferences
  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // Function to register user and log them in
  void _registerUser(String name, String password) async {
    final response = await http.post(
      Uri.parse('https://team-management-api.dops.tech/api/v2/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        _message = 'User registered successfully. Logging in...';
      });
      _loginUser(name, password); // Log the user in after registration
    } else {
      setState(() {
        _message = 'Failed to register: ${response.body}';
      });
    }
  }

  // Function to login user and store token in memory
  void _loginUser(String name, String password) async {
    if (name.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Please fill in both fields to log in.';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('https://team-management-api.dops.tech/api/v2/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (responseBody.containsKey('data') &&
          responseBody['data']['token'] != null) {
        setState(() {
          _token = responseBody['data']['token'];
          _message = 'Login successful! Redirecting...';
        });

        await _saveUsername(name);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(token: _token!),
          ),
        );
      } else {
        setState(() {
          _message = 'Login failed: No token found in response';
        });
      }
    } else {
      setState(() {
        _message = 'Login failed: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teamformer'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_showRegisterForm)
                Column(
                  children: [
                    const Text(
                      'Register',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Register Username',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _registerName = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            _registerPassword = value;
                          });
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _registerUser(_registerName, _registerPassword);
                      },
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRegisterForm = false;
                        });
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Text(
                      'Login',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _loginName = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            _loginPassword = value;
                          });
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _loginUser(_loginName, _loginPassword);
                      },
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRegisterForm = true;
                        });
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Text(_message, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
