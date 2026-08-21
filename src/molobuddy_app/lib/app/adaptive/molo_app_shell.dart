import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/adaptive/window_class.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';
import 'package:molobuddy_app/app/design_system/components/molo_navigation_item.dart';
import 'package:molobuddy_app/app/design_system/components/molo_search_field.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// Presentation data for one authenticated workspace destination.
///
/// A destination deliberately has no route or business capability attached to
/// it. The owner of the shell supplies navigation, which keeps route ownership
/// typed and feature-specific rather than turning the shell into a router.
@immutable
class MoloNavigationDestination {
  const MoloNavigationDestination({
    required this.id,
    required this.label,
    required this.glyph,
    this.section = MoloNavigationSection.primary,
    this.showInCompact = false,
    this.badgeLabel,
    this.enabled = true,
  });

  final String id;
  final String label;
  /// The design's line glyph. Stroked, so selection changes colour only and
  /// there is no filled counterpart to swap in.
  final MoloGlyph glyph;

  final MoloNavigationSection section;

  /// Compact navigation is intentionally limited to high-impact work.
  final bool showInCompact;

  /// A localised, human-readable count or status supplied by the feature.
  ///
  /// This is omitted until a repository-backed value exists; the shell never
  /// manufactures attention counts from presentation-only sample data.
  final String? badgeLabel;

  /// False where the destination belongs in the design but its screen is not
  /// built yet. It stays visible and stops pretending to work.
  final bool enabled;
}

enum MoloNavigationSection { primary, secondary }

/// The adaptive authenticated workspace frame.
///
/// It owns only responsive structure and navigation presentation. Features
/// retain their own scroll positions, data and action handling in [child].
class MoloAppShell extends StatelessWidget {
  const MoloAppShell({
    required this.title,
    required this.destinations,
    required this.selectedDestinationId,
    required this.child,
    required this.onDestinationSelected,
    required this.primaryActionLabel,
    required this.primaryActionTooltip,
    required this.brandSemanticLabel,
    required this.searchHint,
    required this.onPrimaryAction,
    this.accountMenuBuilder,
    this.topBarTrailingBuilder,
    this.scaffoldKey,
    super.key,
  });

  final String title;
  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final Widget child;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final String primaryActionLabel;
  final String primaryActionTooltip;

  /// Placeholder for the top bar's search field, supplied localised.
  final String searchHint;
  final String brandSemanticLabel;
  final VoidCallback? onPrimaryAction;
  final Widget Function(BuildContext context, MoloWindowClass windowClass)?
  accountMenuBuilder;
  final List<Widget> Function(
    BuildContext context,
    MoloWindowClass windowClass,
  )?
  topBarTrailingBuilder;
  final Key? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = moloWindowClassFor(constraints.maxWidth);
        return switch (windowClass) {
          MoloWindowClass.compact => _MoloCompactShell(
            searchHint: searchHint,
            scaffoldKey: scaffoldKey,
            title: title,
            destinations: destinations,
            selectedDestinationId: selectedDestinationId,
            onDestinationSelected: onDestinationSelected,
            primaryActionLabel: primaryActionLabel,
            primaryActionTooltip: primaryActionTooltip,
            onPrimaryAction: onPrimaryAction,
            accountMenu: accountMenuBuilder?.call(
              context,
              MoloWindowClass.compact,
            ),
            topBarTrailing:
                topBarTrailingBuilder?.call(context, MoloWindowClass.compact) ??
                const <Widget>[],
            child: child,
          ),
          _ => _MoloWideShell(
            searchHint: searchHint,
            scaffoldKey: scaffoldKey,
            windowClass: windowClass,
            title: title,
            destinations: destinations,
            selectedDestinationId: selectedDestinationId,
            onDestinationSelected: onDestinationSelected,
            primaryActionLabel: primaryActionLabel,
            primaryActionTooltip: primaryActionTooltip,
            brandSemanticLabel: brandSemanticLabel,
            onPrimaryAction: onPrimaryAction,
            accountMenu: accountMenuBuilder?.call(context, windowClass),
            topBarTrailing:
                topBarTrailingBuilder?.call(context, windowClass) ??
                const <Widget>[],
            child: child,
          ),
        };
      },
    );
  }
}

class _MoloCompactShell extends StatelessWidget {
  const _MoloCompactShell({
    required this.searchHint,
    required this.scaffoldKey,
    required this.title,
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.primaryActionLabel,
    required this.primaryActionTooltip,
    required this.onPrimaryAction,
    required this.accountMenu,
    required this.topBarTrailing,
    required this.child,
  });

  final String searchHint;

  /// Identifies the rendered workspace scaffold. It goes on the scaffold
  /// alone: putting it on this widget as well would place one key on two
  /// widgets, and every byKey lookup would find both.
  final Key? scaffoldKey;
  final String title;
  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final String primaryActionLabel;
  final String primaryActionTooltip;
  final VoidCallback? onPrimaryAction;
  final Widget? accountMenu;
  final List<Widget> topBarTrailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compactDestinations = destinations
        .where((destination) => destination.showInCompact)
        .toList(growable: false);
    assert(
      compactDestinations.length <= 4,
      'Compact navigation has room for four destinations plus one action.',
    );
    final selectedIndex = compactDestinations.indexWhere(
      (destination) => destination.id == selectedDestinationId,
    );
    final navigationDestinations = <NavigationDestination>[];
    for (var index = 0; index < compactDestinations.length; index++) {
      if (index == 2) {
        navigationDestinations.add(
          NavigationDestination(
            icon: const Icon(Icons.add_rounded),
            selectedIcon: const Icon(Icons.add_rounded),
            label: primaryActionLabel,
          ),
        );
      }
      final destination = compactDestinations[index];
      navigationDestinations.add(
        NavigationDestination(
          // Stroked glyph in both states: the design has no filled variant.
          icon: MoloIcon(
            destination.glyph,
            size: MoloNavigationItem.labelledIconSize,
            color: MoloNavigationItem.idleForeground,
          ),
          selectedIcon: MoloIcon(
            destination.glyph,
            size: MoloNavigationItem.labelledIconSize,
            color: MoloColours.surface,
          ),
          label: destination.label,
        ),
      );
    }

    // A compact shell always has Home, Work, Documents and Ask Molo. Keeping
    // the fallback makes the widget robust while a route set is still being
    // assembled, without selecting a navigation item that does not exist.
    final effectiveIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final navigationIndex = effectiveIndex >= 2
        ? effectiveIndex + 1
        : effectiveIndex;
    return Scaffold(
      key: scaffoldKey,
      appBar: MoloTopBar(
        compact: true,
        title: title,
        searchHint: searchHint,
        trailing: [
          ...topBarTrailing,
          if (accountMenu case final Widget menu) menu,
          const SizedBox(width: MoloSpacing.xs),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            onPrimaryAction?.call();
            return;
          }
          final destinationIndex = index > 2 ? index - 1 : index;
          if (destinationIndex < compactDestinations.length) {
            onDestinationSelected(compactDestinations[destinationIndex]);
          }
        },
        destinations: navigationDestinations,
      ),
    );
  }
}

class _MoloWideShell extends StatelessWidget {
  const _MoloWideShell({
    required this.searchHint,
    required this.scaffoldKey,
    required this.windowClass,
    required this.title,
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.primaryActionLabel,
    required this.primaryActionTooltip,
    required this.brandSemanticLabel,
    required this.onPrimaryAction,
    required this.accountMenu,
    required this.topBarTrailing,
    required this.child,
  });

  final MoloWindowClass windowClass;
  final String title;
  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final String primaryActionLabel;
  final String primaryActionTooltip;
  final String brandSemanticLabel;
  final String searchHint;

  /// Identifies the rendered workspace scaffold. It goes on the scaffold
  /// alone: putting it on this widget as well would place one key on two
  /// widgets, and every byKey lookup would find both.
  final Key? scaffoldKey;
  final VoidCallback? onPrimaryAction;
  final Widget? accountMenu;
  final List<Widget> topBarTrailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final labelled =
        windowClass == MoloWindowClass.large ||
        windowClass == MoloWindowClass.extraLarge;
    final navigation = labelled
        ? MoloSidebar(
            destinations: destinations,
            selectedDestinationId: selectedDestinationId,
            onDestinationSelected: onDestinationSelected,
            primaryActionLabel: primaryActionLabel,
            primaryActionTooltip: primaryActionTooltip,
            onPrimaryAction: onPrimaryAction,
            accountMenu: accountMenu,
          )
        : MoloNavigationRail(
            destinations: destinations,
            selectedDestinationId: selectedDestinationId,
            onDestinationSelected: onDestinationSelected,
            primaryActionLabel: primaryActionLabel,
            primaryActionTooltip: primaryActionTooltip,
            onPrimaryAction: onPrimaryAction,
            accountMenu: accountMenu,
          );
    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Row(
          children: [
            navigation,
            Expanded(
              // The design's header is sticky inside the scroll container, so
              // content passes beneath a translucent bar. Stacking the bar over
              // a full-height body reproduces that; the body is told how much
              // of its top the bar covers so its first item clears it.
              child: Stack(
                children: [
                  Positioned.fill(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        padding: MediaQuery.paddingOf(
                          context,
                        ).copyWith(top: MoloTopBar.height),
                      ),
                      child: child,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: MoloTopBar(
                      title: title,
                      searchHint: searchHint,
                      trailing: topBarTrailing,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 140 percent saturation matrix, matching the design's `saturate(140%)`.
///
/// Built from the standard luminance weights: each channel keeps its own value
/// amplified and subtracts the others in proportion, so greys stay grey and
/// colour is pushed outward.
const _saturate140 = <double>[
  1.3148, -0.2860, -0.0288, 0, 0, //
  -0.0852, 1.1140, -0.0288, 0, 0, //
  -0.0852, -0.2860, 1.3712, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// The contextual application header used by authenticated workspace views.
///
/// Measured from the design baseline: a 65 tall translucent bar over the warm
/// canvas, blurred, with a hairline rule and a fixed-width search field.
class MoloTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MoloTopBar({
    required this.title,
    required this.searchHint,
    this.compact = false,
    this.searchController,
    this.onSearchChanged,
    this.trailing = const <Widget>[],
    super.key,
  });

  /// 12 of padding above and below a 40 tall control, plus the hairline rule.
  static const height = 65.0;

  /// The warm canvas at 72 percent, which the blur behind it resolves against.
  static const background = Color(0xB8FFF9F7);

  /// The hairline rule: the border tint at 70 percent.
  static const ruleColour = Color(0xB3E4D5D8);

  final String title;
  final String searchHint;
  final bool compact;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> trailing;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        // The design is `saturate(140%) blur(14px)`. The saturation is not
        // decoration: without it, plum and pulse content passing under the bar
        // desaturates to grey instead of staying warm.
        filter: ImageFilter.compose(
          outer: const ColorFilter.matrix(_saturate140),
          inner: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: background,
            border: Border(bottom: BorderSide(color: ruleColour)),
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                // 40 on desktop, 20 when compact.
                compact ? 20 : 40,
                12,
                compact ? 20 : 40,
                // 12, plus the pixel the hairline rule occupies. CSS puts a
                // border inside the box it measures, so the design's content
                // box is 40 tall, not 41, and its search field starts exactly
                // 12 down. A Flutter border paints over the box instead of
                // reserving room in it, so the room is reserved here.
                13,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (compact) ...[
                          const MoloWordmark(compact: true),
                          const SizedBox(width: 14),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              height: MoloTypography.normalLineHeight,
                              color: MoloColours.moloPlum,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The design's right group is the search field alone, at
                  // gap 12, ending flush against the header inset. Anything
                  // the app adds is a status, so it goes ahead of the field
                  // rather than displacing it from the edge.
                  const SizedBox(width: MoloSpacing.md),
                  for (final item in trailing) ...[
                    item,
                    const SizedBox(width: 12),
                  ],
                  if (!compact)
                    MoloSearchField(
                      hint: searchHint,
                      controller: searchController,
                      onChanged: onSearchChanged,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled persistent navigation for large workspace layouts.
class MoloSidebar extends StatelessWidget {
  const MoloSidebar({
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.primaryActionLabel,
    required this.primaryActionTooltip,
    required this.onPrimaryAction,
    this.accountMenu,
    super.key,
  });

  /// Frame width with labels showing.
  static const width = 240.0;

  /// Horizontal inset of the rows inside the frame.
  static const horizontalPadding = 12.0;

  /// Section rule: white at fourteen percent over plum.
  static const dividerColour = Color(0x24FFFFFF);

  /// The brand mark, so tests and the rail can find the same lockup.
  static const brandMarkKey = Key('molo_sidebar_brand_mark');

  /// The create action, which the rail renders without its label.
  static const primaryActionKey = Key('molo_sidebar_primary_action');

  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final String primaryActionLabel;
  final String primaryActionTooltip;
  final VoidCallback? onPrimaryAction;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    return _MoloNavigationFrame(
      width: width,
      horizontalPadding: horizontalPadding,
      labelled: true,
      destinations: destinations,
      selectedDestinationId: selectedDestinationId,
      onDestinationSelected: onDestinationSelected,
      primaryActionLabel: primaryActionLabel,
      primaryActionTooltip: primaryActionTooltip,
      onPrimaryAction: onPrimaryAction,
      accountMenu: accountMenu,
    );
  }
}

/// The plum navigation frame shared by the labelled sidebar and the icon rail.
///
/// Both are the same design at two widths, so they are one widget with a
/// [labelled] flag rather than two that drift apart.
class _MoloNavigationFrame extends StatelessWidget {
  const _MoloNavigationFrame({
    required this.width,
    required this.horizontalPadding,
    required this.labelled,
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.primaryActionLabel,
    required this.primaryActionTooltip,
    required this.onPrimaryAction,
    required this.accountMenu,
  });

  final double width;
  final double horizontalPadding;
  final bool labelled;
  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final String primaryActionLabel;
  final String primaryActionTooltip;
  final VoidCallback? onPrimaryAction;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // The design animates the frame between its two widths rather than
      // snapping, which is what makes a window resize read as one surface.
      duration: const Duration(milliseconds: 160),
      curve: Curves.ease,
      width: width,
      color: MoloColours.moloPlum,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 12),
        child: Column(
          children: [
            // The design stacks brand, destinations and the create action from
            // the top and lets the leftover height fall below them, which is
            // what rests the account row on the floor. Making the destination
            // list itself expand would bunch create against the account.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _MoloSidebarBrand(labelled: labelled),
                    _MoloNavigationList(
                      destinations: destinations,
                      selectedDestinationId: selectedDestinationId,
                      onDestinationSelected: onDestinationSelected,
                      labelled: labelled,
                    ),
                    _MoloPrimaryAction(
                      label: primaryActionLabel,
                      tooltip: primaryActionTooltip,
                      labelled: labelled,
                      onPressed: onPrimaryAction,
                    ),
                  ],
                ),
              ),
            ),
            ?accountMenu,
          ],
        ),
      ),
    );
  }
}

/// The mark, plus the wordmark where there is room for it.
class _MoloSidebarBrand extends StatelessWidget {
  const _MoloSidebarBrand({required this.labelled});

  final bool labelled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The design pads the lockup inside the frame and separates it from the
      // first row by 18.
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
      child: Row(
        mainAxisAlignment:
            labelled ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          MoloBrandLockup(
            onDark: true,
            labelled: labelled,
            markKey: MoloSidebar.brandMarkKey,
          ),
        ],
      ),
    );
  }
}

/// The white create action that closes the navigation groups.
class _MoloPrimaryAction extends StatelessWidget {
  const _MoloPrimaryAction({
    required this.label,
    required this.tooltip,
    required this.labelled,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final bool labelled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MoloSpacing.md),
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          key: MoloSidebar.primaryActionKey,
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: MoloColours.surface,
              foregroundColor: MoloColours.moloPlum,
              // The design uses 15 here, one more than the control radius.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.zero,
              // Built from the theme's button role rather than from a bare
              // TextStyle. A button style's text style replaces the role
              // outright instead of merging with it, so writing one from
              // scratch dropped the font family with it and the label came out
              // in the platform default instead of Geist, half again too wide.
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                MoloColours.pulseTint,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('+', style: TextStyle(fontSize: 18, height: 1)),
                if (labelled) ...[
                  const SizedBox(width: MoloSpacing.xs),
                  Text(label),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only navigation for medium and expanded workspace layouts.
class MoloNavigationRail extends StatelessWidget {
  const MoloNavigationRail({
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.primaryActionLabel,
    required this.primaryActionTooltip,
    required this.onPrimaryAction,
    this.accountMenu,
    super.key,
  });

  /// Frame width without labels.
  static const width = 76.0;

  /// The design tightens the inset by 2 when the labels go.
  static const horizontalPadding = 10.0;

  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final String primaryActionLabel;
  final String primaryActionTooltip;
  final VoidCallback? onPrimaryAction;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    return _MoloNavigationFrame(
      width: width,
      horizontalPadding: horizontalPadding,
      labelled: false,
      destinations: destinations,
      selectedDestinationId: selectedDestinationId,
      onDestinationSelected: onDestinationSelected,
      primaryActionLabel: primaryActionLabel,
      primaryActionTooltip: primaryActionTooltip,
      onPrimaryAction: onPrimaryAction,
      accountMenu: accountMenu,
    );
  }
}

class _MoloNavigationList extends StatelessWidget {
  const _MoloNavigationList({
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.labelled,
  });

  /// The design sets 4 between rows, tighter than any spacing token.
  static const _rowSpacing = 4.0;

  final List<MoloNavigationDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<MoloNavigationDestination> onDestinationSelected;
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final primary = destinations
        .where((d) => d.section == MoloNavigationSection.primary)
        .toList(growable: false);
    final secondary = destinations
        .where((d) => d.section == MoloNavigationSection.secondary)
        .toList(growable: false);

    return Column(
      children: [
        ..._rows(primary),
        if (secondary.isNotEmpty)
          const Padding(
            // 14 above and below, inset 10, as the design draws it.
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Divider(color: MoloSidebar.dividerColour, height: 1),
          ),
        ..._rows(secondary),
      ],
    );
  }

  List<Widget> _rows(List<MoloNavigationDestination> group) {
    final rows = <Widget>[];
    for (var i = 0; i < group.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: _rowSpacing));
      final destination = group[i];
      rows.add(
        MoloNavigationItem(
          glyph: destination.glyph,
          label: destination.label,
          selected: destination.id == selectedDestinationId,
          labelled: labelled,
          badgeLabel: destination.badgeLabel,
          enabled: destination.enabled,
          onTap: () => onDestinationSelected(destination),
        ),
      );
    }
    return rows;
  }
}
