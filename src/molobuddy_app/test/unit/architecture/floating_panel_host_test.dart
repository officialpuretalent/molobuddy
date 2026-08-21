import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A panel that draws its own surface must not be hosted by a Material menu.
///
/// `MenuAnchor`, `PopupMenuButton`, `Dialog` and `Card` each wrap what they are
/// given in their own `Material` with a shape, an elevation and
/// `clipBehavior: Clip.hardEdge`, and a menu adds padding, a clipping scroll
/// view and a scrollbar that stays on while it is open. The account panel draws
/// its own fill, radius, border and shadow, and inside one of those hosts its
/// shadow was clipped to its own bounding box: it survived only where the 22
/// radius left the box, as a hard wedge in each rounded corner, and read as a
/// second rectangle sitting behind the panel.
///
/// `RawMenuAnchor` keeps dismissal, focus and the anchor rect and supplies no
/// surface of its own. See `docs/app_design/visual_design.md`.
void main() {
  final welcomeView = File(
    'lib/core/auth/ui/views/welcome/welcome_view.dart',
  );

  test('the account panel is hosted by RawMenuAnchor', () {
    expect(
      welcomeView.existsSync(),
      isTrue,
      reason: 'run this test from src/molobuddy_app',
    );
    final source = welcomeView.readAsStringSync();

    expect(
      source.contains('RawMenuAnchor('),
      isTrue,
      reason:
          'The account panel needs a host that draws nothing of its own. '
          'RawMenuAnchor.overlayBuilder is that host.',
    );

    for (final host in const ['MenuAnchor(', 'PopupMenuButton<', 'Card(']) {
      // Anchored so that MenuAnchor does not match inside RawMenuAnchor.
      final used = RegExp('(?<![A-Za-z])${RegExp.escape(host)}');
      expect(
        used.hasMatch(source),
        isFalse,
        reason:
            '$host wraps its child in a Material with a shape, an elevation and '
            'a hard-edge clip. The account panel supplies all three itself, and '
            'the clip crops its shadow to its own corners. Use RawMenuAnchor.',
      );
    }
  });

  test('the panel draws exactly one shadow, and the host draws none', () {
    final panel = File(
      'lib/app/design_system/components/molo_account_menu.dart',
    );
    expect(panel.existsSync(), isTrue);

    final source = panel.readAsStringSync();
    // One BoxShadow, declared once and named, so a second cannot creep in
    // beside it: two shadows on a floating panel is what makes one read as a
    // solid rectangle behind the other.
    expect(
      'BoxShadow('.allMatches(source).length,
      1,
      reason:
          'The panel should declare a single named shadow. A second shadow, or '
          'an elevation on the host as well, is what produced the artefact '
          'this component was reported for.',
    );
    expect(
      source.contains('elevation:'),
      isFalse,
      reason:
          'The panel paints its own shadow, so nothing inside it should ask '
          'Material for one as well.',
    );
  });
}
