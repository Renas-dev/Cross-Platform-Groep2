import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/pages/homepage.dart';

void main() {
  setUp(() {
    // Mock SharedPreferences values
    SharedPreferences.setMockInitialValues({'username': 'TestUser'});
  });

  testWidgets('Should display username on HomePage', (WidgetTester tester) async {
    // Build the HomePage widget
    await tester.pumpWidget(MaterialApp(home: HomePage(token: 'mockToken')));

    // Wait for the widget to build and the async logic to complete
    await tester.pumpAndSettle();

    // Add debug output
    debugPrint('Looking for text: Welcome, TestUser!');

    // Verify the "Welcome, TestUser!" text is displayed
    expect(find.text('Welcome, TestUser!'), findsOneWidget);

    // Verify the "Manage your teams" button exists
    expect(find.text('Manage your teams'), findsOneWidget);
  });
}
