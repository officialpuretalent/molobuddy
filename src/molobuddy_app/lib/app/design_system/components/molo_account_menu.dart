import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// One row of the account menu.
///
/// A null [onTap] renders the row in the design's place, greyed and inert. The
/// sidebar already treats a destination whose screen is not built that way, and
/// the alternative is a row that looks live and does nothing when pressed.
@immutable
class MoloAccountMenuEntry {
  const MoloAccountMenuEntry({
    required this.glyph,
    required this.label,
    this.onTap,
    this.showChevron = false,
    this.destructive = false,
    this.key,
  });

  /// Identifies one row, so a caller can address it without matching on copy.
  final Key? key;

  final MoloGlyph glyph;
  final String label;
  final VoidCallback? onTap;

  /// Whether the row leads somewhere further, as Help and support does.
  final bool showChevron;

  /// Signing out, which the design draws in the pulse's darker text.
  final bool destructive;
}

/// The practice row that opens the account menu.
@immutable
class MoloAccountMenuHeader {
  const MoloAccountMenuHeader({
    required this.initials,
    required this.name,
    required this.caption,
    this.onTap,
  });

  final String initials;
  final String name;

  /// What this identity is, under its name: the design reads "Practice
  /// account" here, against the person's name on the sidebar row itself.
  final String caption;
  final VoidCallback? onTap;
}

/// The panel that opens from the sidebar's account row.
///
/// Measured from the design baseline: 268 wide, an 8 inset, a 22 radius and a
/// long soft shadow, with 2 between rows and a hairline between groups.
class MoloAccountMenu extends StatelessWidget {
  const MoloAccountMenu({
    required this.header,
    required this.sections,
    super.key,
  });

  static const width = 268.0;

  /// Panel corner radius, larger than the 14 the rows inside it use.
  static const radius = 22.0;

  /// Inset around the rows.
  static const padding = 8.0;

  /// The design's `0 18px 40px rgba(36,21,41,0.22)`.
  ///
  /// CSS states a blur *radius*, which is twice the Gaussian deviation, while
  /// Flutter converts a radius with `radius * 0.57735 + 0.5`. Passing 40
  /// straight through would blur half again as far as the design does, so the
  /// radius that lands on the same 20 deviation is used instead.
  static const shadow = BoxShadow(
    color: Color(0x38241529),
    blurRadius: 33.8,
    offset: Offset(0, 18),
  );

  final MoloAccountMenuHeader header;

  /// Row groups, drawn with a hairline between each.
  final List<List<MoloAccountMenuEntry>> sections;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _MoloAccountMenuHeaderRow(header: header),
      for (final section in sections) ...[
        const _MoloAccountMenuRule(),
        for (final entry in section)
          _MoloAccountMenuRow(key: entry.key, entry: entry),
      ],
    ];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: MoloColours.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: MoloColours.border),
          boxShadow: const [shadow],
        ),
        padding: const EdgeInsets.all(padding),
        child: ConstrainedBox(
          // The design caps the panel at the viewport less 120 and scrolls.
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(context).height - 120).clamp(
              120.0,
              double.infinity,
            ),
          ),
          child: SingleChildScrollView(
            // Not the primary controller: a menu supplies its own scrollable
            // around whatever it is given, and two of them claiming the
            // primary controller trips the scrollbar's single-position check.
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  // The design's flex gap applies between every child, so a
                  // rule carries 2 either side of its own 6 of margin.
                  if (i > 0) const SizedBox(height: _rowGap),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The design sets 2 between rows.
  static const _rowGap = 2.0;
}

/// The hairline between row groups.
class _MoloAccountMenuRule extends StatelessWidget {
  const _MoloAccountMenuRule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      // 6 above and below, inset 10, as the design draws it.
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ColoredBox(color: MoloColours.border, child: SizedBox(height: 1)),
    );
  }
}

class _MoloAccountMenuHeaderRow extends StatelessWidget {
  const _MoloAccountMenuHeaderRow({required this.header});

  static const avatarSize = 34.0;

  final MoloAccountMenuHeader header;

  @override
  Widget build(BuildContext context) {
    return _MoloAccountMenuSurface(
      onTap: header.onTap,
      // The header sits a pixel taller than the rows beneath it.
      verticalPadding: 12,
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MoloColours.pulseTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              header.initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: MoloColours.pulseText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  header.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    color: MoloColours.moloPlum,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  header.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    color: MoloColours.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const _MoloAccountMenuChevron(),
        ],
      ),
    );
  }
}

class _MoloAccountMenuRow extends StatelessWidget {
  const _MoloAccountMenuRow({required this.entry, super.key});

  static const glyphSize = 17.0;

  final MoloAccountMenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final enabled = entry.onTap != null;
    final foreground = entry.destructive
        ? MoloColours.pulseText
        : MoloColours.moloPlum;
    final effective = enabled ? foreground : foreground.withValues(alpha: 0.38);
    // The design strokes every glyph here in the muted text, except signing
    // out, which takes the row's own colour.
    final glyphColour = entry.destructive
        ? effective
        : (enabled
              ? MoloColours.secondaryText
              : MoloColours.secondaryText.withValues(alpha: 0.38));

    return _MoloAccountMenuSurface(
      onTap: entry.onTap,
      verticalPadding: 11,
      hover: entry.destructive ? MoloColours.errorTint : MoloColours.warmCanvas,
      child: Row(
        children: [
          MoloIcon(entry.glyph, size: glyphSize, color: glyphColour),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: effective,
              ),
            ),
          ),
          if (entry.showChevron) const _MoloAccountMenuChevron(),
        ],
      ),
    );
  }
}

/// The tappable, hoverable body shared by every row in the panel.
class _MoloAccountMenuSurface extends StatelessWidget {
  const _MoloAccountMenuSurface({
    required this.onTap,
    required this.verticalPadding,
    required this.child,
    this.hover = MoloColours.warmCanvas,
  });

  final VoidCallback? onTap;
  final double verticalPadding;
  final Color hover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        // The design states a hover fill per row and no ripple; Material's
        // default here is a wash of onSurface that does not match either.
        overlayColor: WidgetStateMapper<Color?>({
          WidgetState.hovered: hover,
          WidgetState.pressed: hover,
          WidgetState.any: null,
        }),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 10,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The small chevron that marks a row leading somewhere further.
///
/// The design types this as U+203A at 13, whose ink measures 3.16 by 5.2. It is
/// painted for the same reason as the account row's caret: the character comes
/// from font fallback, so its shape and weight would vary by platform.
class _MoloAccountMenuChevron extends StatelessWidget {
  const _MoloAccountMenuChevron();

  static const size = Size(3.16, 5.2);

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.only(left: 8),
        child: CustomPaint(size: size, painter: _ChevronPainter()),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height),
      Paint()
        ..color = MoloColours.secondaryText
        ..style = PaintingStyle.stroke
        // Matched to the weight of the glyph the design types here, which is
        // filled rather than stroked and has no stroke width to copy.
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => false;
}
