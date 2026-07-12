import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/app/app.dart';
import 'package:pinesphere_stay/core/database/objectbox.dart';
import 'package:pinesphere_stay/main.dart' as app;

void main() {
  testWidgets('End-to-End UI Flow: Login to Dashboard to Sync', (WidgetTester tester) async {
    // 1. Initialize DB and App
    app.objectBox = await ObjectBox.create();
    await tester.pumpWidget(const ProviderScope(child: PinesphereApp()));
    
    // Wait for initial routing
    await tester.pumpAndSettle();

    // 2. Validate Login Screen is present
    expect(find.text('Pinesphere Stay'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    
    // 3. Find and enter Email
    final emailField = find.byType(TextField).first;
    await tester.enterText(emailField, 'test@pinesphere.com');
    await tester.pumpAndSettle();
    
    // 4. Find and enter Password
    final passwordField = find.byType(TextField).last;
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();
    
    // 5. Tap Login Button
    final loginButton = find.text('Login');
    await tester.tap(loginButton);
    
    // Wait for authentication and navigation to Dashboard
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 6. Validate Dashboard Screen
    expect(find.text('PineStay'), findsOneWidget);
    
    // We expect some quick actions or greeting to be on the dashboard.
    expect(find.text('New Booking'), findsWidgets);
    expect(find.text('Check-in'), findsWidgets);

    // 7. Open Drawer to check Navigation
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    
    // Drawer should have Dashboard, Rooms, Guests, Sync
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Rooms'), findsWidgets);
    expect(find.text('Guests'), findsWidgets);

    // 8. Test Sync from Drawer
    await tester.tap(find.text('Offline Sync'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Wait to simulate sync complete UI
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // If it navigated to sync screen, verify sync screen is visible
    expect(find.text('Sync Engine'), findsWidgets);
  });
}
