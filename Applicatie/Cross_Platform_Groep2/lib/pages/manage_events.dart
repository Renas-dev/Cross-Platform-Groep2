import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'view_event.dart';
import 'edit_event.dart';

class ManageEventsPage extends StatefulWidget {
  final String token;

  const ManageEventsPage({super.key, required this.token});

  @override
  _ManageEventsPageState createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage> {
  String _eventTitle = '';
  String _eventDescription = '';
  String _teamIdToCreate = '';
  String _createMessage = '';
  String _deleteMessage = '';
  String _fetchMessage = '';
  List<dynamic> _events = [];
  List<dynamic> _teams = [];
  String _username = '';
  DateTime? _eventStartTime;
  DateTime? _eventEndTime;
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // New input fields for latitude, longitude, and instructions
  String _latitude = '';
  String _longitude = '';
  String _instructions = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    fetchTeams(); // Fetch teams the user is part of
    fetchEvents(); // Fetch events the user is part of
  }

  // Load username from SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  // Fetch teams
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

          // Filter teams where the user is an admin
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

  // Fetch events
  Future<void> fetchEvents() async {
    if (widget.token.isNotEmpty) {
      final headers = {
        HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
        'accept': 'application/json',
      };

      try {
        final response = await http.get(
          Uri.parse('https://team-management-api.dops.tech/api/v2/events'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final responseJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          final allEvents = responseJson['data'] as List<dynamic>;

          // Filter events where the user is part of the team
          final userEvents = allEvents.where((event) {
            return event['team']['members'].any((member) =>
                member['name'].toString().toLowerCase() ==
                _username.toLowerCase());
          }).toList();

          setState(() {
            _events = userEvents;
          });
        } else {
          setState(() {
            _fetchMessage = 'Failed to fetch events: ${response.body}';
          });
        }
      } catch (e) {
        setState(() {
          _fetchMessage = 'An error occurred: $e';
        });
      }
    }
  }

  // Create event function with validation
  Future<void> createEvent() async {
    // Validate if all fields are filled
    if (_teamIdToCreate.isEmpty ||
        _eventTitle.isEmpty ||
        _eventStartTime == null ||
        _eventEndTime == null ||
        _latitude.isEmpty ||
        _longitude.isEmpty ||
        _instructions.isEmpty) {
      setState(() {
        _createMessage =
            'Please fill in all the fields. (Team, Title, Description, Start Time, End Time, Latitude, Longitude, Instructions)';
      });
      return;
    }

    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    final response = await http.post(
      Uri.parse('https://team-management-api.dops.tech/api/v2/events'),
      headers: headers,
      body: jsonEncode({
        'title': _eventTitle,
        'description': _eventDescription,
        'datetimeStart': _eventStartTime!.toIso8601String(),
        'datetimeEnd': _eventEndTime!.toIso8601String(),
        'location': {
          'latitude': double.tryParse(_latitude) ?? 0.0,
          'longitude': double.tryParse(_longitude) ?? 0.0
        },
        'teamId': _teamIdToCreate,
        'metadata': {'instructions': _instructions},
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        _createMessage = 'Event created successfully!';
      });
      fetchEvents(); // Refresh events after creation
    } else {
      setState(() {
        _createMessage = 'Failed to create event: ${response.body}';
      });
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    if (eventId.isEmpty) {
      setState(() {
        _deleteMessage = 'Please provide a valid event ID.';
      });
      return;
    }

    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
      'accept': 'application/json',
    };

    try {
      final response = await http.delete(
        Uri.parse(
            'https://team-management-api.dops.tech/api/v2/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _deleteMessage = 'Event deleted successfully!';
        });
        fetchEvents(); // Refresh events list
      } else {
        setState(() {
          _deleteMessage = 'Failed to delete event: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _deleteMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Create Event',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Team dropdown with consistent styling
              DropdownButtonFormField<String>(
                value: _teamIdToCreate.isEmpty ? null : _teamIdToCreate,
                hint: const Text('Select Team'),
                onChanged: (String? newValue) {
                  setState(() {
                    _teamIdToCreate = newValue ?? '';
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Team',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                items: _teams.map<DropdownMenuItem<String>>((team) {
                  return DropdownMenuItem<String>(
                    value: team['id'].toString(),
                    child: Text(team['name']),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Event Title Field with consistent styling
              TextField(
                onChanged: (value) => _eventTitle = value,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Event Description Field with consistent styling
              TextField(
                onChanged: (value) => _eventDescription = value,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Start Time Field with consistent styling
              TextField(
                controller: _startTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              // End Time Field with consistent styling
              TextField(
                controller: _endTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Latitude Field with consistent styling
              TextField(
                onChanged: (value) => _latitude = value,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Longitude Field with consistent styling
              TextField(
                onChanged: (value) => _longitude = value,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Instructions Field with consistent styling
              TextField(
                onChanged: (value) => _instructions = value,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: createEvent,
                child: const Text('Create Event'),
              ),
              if (_createMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_createMessage, style: const TextStyle(color: Colors.red)),
              ],

              // Event display section
              const SizedBox(height: 40),
              const Text(
                'Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ..._events.map(
                (event) {
                  return ListTile(
                    title: Text(event['title']),
                    subtitle: Text(event['datetimeStart']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailPage(
                                  token: widget.token,
                                  eventId: event['id'].toString(),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditEventPage(
                                  token: widget.token,
                                  eventId: event['id'].toString(),
                                ),
                              ),
                            );

                            if (success != null && success) {
                              fetchEvents(); // Refresh event list after edit
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteEvent(event['id'].toString());
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_deleteMessage.isNotEmpty) Text(_deleteMessage),
            ],
          ),
        ),
      ),
    );
  }
}
