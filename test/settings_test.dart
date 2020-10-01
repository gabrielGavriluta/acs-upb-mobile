import 'package:acs_upb_mobile/authentication/model/user.dart';
import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/main.dart';
import 'package:acs_upb_mobile/pages/portal/service/website_provider.dart';
import 'package:acs_upb_mobile/pages/settings/service/request_provider.dart';
import 'package:acs_upb_mobile/pages/settings/view/ask_permissions.dart';
import 'package:acs_upb_mobile/pages/settings/view/settings_page.dart';
import 'package:acs_upb_mobile/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockWebsiteProvider extends Mock implements WebsiteProvider {}

class MockRequestProvider extends Mock implements RequestProvider {}

void main() {
  AuthProvider mockAuthProvider;
  WebsiteProvider mockWebsiteProvider;
  RequestProvider mockRequestProvider;

  group('Settings', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      PrefService.enableCaching();
      PrefService.cache = {};
      // Assuming mock system language is English
      SharedPreferences.setMockInitialValues({'language': 'auto'});

      // Pretend an anonymous user is already logged in
      mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isAuthenticatedFromCache).thenReturn(true);
      // ignore: invalid_use_of_protected_member
      when(mockAuthProvider.hasListeners).thenReturn(false);
      when(mockAuthProvider.isAuthenticatedFromService)
          .thenAnswer((realInvocation) => Future.value(true));
      when(mockAuthProvider.currentUser).thenAnswer((_) => Future.value(null));
      when(mockAuthProvider.isAnonymous).thenReturn(true);

      mockWebsiteProvider = MockWebsiteProvider();
      // ignore: invalid_use_of_protected_member
      when(mockWebsiteProvider.hasListeners).thenReturn(false);
      when(mockWebsiteProvider.deleteWebsite(any, context: anyNamed('context')))
          .thenAnswer((realInvocation) => Future.value(true));
      when(mockWebsiteProvider.fetchWebsites(any))
          .thenAnswer((_) => Future.value([]));

      mockRequestProvider = MockRequestProvider();
      when(mockRequestProvider.makeRequest(any, context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));
      when(mockRequestProvider.userAlreadyRequested(any,
              context: anyNamed('context')))
          .thenAnswer((_) => Future.value(false));
    });

    testWidgets('Dark Mode', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider)
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      MaterialApp app = find.byType(MaterialApp).evaluate().first.widget;
      expect(app.theme.brightness, equals(Brightness.light));

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Toggle dark mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      app = find.byType(MaterialApp).evaluate().first.widget;
      expect(app.theme.brightness, equals(Brightness.dark));

      // Toggle dark mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      app = find.byType(MaterialApp).evaluate().first.widget;
      expect(app.theme.brightness, equals(Brightness.light));
    });

    testWidgets('Language', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider)
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Auto'), findsOneWidget);

      // Romanian
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Romanian'));
      await tester.pumpAndSettle();

      expect(find.text('Setări'), findsOneWidget);
      expect(find.text('Română'), findsOneWidget);

      // English
      await tester.tap(find.text('Limbă'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engleză'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Back to Auto (English)
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('Ask Permissions - normal scenario',
        (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((_) =>
          Future.value(User(uid: '0', firstName: 'John', lastName: 'Doe')));
      when(mockAuthProvider.isVerifiedFromCache).thenAnswer((_) => true);
      when(mockAuthProvider.isAnonymous).thenReturn(false);

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        Provider<RequestProvider>(create: (_) => mockRequestProvider),
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Open Ask Permissions page
      expect(find.text('Request editing permissions'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ask_permissions')));
      await tester.pumpAndSettle();
      expect(find.byType(AskPermissions), findsOneWidget);

      // Send a request
      await tester.enterText(
          find.byType(TextFormField), 'I love League of Legends');
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify the request is sent and Settings Page pops back
      verify(
          mockRequestProvider.makeRequest(any, context: anyNamed('context')));
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Ask Permissions - user has already sent a request scenario',
        (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((_) =>
          Future.value(User(uid: '0', firstName: 'John', lastName: 'Doe')));
      when(mockAuthProvider.isVerifiedFromCache).thenAnswer((_) => true);
      when(mockAuthProvider.isAnonymous).thenReturn(false);
      when(mockRequestProvider.userAlreadyRequested(any,
              context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        Provider<RequestProvider>(create: (_) => mockRequestProvider),
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Open Ask Permissions page
      expect(find.text('Request editing permissions'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ask_permissions')));
      await tester.pumpAndSettle();
      expect(find.byType(AskPermissions), findsOneWidget);

      // Send a request
      await tester.enterText(
          find.byType(TextFormField), 'I love League of Legends');
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check that warning Dialog appears and press Send
      expect(find.byType(AppDialog), findsOneWidget);
      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify the request is sent and Settings Page pops back
      verify(
          mockRequestProvider.makeRequest(any, context: anyNamed('context')));
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Ask Permissions - user is anonymous scenario',
        (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((_) =>
          Future.value(User(uid: '0', firstName: 'John', lastName: 'Doe')));
      when(mockAuthProvider.isVerifiedFromCache).thenAnswer((_) => true);
      when(mockAuthProvider.isAnonymous).thenReturn(true);
      when(mockRequestProvider.userAlreadyRequested(any,
              context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        Provider<RequestProvider>(create: (_) => mockRequestProvider),
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Press Ask Permissions page
      expect(find.text('Request editing permissions'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ask_permissions')));
      await tester.pumpAndSettle();

      // Verify nothing happens
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Ask Permissions - user is not verified scenario',
        (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((_) =>
          Future.value(User(uid: '0', firstName: 'John', lastName: 'Doe')));
      when(mockAuthProvider.isVerifiedFromCache).thenAnswer((_) => false);
      when(mockAuthProvider.isAnonymous).thenReturn(false);
      when(mockRequestProvider.userAlreadyRequested(any,
              context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        Provider<RequestProvider>(create: (_) => mockRequestProvider),
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Press Ask Permissions page
      expect(find.text('Request editing permissions'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ask_permissions')));

      // Verify Ask Permissions page is not opened
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.byType(SettingsPage), findsOneWidget);

      // Verify account
      when(mockAuthProvider.isVerifiedFromCache).thenAnswer((_) => true);

      // Press Ask Permissions page
      expect(find.text('Request editing permissions'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ask_permissions')));

      // Verify Ask Permissions page is opened
      await tester.pumpAndSettle();
      expect(find.byType(AskPermissions), findsOneWidget);
    });
  });
}
