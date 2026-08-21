import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_field_label.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// A field with its label above it, as the design draws every field.
///
/// Material floats a label into the outline; the design keeps it on its own
/// line, in a row that can also carry an action such as "Forgot password?".
/// The visible label is excluded from semantics and re-stated on the field, so
/// a screen reader hears the name once and hears it attached to the control.
class MoloTextField extends StatelessWidget {
  const MoloTextField({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.trailing,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.autocorrect = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Placed on the [TextField] itself, so a caller's existing key keeps
  /// pointing at the control rather than at this wrapper.
  final Key? fieldKey;

  /// An action at the right of the label row. Outside the field's semantics,
  /// because it is a separate control.
  final Widget? trailing;

  final String? hintText;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final Widget? suffix;
  final List<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  /// Reported on every keystroke, for a caller that shows what is being typed
  /// somewhere else on the screen.
  final ValueChanged<String>? onChanged;

  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoloFieldLabel(label: label, trailing: trailing),
        const SizedBox(height: MoloFieldLabel.gap),
        Semantics(
          container: true,
          label: label,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscureText,
            autocorrect: autocorrect,
            autofillHints: autofillHints,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              letterSpacing: 0,
              height: MoloTypography.normalLineHeight,
              color: MoloColours.moloPlum,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              errorText: errorText,
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
