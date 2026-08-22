import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// Whether choosing this card unchooses its siblings.
enum MoloChoiceKind { single, multiple }

/// One selectable option in the signup wizard: a glyph, a title, a line of
/// explanation, and a mark saying whether it is chosen.
///
/// The card is the whole control. There is no separate checkbox: the previous
/// version accepted a trailing widget so the goals step could hang a Material
/// `Checkbox` beside the card's own mark, which meant two controls painting one
/// state and two tap targets for one answer.
class MoloChoiceCard extends StatefulWidget {
  const MoloChoiceCard({
    required this.glyph,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.kind = MoloChoiceKind.single,
    super.key,
  });

  final MoloGlyph glyph;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final MoloChoiceKind kind;

  /// The selection mark, so a measurement can find it.
  static const markKey = Key('molo_choice_card_mark');

  @override
  State<MoloChoiceCard> createState() => _MoloChoiceCardState();
}

class _MoloChoiceCardState extends State<MoloChoiceCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final radius = BorderRadius.circular(MoloSpacing.choiceCardRadius);
    // Selection and focus share the strong edge; hover only firms the quiet
    // one. What tells a focused card from a chosen one is the mark, which is
    // where the state actually lives.
    final strongEdge = selected || _focused;
    return Semantics(
      container: true,
      checked: selected,
      inMutuallyExclusiveGroup: widget.kind == MoloChoiceKind.single,
      child: Material(
        color: selected ? MoloColours.pulseTint : MoloColours.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          // Focus and hover paint their own outlines below, so the default
          // fills would linger and read as a second chosen card.
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onFocusChange: (value) => setState(() => _focused = value),
          onHover: (value) => setState(() => _hovered = value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? MoloColours.pulseTint : MoloColours.surface,
              borderRadius: radius,
              border: Border.all(
                color: strongEdge
                    ? MoloColours.pulseText
                    : _hovered
                    ? MoloColours.controlBorder
                    : MoloColours.border,
                width: strongEdge ? 2 : 1,
              ),
            ),
            child: Padding(
              // The design pads 16 down the sides of the row and 18 across it,
              // and the two-pixel selected edge is drawn inside that, so the
              // contents never shift as a card is chosen.
              padding: EdgeInsets.symmetric(
                vertical: strongEdge ? 15 : 16,
                horizontal: strongEdge ? 17 : 18,
              ),
              child: Row(
                children: [
                  MoloIcon(
                    widget.glyph,
                    size: 19,
                    color: selected
                        ? MoloColours.pulseText
                        : MoloColours.controlBorder,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            height: MoloTypography.normalLineHeight,
                            color: MoloColours.moloPlum,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            letterSpacing: 0,
                            color: MoloColours.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _ChoiceMark(selected: selected, kind: widget.kind),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round for a choice that excludes its siblings, square for one that does not,
/// so the shape says how many answers are allowed before anything is chosen.
class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected, required this.kind});

  final bool selected;
  final MoloChoiceKind kind;

  @override
  Widget build(BuildContext context) {
    final single = kind == MoloChoiceKind.single;
    final fill = single ? MoloColours.pulseText : MoloColours.moloPlum;
    return Container(
      key: MoloChoiceCard.markKey,
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? fill : MoloColours.surface,
        shape: single ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: single ? null : BorderRadius.circular(7),
        // The unselected outline is controlBorder rather than the baseline's
        // #D8C6CB at 1.49:1: it is the only thing that says a control is there.
        border: selected ? null : Border.all(color: MoloColours.controlBorder),
      ),
      // The tick stays in the tree and fades, as the baseline does, so the mark
      // never reflows as it is chosen.
      child: Opacity(
        opacity: selected ? 1 : 0,
        child: MoloIcon(
          MoloGlyphs.tick,
          size: 11,
          color: MoloColours.warmCanvas,
        ),
      ),
    );
  }
}
