import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page's own toolbar (no fixed toolbar host) when another route is pushed
/// on top of the page.
void main() {
  /// Whether the page's toolbar keeps its native view. Read from the widget,
  /// which off iOS draws a fallback, so this needs no platform view.
  bool showsNativeToolbar(WidgetTester tester) => tester
      .widget<IOS26NativeToolbar>(
        find.byType(IOS26NativeToolbar, skipOffstage: false),
      )
      .showNativeView;

  /// Pumps a page with its own toolbar and returns a context inside it.
  Future<BuildContext> pumpPage(WidgetTester tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const IOS26Scaffold(
              title: 'Devices',
              useFixedToolbar: false,
              // Off iOS the fallback toolbar would nest this Hero in another.
              useHeroBackButton: false,
              children: [SizedBox.expand()],
            );
          },
        ),
      ),
    );
    return pageContext;
  }

  testWidgets('keeps the native toolbar under a dialog', (tester) async {
    final context = await pumpPage(tester);
    expect(showsNativeToolbar(tester), isTrue);

    showDialog<void>(context: context, builder: (_) => const Text('dialog'));
    await tester.pump();
    // From the dialog's first frame, not only once it has settled: dropping
    // the view and creating it again is what made the toolbar blink.
    expect(showsNativeToolbar(tester), isTrue);

    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);
    expect(showsNativeToolbar(tester), isTrue);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(showsNativeToolbar(tester), isTrue);
  });

  testWidgets('keeps the native toolbar under a bottom sheet', (tester) async {
    final context = await pumpPage(tester);

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const Text('sheet'),
    );
    await tester.pumpAndSettle();

    expect(find.text('sheet'), findsOneWidget);
    expect(showsNativeToolbar(tester), isTrue);
  });

  testWidgets('drops the native toolbar once a page covers it', (
    tester,
  ) async {
    final context = await pumpPage(tester);

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Text('next page')),
    );
    await tester.pumpAndSettle();

    expect(find.text('next page'), findsOneWidget);
    expect(showsNativeToolbar(tester), isFalse);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(showsNativeToolbar(tester), isTrue);
  });
}
