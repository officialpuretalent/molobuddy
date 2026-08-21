import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_greeting.dart';

void main() {
  test('morning runs to noon', () {
    expect(signInGreetingForHour(0), SignInGreeting.morning);
    expect(signInGreetingForHour(11), SignInGreeting.morning);
  });

  test('afternoon runs from noon to five', () {
    expect(signInGreetingForHour(12), SignInGreeting.afternoon);
    expect(signInGreetingForHour(16), SignInGreeting.afternoon);
  });

  test('evening runs from five', () {
    expect(signInGreetingForHour(17), SignInGreeting.evening);
    expect(signInGreetingForHour(23), SignInGreeting.evening);
  });
}
