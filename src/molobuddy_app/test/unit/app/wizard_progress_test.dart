import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';

void main() {
  WizardProgress at(int step) => WizardProgress(
    stepNumber: step,
    readinessPercent: 12,
    steps: const [
      WizardStepDescriptor(
        title: 'Your account',
        note: 'Name, email and a password',
      ),
      WizardStepDescriptor(
        title: 'Your practice',
        note: 'Practice, team size and region',
      ),
      WizardStepDescriptor(
        title: 'Your first win',
        note: 'What you want to fix first',
      ),
      WizardStepDescriptor(
        title: 'Your starting point',
        note: 'Real data or a sample',
      ),
    ],
  );

  test('a step before the current one is done', () {
    expect(at(3).stateOf(1), WizardStepState.done);
    expect(at(3).stateOf(2), WizardStepState.done);
  });

  test('the step on screen is current', () {
    expect(at(3).stateOf(3), WizardStepState.current);
  });

  test('a step after it is pending', () {
    expect(at(3).stateOf(4), WizardStepState.pending);
  });

  test('the first step has nothing behind it', () {
    expect(at(1).stateOf(1), WizardStepState.current);
    expect(at(1).stateOf(2), WizardStepState.pending);
  });

  test('the last step has nothing ahead of it', () {
    expect(at(4).stateOf(3), WizardStepState.done);
    expect(at(4).stateOf(4), WizardStepState.current);
  });

  test('the rail carries one descriptor per step', () {
    expect(at(1).steps, hasLength(WizardProgress.totalSteps));
  });

  group('rail width', () {
    test('is 38% of the window', () {
      expect(MoloAuthShellLayout.wizardRailWidth(1000), closeTo(380, 0.01));
    });

    test('stops growing at 460', () {
      expect(MoloAuthShellLayout.wizardRailWidth(1600), 460);
      expect(MoloAuthShellLayout.wizardRailWidth(2400), 460);
    });

    test('is narrower than the sign-in hero, as the baseline draws them', () {
      // Sign-in gets 44% and the rail 38%. Asserting it means a later change
      // that quietly unifies the two has to argue with a test.
      expect(
        MoloAuthShellLayout.wizardRailWidth(1200),
        lessThan(MoloAuthShellLayout.signInHeroWidth(1200)),
      );
    });
  });
}
