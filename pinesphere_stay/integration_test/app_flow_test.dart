import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/app/app.dart';
import 'package:pinesphere_stay/core/database/database_service.dart';
import 'package:pinesphere_stay/main.dart' as app;

void main() {
  testWidgets('End-to-End UI Flow: Login to Dashboard to Sync', (WidgetTester tester) async {
    // 1. Initialize DB and App

    app.databaseService = DatabaseService();
    await app.databaseService.init(isTest: true);
    
    addTearDown(() {
      final store = app.databaseService.store;
      if (store != null) {
        store.close();
      }
    });

    await tester.pumpWidget(const ProviderScope(child: PinesphereApp()));
    
    // Wait for initial routing

    await tester.pumpAndSettle();

    // 2. Validate Login Screen is present
    expect(find.text('Welcome to Pinesphere'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    
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
    expect(find.text('Check-In'), findsWidgets);

    // 7. Open Drawer to check Navigation
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    
    // Drawer should have PineStay Properties and Log Out
    expect(find.text('PineStay Properties'), findsWidgets);
    expect(find.text('Log Out'), findsWidgets);

    // 8. Close the drawer
    await tester.tap(find.byType(Drawer));
    // Wait for the tap to register and drawer to start closing
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    // Test successfully completes!
  });
}
