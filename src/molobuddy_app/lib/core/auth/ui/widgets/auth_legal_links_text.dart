import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';

class AuthLegalLinksText extends StatefulWidget {
  const AuthLegalLinksText({
    required this.label,
    required this.termsLabel,
    required this.privacyLabel,
    required this.onTermsPressed,
    required this.onPrivacyPressed,
    this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String label;
  final String termsLabel;
  final String privacyLabel;
  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPressed;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<AuthLegalLinksText> createState() => _AuthLegalLinksTextState();
}

class _AuthLegalLinksTextState extends State<AuthLegalLinksText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsPressed;
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = widget.onPrivacyPressed;
  }

  @override
  void didUpdateWidget(covariant AuthLegalLinksText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.onTermsPressed;
    _privacyRecognizer.onTap = widget.onPrivacyPressed;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = defaultStyle.copyWith(
      color: MoloColours.pulseText,
      decoration: TextDecoration.underline,
      decorationColor: MoloColours.pulseText,
      decorationThickness: 1.25,
    );
    return Text.rich(
      TextSpan(style: defaultStyle, children: _spans(linkStyle)),
      textAlign: widget.textAlign,
    );
  }

  List<InlineSpan> _spans(TextStyle linkStyle) {
    final termsStart = widget.label.indexOf(widget.termsLabel);
    final privacyStart = widget.label.indexOf(widget.privacyLabel);
    if (termsStart < 0 || privacyStart < termsStart) {
      return [TextSpan(text: widget.label)];
    }

    final termsEnd = termsStart + widget.termsLabel.length;
    final privacyEnd = privacyStart + widget.privacyLabel.length;
    return [
      TextSpan(text: widget.label.substring(0, termsStart)),
      TextSpan(
        text: widget.termsLabel,
        style: linkStyle,
        recognizer: _termsRecognizer,
        mouseCursor: SystemMouseCursors.click,
      ),
      TextSpan(text: widget.label.substring(termsEnd, privacyStart)),
      TextSpan(
        text: widget.privacyLabel,
        style: linkStyle,
        recognizer: _privacyRecognizer,
        mouseCursor: SystemMouseCursors.click,
      ),
      TextSpan(text: widget.label.substring(privacyEnd)),
    ];
  }
}

Future<void> showAuthLegalPreviewDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String closeLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}
