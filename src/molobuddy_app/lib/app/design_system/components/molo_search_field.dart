import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MoloColours.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoloColours.border),
        ),
        child: Padding(
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
                    letterSpacing: 0,
                    color: MoloColours.moloPlum,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 0,
                      color: MoloColours.secondaryText,
                    ),
                    // The design draws the border on the container, so the
                    // field itself contributes none of its own chrome.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
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
