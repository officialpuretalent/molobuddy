import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

void main() {
  test('loading the session counts as busy, same as authenticating', () {
    const state = AuthViewState(
      status: AuthViewStatus.loadingSession,
      methods: [],
    );

    expect(state.isBusy, isTrue);
  });

  test('signed-in and signed-out are not busy', () {
    const signedIn = AuthViewState(
      status: AuthViewStatus.signedIn,
      methods: [],
    );
    const signedOut = AuthViewState.signedOut();

    expect(signedIn.isBusy, isFalse);
    expect(signedOut.isBusy, isFalse);
  });
}
