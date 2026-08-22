import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The workspace search field that sits in the desktop top bar.
///
/// A fixed 260 by 40 in the design, so it holds its shape beside a title that
/// can be any length rather than competing with it for width.
class MoloSearchField extends StatelessWidget {
  const MoloSearchField({
    required this.hint,
    this.controller,
    this.onChanged,
    super.key,
  });

  static const width = 260.0;
  static const height = 40.0;

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: MoloColours.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoloColours.border),
        ),
        // The design pads 14 inside a 1 border, and CSS holds the border
        // outside the padding, so its content starts 15 in and runs 230 wide.
        // A Container adds the border's own dimensions to this padding; a
        // DecoratedBox would paint the border over the content instead of
        // making room for it, and the field would run 2 wide and 1 off.
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            MoloIcon(
              MoloGlyphs.search,
              size: 15,
              color: MoloColours.secondaryText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  height: MoloTypography.normalLineHeight,
                  color: MoloColours.moloPlum,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    // The design leaves the placeholder to the browser,
                    // which paints Chrome's default grey. That is a user
                    // agent default rather than a decision, so this uses the
                    // system's own muted text instead of copying it.
                    color: MoloColours.secondaryText,
                  ),
                  // The design draws the border on the container, so the
                  // field itself contributes none of its own chrome.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  // The theme's fields are 50 high and carry a 50 minimum to
                  // match. This one is 40, and that minimum stretches the
                  // decorator to fill it; InputDecorator then top-aligns its
                  // input in the spare room and the words ride above the
                  // magnifier beside them. Cleared so the decorator stays its
                  // own height and the Row centres it, the same reason this
                  // field already declines the theme's fill and borders.
                  constraints: const BoxConstraints(),
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
