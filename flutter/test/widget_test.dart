import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovers_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LoversApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
