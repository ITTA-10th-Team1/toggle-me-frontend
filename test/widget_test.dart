import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/app/app.dart';

void main() {
  testWidgets('Toggle me app launches', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());

    expect(find.text('Toggle me'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
