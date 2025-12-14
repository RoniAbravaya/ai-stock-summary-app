// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_stock_summary/main.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  setUpAll(() {
    // google_fonts loads AssetManifest.json at runtime; in widget tests there is no
    // generated asset manifest unless we provide one.
    TestWidgetsFlutterBinding.ensureInitialized();

    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final String key = utf8.decode(message.buffer.asUint8List());

        if (key == 'AssetManifest.json' ||
            key == 'FontManifest.json' ||
            key == 'AssetManifest.bin') {
          final bytes = utf8.encode('{}');
          return ByteData.view(Uint8List.fromList(bytes).buffer);
        }

        return null; // Fall back to default behavior for other assets.
      },
    );
  });

  testWidgets('App builds MaterialApp shell', (tester) async {
    await tester.pumpWidget(const AIStockSummaryApp(firebaseEnabled: false));

    // The app should build a MaterialApp wrapper successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
