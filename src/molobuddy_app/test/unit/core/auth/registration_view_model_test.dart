import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/registration_view_model.dart';

void main() {
  test(
    'registration validates each stage and completes without credentials',
    () {
      final container = ProviderContainer.test();
      final subscription = container.listen(
        registrationViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final viewModel = container.read(registrationViewModelProvider.notifier);

      expect(
        viewModel.continueFromAccount(
          displayName: '',
          email: 'not-an-email',
          password: 'short',
          acceptedTerms: false,
        ),
        isFalse,
      );
      expect(container.read(registrationViewModelProvider).nameInvalid, isTrue);
      expect(
        container.read(registrationViewModelProvider).termsNotAccepted,
        isTrue,
      );

      expect(
        viewModel.continueFromAccount(
          displayName: 'Naledi Mokoena',
          email: 'naledi@example.com',
          password: 'safe-preview-password',
          acceptedTerms: true,
        ),
        isTrue,
      );
      expect(
        container.read(registrationViewModelProvider).step,
        RegistrationStep.practice,
      );

      expect(viewModel.continueFromPractice(practiceName: 'Molo Tax'), isTrue);
      expect(viewModel.continueFromPriorities(), isFalse);
      expect(
        container.read(registrationViewModelProvider).prioritiesInvalid,
        isTrue,
      );

      viewModel.togglePriority(RegistrationPriority.deadlines);
      expect(viewModel.continueFromPriorities(), isTrue);
      expect(
        container.read(registrationViewModelProvider).step,
        RegistrationStep.startingPoint,
      );
      expect(viewModel.completePreview(), isFalse);
      viewModel.selectStartingPoint(WorkspaceStartingPoint.sampleWorkspace);
      expect(viewModel.completePreview(), isTrue);
      expect(
        container.read(registrationViewModelProvider).step,
        RegistrationStep.complete,
      );
      expect(
        container.read(registrationViewModelProvider).email,
        'naledi@example.com',
      );
    },
  );
}
