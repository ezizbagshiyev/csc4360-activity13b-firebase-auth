import 'package:flutter_test/flutter_test.dart';
import 'package:incl13b/auth_service.dart';

void main() {
  test('email validation rejects malformed input and trims whitespace', () {
    for (final v in ['', 'missing-at', 'a@b', 'a b@example.com']) {
      expect(validateEmail(v), isNotNull);
    }
    expect(validateEmail(' learner@example.com '), isNull);
  });
  test('password enforces six-character baseline', () {
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
  });
  test('sign-in failures do not reveal account existence', () {
    expect(authMessage('user-not-found'), authMessage('wrong-password'));
    expect(authMessage('invalid-credential'), authMessage('wrong-password'));
    expect(authMessage('internal-secret'), isNot(contains('internal-secret')));
  });
}
