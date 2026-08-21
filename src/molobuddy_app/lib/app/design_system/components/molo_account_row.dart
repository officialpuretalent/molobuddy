import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';

/// The practice and person identity row that closes the workspace sidebar.
///
/// Presentational: the caller wraps it in whatever opens the account menu, so
/// this widget carries no sign-out or navigation of its own.
class MoloAccountRow extends StatelessWidget {
  const MoloAccountRow({
    required this.initials,
    required this.name,
    this.detail,
    this.labelled = true,
    this.showCaret = true,
    super.key,
  });

  /// The initials tile, so tests and the rail can find the same element.
  static const avatarKey = Key('molo_account_row_avatar');

  /// The second line's colour: the warm white at 66 percent.
  static const detailForeground = Color(0xA8FFF9F7);

  final String initials;
  final String name;

  /// The signed-in person, under the practice name. Absent on the rail, where
  /// there is only room for the initials tile.
  final String? detail;

  /// Whether the text and caret show. False on the icon rail.
  final bool labelled;

  final bool showCaret;

  @override
  Widget build(BuildContext context) {
    final detailLine = detail;
    return Padding(
      // 12 on every side, inside a 15 radius, as the design draws it.
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment:
            labelled ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            key: avatarKey,
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MoloColours.softBlush,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                color: MoloColours.moloPlum,
              ),
            ),
          ),
          if (labelled) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      color: MoloColours.surface,
                    ),
                  ),
                  if (detailLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detailLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 0,
                        color: detailForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showCaret)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: detailForeground,
              ),
          ],
        ],
      ),
    );
  }
}
