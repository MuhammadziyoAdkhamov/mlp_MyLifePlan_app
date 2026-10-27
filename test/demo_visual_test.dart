import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/demo/demo_app.dart';
import 'package:mylife_plan/demo/demo_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final file = File('C:/Windows/Fonts/segoeui.ttf');
    if (file.existsSync()) {
      final font = FontLoader('Segoe UI')
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await font.load();
    }
  });
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('render demo ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DemoStore(prefs);
      await store.init();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MplDemoApp(
            enableOnboarding: false,
            store: store,
            prefs: prefs,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final png = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      final output = File('build/mpl_preview/today-${size.width.toInt()}.png');
      output.parent.createSync(recursive: true);
      output.writeAsBytesSync(png!);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }
}
