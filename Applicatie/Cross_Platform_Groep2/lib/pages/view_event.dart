import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EventDetailPage extends StatefulWidget {
  final String token;
  final String eventId;

  const EventDetailPage(
      {super.key, required this.token, required this.eventId});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Map<String, dynamic> _eventDetails = {};
  String _fetchMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  // Fetch event details using the provided eventId
  Future<void> fetchEventDetails() async {
    if (widget.token.isNotEmpty && widget.eventId.isNotEmpty) {
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
          final responseJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _eventDetails = responseJson[
                'data']; // Assuming the event data is in 'data' key
            _fetchMessage = 'Event details fetched successfully!';
          });
        } else {
          setState(() {
            _fetchMessage = 'Failed to fetch event details: ${response.body}';
          });
        }
      } catch (e) {
        setState(() {
          _fetchMessage = 'An error occurred: $e';
        });
      }
    } else {
      setState(() {
        _fetchMessage = 'No token or event ID provided.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _eventDetails.isEmpty
            ? Center(child: Text(_fetchMessage))
            : Center(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligning text to the left
                    children: [
                      Text('Title: ${_eventDetails['title']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Description: ${_eventDetails['description']}'),
                      const SizedBox(height: 8),
                      Text('Start Time: ${_eventDetails['datetimeStart']}'),
                      const SizedBox(height: 8),
                      Text('End Time: ${_eventDetails['datetimeEnd']}'),
                      const SizedBox(height: 8),
                      Text(
                          'Latitude: ${_eventDetails['location']['latitude']}'),
                      const SizedBox(height: 8),
                      Text(
                          'Longitude: ${_eventDetails['location']['longitude']}'),
                      const SizedBox(height: 8),
                      Text(
                          'Instructions: ${_eventDetails['metadata']['instructions'] ?? 'None'}'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
