import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cross_platform_groep2/main.dart' as app;

Future<void> addDelay([int milliseconds = 3000]) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login test with valid credentials', (WidgetTester tester) async {
    // Start de app
    app.main();
    await tester.pumpAndSettle();

    // Add delay for app initialization
    await addDelay();

    // Vind de invoervelden en knop
    final Finder usernameField = find.byKey(const Key('username_field'));
    final Finder passwordField = find.byKey(const Key('password_field'));
    final Finder loginButton = find.byKey(const Key('login_button'));

    // Vul de testgegevens in
    await tester.enterText(usernameField, 'Renas');
    await addDelay();
    await tester.enterText(passwordField, 'Renas123');
    await addDelay();
    await tester.tap(loginButton);
    await addDelay();

    // Wacht tot de navigatie compleet is
    await tester.pumpAndSettle();
    await addDelay();
    // Controleer of de navigatie naar de HomePage succesvol was
    expect(find.text('Welcome, Renas!'), findsOneWidget);
    await addDelay();
  });
}
