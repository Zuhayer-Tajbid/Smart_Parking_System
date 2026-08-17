import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_parking_system/app.dart';
import 'package:smart_parking_system/config/supabase_config.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  Future<void> pumpToLogin(WidgetTester tester) async {
    await tester.pumpWidget(const SmartParkingApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('Splash screen shows title and routes to Login without session',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmartParkingApp());

    expect(find.text('Smart Parking'), findsOneWidget);
    expect(find.byIcon(Icons.local_parking), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Login form shows validation errors for empty fields',
      (WidgetTester tester) async {
    await pumpToLogin(tester);

    expect(find.text('Welcome Back'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
