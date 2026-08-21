import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_app_shell.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

final _destinations = <MoloNavigationDestination>[
  MoloNavigationDestination(
    id: 'home',
    label: 'Home',
    glyph: MoloGlyphs.home,
    showInCompact: true,
  ),
  MoloNavigationDestination(
    id: 'work',
    label: 'Work',
    glyph: MoloGlyphs.work,
    showInCompact: true,
  ),
  MoloNavigationDestination(
    id: 'documents',
    label: 'Documents',
    glyph: MoloGlyphs.documents,
    showInCompact: true,
  ),
  MoloNavigationDestination(
    id: 'ask-molo',
    label: 'Ask Molo',
    glyph: MoloGlyphs.askMolo,
    section: MoloNavigationSection.secondary,
    showInCompact: true,
  ),
];

void main() {
  testWidgets('keeps compact navigation to high-impact destinations', (
    tester,
  ) async {
    String? selected;
    var createPressed = 0;

    await _pumpShell(
      tester,
      size: const Size(390, 900),
      onDestinationSelected: (destination) => selected = destination.id,
      onPrimaryAction: () => createPressed++,
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    final navigation = find.byType(NavigationBar);
    expect(
      find.descendant(of: navigation, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Work')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Create work')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Documents')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Ask Molo')),
      findsOneWidget,
    );
    expect(find.byType(MoloSidebar), findsNothing);

    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Create work')),
    );
    await tester.pump();
    expect(createPressed, 1);

    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Work')),
    );
    await tester.pump();
    expect(selected, 'work');
  });

  testWidgets('uses an icon rail at medium width', (tester) async {
    await _pumpShell(tester, size: const Size(700, 900));

    expect(find.byType(MoloNavigationRail), findsOneWidget);
    expect(find.byType(MoloSidebar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('keeps the rail at expanded width', (tester) async {
    await _pumpShell(tester, size: const Size(1000, 900));

    expect(find.byType(MoloNavigationRail), findsOneWidget);
    expect(find.byType(MoloSidebar), findsNothing);
  });

  testWidgets('uses the labelled sidebar at large width', (tester) async {
    await _pumpShell(tester, size: const Size(1280, 900));

    expect(find.byType(MoloSidebar), findsOneWidget);
    expect(find.byType(MoloNavigationRail), findsNothing);
    expect(find.text('Workspace content'), findsOneWidget);
  });

  testWidgets('keeps the labelled sidebar at extra-large width', (
    tester,
  ) async {
    await _pumpShell(tester, size: const Size(1800, 900));

    expect(find.byType(MoloSidebar), findsOneWidget);
    expect(find.byType(MoloNavigationRail), findsNothing);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  ValueChanged<MoloNavigationDestination>? onDestinationSelected,
  VoidCallback? onPrimaryAction,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: MoloTheme.light(),
      home: MoloAppShell(
        title: 'Home',
        destinations: _destinations,
        selectedDestinationId: 'home',
        primaryActionLabel: 'Create work',
        primaryActionTooltip: 'Create work',
        brandSemanticLabel: 'Molo',
      searchHint: 'Search',
        onDestinationSelected: onDestinationSelected ?? (_) {},
        onPrimaryAction: onPrimaryAction,
        child: const Center(child: Text('Workspace content')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
