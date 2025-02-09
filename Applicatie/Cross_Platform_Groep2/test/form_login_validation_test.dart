import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cross_platform_groep2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Stel een mock SharedPreferences waarde in
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Login test with valid credentials', (WidgetTester tester) async {
    // Start de app
    app.main();
    await tester.pumpAndSettle();

    // Vind de invoervelden en knop
    final Finder usernameField = find.byKey(const Key('username_field'));
    final Finder passwordField = find.byKey(const Key('password_field'));
    final Finder loginButton = find.byKey(const Key('login_button'));

    // Vul de testgegevens in
    await tester.enterText(usernameField, 'Renas');
    await tester.enterText(passwordField, 'Renas123');
    await tester.tap(loginButton);

    // Wacht tot de navigatie compleet is
    await tester.pumpAndSettle();

    // Controleer of de navigatie naar de HomePage succesvol was
    expect(find.textContaining('Welcome, Renas!'), findsOneWidget);
  });
}
