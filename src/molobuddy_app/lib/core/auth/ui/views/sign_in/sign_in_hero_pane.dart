import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';

/// The photographic pane beside the sign-in form.
///
/// The plum panel with two orbs and three story points is retired: the design
/// puts a photograph here, under a scrim whose bottom stop is what keeps the
/// promise readable rather than merely dark.
class SignInHeroPane extends StatelessWidget {
  const SignInHeroPane({super.key});

  /// Kept from the retired panel, so tests and the shell's measurements go on
  /// pointing at the same pane.
  static const paneKey = Key('auth_hero_panel');

  /// The design's text column is `30ch`, which CSS resolves against the
  /// inherited 16px root. Geist's zero advance measures 0.663em, so
  /// 30 x 16 x 0.663 lands on 318.
  static const _textColumnWidth = 318.0;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return DecoratedBox(
      key: paneKey,
      decoration: const BoxDecoration(
        color: MoloColours.moloPlum,
        image: DecorationImage(
          image: AssetImage('assets/brand/signin-portrait.webp'),
          fit: BoxFit.cover,
          // The design's `background-position: 62% 50%`.
          alignment: Alignment(0.24, 0),
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.42, 1],
            // moloPlum at 0.72, 0.28 and 0.86. Written as ARGB because a const
            // gradient cannot call withValues.
            colors: [Color(0xB8241529), Color(0x47241529), Color(0xDB241529)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MoloBrandLockup(onDark: true),
              Flexible(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _textColumnWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localisations.brandPromise,
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.2,
                            letterSpacing: MoloTypography.display(30),
                            color: MoloColours.warmCanvas,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localisations.signInHeroBody,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            letterSpacing: 0,
                            color: MoloColours.warmCanvas.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
