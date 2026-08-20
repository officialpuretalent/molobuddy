import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';

void main() {
  test('a session with no practices is not ready for practice work', () {
    const session = MoloSession(uid: 'user_1', practiceRefs: []);

    expect(session.hasPractices, isFalse);
  });

  test('a session exposes only active practices as selectable', () {
    const session = MoloSession(
      uid: 'user_1',
      practiceRefs: [
        PracticeRef(
          practiceId: 'p_1',
          displayLabel: 'Mokoena Media Tax',
          homeRegionKey: 'za1',
          routeVersion: 1,
          accessStatus: PracticeAccessStatus.active,
        ),
        PracticeRef(
          practiceId: 'p_2',
          displayLabel: 'Suspended Practice',
          homeRegionKey: 'za1',
          routeVersion: 1,
          accessStatus: PracticeAccessStatus.suspended,
        ),
      ],
    );

    expect(session.hasPractices, isTrue);
    expect(session.selectablePractices.map((p) => p.practiceId), ['p_1']);
  });
}
