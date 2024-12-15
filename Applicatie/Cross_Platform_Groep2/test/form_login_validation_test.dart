import 'package:flutter_test/flutter_test.dart';

bool validateLogin(String username, String password) {
  if (username.isEmpty || password.isEmpty) {
    return false;
  }
  return true;
}

void main() {
  group('Login Validation Tests', () {
    test('Should return false if username is empty', () {
      expect(validateLogin('', 'password'), false);
    });

    test('Should return false if password is empty', () {
      expect(validateLogin('username', ''), false);
    });

    test('Should return true if both fields are filled', () {
      expect(validateLogin('username', 'password'), true);
    });
  });
}
