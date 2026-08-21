/// Which time-of-day kicker sits above "Welcome back".
enum SignInGreeting { morning, afternoon, evening }

/// The baseline's rule: morning before noon, afternoon before five, evening
/// after.
///
/// A pure function of the hour rather than a read of the clock, so the rule is
/// testable and the view stays the only thing that knows what time it is. The
/// home screen's greeting is a fixed string today; making that follow the clock
/// too is that screen's own work.
SignInGreeting signInGreetingForHour(int hour) {
  if (hour < 12) {
    return SignInGreeting.morning;
  }
  if (hour < 17) {
    return SignInGreeting.afternoon;
  }
  return SignInGreeting.evening;
}
