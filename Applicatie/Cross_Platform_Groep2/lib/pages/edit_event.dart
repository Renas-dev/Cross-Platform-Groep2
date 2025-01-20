import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditEventPage extends StatefulWidget {
  final String token;
  final String eventId;

  const EditEventPage({super.key, required this.token, required this.eventId});

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  String _eventTitle = '';
  String _eventDescription = '';
  DateTime? _eventStartTime;
  DateTime? _eventEndTime;
  String _latitude = '';
  String _longitude = '';
  String _instructions = '';

  // Fetch event details
  Future<void> fetchEventDetails() async {
    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(
        Uri.parse(
            'https://team-management-api.dops.tech/api/v2/events/${widget.eventId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final event = jsonDecode(response.body)['data'];
        setState(() {
          _eventTitle = event['title'];
          _eventDescription = event['description'];
          _eventStartTime = DateTime.parse(event['datetimeStart']);
          _eventEndTime = DateTime.parse(event['datetimeEnd']);
          _latitude = event['location']['latitude'].toString();
          _longitude = event['location']['longitude'].toString();
          _instructions = event['metadata']['instructions'];
        });
      } else {
        print('Failed to fetch event details: ${response.body}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => _eventTitle = value,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              controller: TextEditingController(text: _eventTitle),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => _eventDescription = value,
              decoration: const InputDecoration(
                labelText: 'Event Description',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              controller: TextEditingController(text: _eventDescription),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => _latitude = value,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              controller: TextEditingController(text: _latitude),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => _longitude = value,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              controller: TextEditingController(text: _longitude),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => _instructions = value,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              controller: TextEditingController(text: _instructions),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Save edited event details
                final headers = {
                  'Authorization': 'Bearer ${widget.token}',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                };

                final response = await http.put(
                  Uri.parse(
                      'https://team-management-api.dops.tech/api/v2/events/${widget.eventId}'),
                  headers: headers,
                  body: jsonEncode({
                    'title': _eventTitle,
                    'description': _eventDescription,
                    'datetimeStart': _eventStartTime!.toIso8601String(),
                    'datetimeEnd': _eventEndTime!.toIso8601String(),
                    'location': {
                      'latitude': double.tryParse(_latitude) ?? 0.0,
                      'longitude': double.tryParse(_longitude) ?? 0.0,
                    },
                    'metadata': {'instructions': _instructions},
                  }),
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context, true); // Notify success
                } else {
                  print('Failed to edit event: ${response.body}');
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
