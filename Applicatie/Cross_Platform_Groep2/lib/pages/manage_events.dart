import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'view_event.dart';

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

  // Create event function
  Future<void> createEvent() async {
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
      fetchEvents();
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

  // Select start time and date
  Future<void> _selectStartTime(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _eventStartTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventStartTime ?? DateTime.now()),
      );

      if (selectedTime != null) {
        final selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          _eventStartTime = selectedDateTime;
          _startTimeController.text =
              '${"${selectedDateTime.toLocal()}".split(' ')[0]} ${selectedTime.format(context)}';
        });
      }
    }
  }

  // Select end time and date
  Future<void> _selectEndTime(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _eventEndTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventEndTime ?? DateTime.now()),
      );

      if (selectedTime != null) {
        final selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          _eventEndTime = selectedDateTime;
          _endTimeController.text =
              '${"${selectedDateTime.toLocal()}".split(' ')[0]} ${selectedTime.format(context)}';
        });
      }
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
              // Event creation section
              const Text(
                'Create Event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align to the left
                children: [
                  const Text(
                    'Teams',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Align(
                    alignment:
                        Alignment.centerLeft, // Align dropdown to the left
                    child: DropdownButton<String>(
                      value: _teamIdToCreate.isEmpty ? null : _teamIdToCreate,
                      onChanged: (newValue) {
                        setState(() {
                          _teamIdToCreate = newValue ?? '';
                        });
                      },
                      items: _teams.map((team) {
                        return DropdownMenuItem<String>(
                          value: team['id'].toString(),
                          child: Text(team['name']),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _eventTitle = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _eventDescription = value;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Event Description'),
              ),
              TextField(
                controller: _startTimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Start Time'),
                onTap: () => _selectStartTime(context),
              ),
              TextField(
                controller: _endTimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'End Time'),
                onTap: () => _selectEndTime(context),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _latitude = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _longitude = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _instructions = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Instructions'),
              ),
              ElevatedButton(
                onPressed: createEvent,
                child: const Text('Create Event'),
              ),
              if (_createMessage.isNotEmpty) Text(_createMessage),

              const SizedBox(height: 16),

              // Event list section
              const Text(
                'Manage Existing Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_events.isEmpty)
                const Center(child: Text('No events found.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final startTime = DateTime.parse(event['datetimeStart']);
                    final endTime = DateTime.parse(event['datetimeEnd']);
                    final latitude = event['location']['latitude'].toString();
                    final longitude = event['location']['longitude'].toString();
                    final instructions =
                        event['metadata']['instructions'] ?? 'No instructions';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 10.0), // Space around each event
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey,
                            width: 1.5), // Border color and width
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                      child: ListTile(
                        title: Text(event['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description: ${event['description']}'),
                            Text('Start Time: ${startTime.toLocal()}'),
                            Text('End Time: ${endTime.toLocal()}'),
                            Text('Latitude: $latitude'),
                            Text('Longitude: $longitude'),
                            Text('Instructions: $instructions'),
                          ],
                        ),
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
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                deleteEvent(event['id'].toString());
                              },
                            ),
                          ],
                        ),
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
