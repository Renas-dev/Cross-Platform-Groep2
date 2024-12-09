import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pages/homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  String _loginMessage = '';
  String? _token; // Store the token in memory

  // Function to register user
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
        _loginMessage = 'User registered successfully. You can now log in.';
      });
    } else {
      setState(() {
        _loginMessage = 'Failed to register: ${response.body}';
      });
    }
  }

  // Function to login user and store token in memory
  void _loginUser(String name, String password) async {
    if (name.isEmpty || password.isEmpty) {
      setState(() {
        _loginMessage = 'Please fill in both fields to log in.';
      });
      return; // Exit early if fields are empty
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
          _token = responseBody['data']['token']; // Store the token
          _loginMessage = 'Login successful! Token stored.';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(token: _token!)),
          );
        });
        print('Login success! Token: $_token');
      } else {
        setState(() {
          _loginMessage = 'Login failed: No token found in response';
        });
      }
    } else {
      setState(() {
        _loginMessage = 'Login failed: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register and Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Register',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    labelText: 'Register Password',
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
                  _registerUser(
                      _registerName, _registerPassword); // Register user
                },
                child: const Text('Register'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Login Username',
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
                    labelText: 'Login Password',
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
                  _loginUser(_loginName, _loginPassword); // Call login function
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              Text(_loginMessage, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
