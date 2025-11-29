import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supercart_pos/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build MyApp
    await tester.pumpWidget(const MyApp());

    // Pastikan MyApp berhasil dimuat
    expect(find.byType(MyApp), findsOneWidget);

    // Tunggu rendering widget awal (misalnya LoginScreen)
    await tester.pumpAndSettle();

    // Cek apakah ada widget yang tampil di layar
    expect(find.byType(Scaffold), findsWidgets);
  });
}
