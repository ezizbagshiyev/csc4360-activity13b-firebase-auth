import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incl13b/auth_service.dart';
import 'package:incl13b/main.dart';

class StubAuthService implements AuthService {
  Completer<UserCredential>? pending;
  @override
  User? get currentUser => null;
  @override
  Stream<User?> get authState => Stream<User?>.value(null);
  @override
  Future<UserCredential> signIn(String email, String password) =>
      pending!.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json');
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final pkg = (config['packages'] as List).firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final flutterPackage = Directory.fromUri(
      configFile.absolute.uri.resolve(pkg['rootUri'] as String),
    );
    final fontDir = flutterPackage.parent.parent.uri.resolve(
      'bin/cache/artifacts/material_fonts/',
    );
    final font = FontLoader('Roboto')
      ..addFont(
        File.fromUri(fontDir.resolve('roboto-regular.ttf'))
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File.fromUri(fontDir.resolve('materialicons-regular.otf'))
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await icons.load();
  });
  testWidgets(
    'signed-out view, validation, loading, and safe network feedback',
    (tester) async {
      tester.view.physicalSize = const Size(440, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = StubAuthService();
      await tester.pumpWidget(AuthApp(service: service));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Your profile'), findsNothing);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evidence/01-signed-out.png'),
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Use at least 6 characters.'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evidence/02-invalid-input.png'),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'learner@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Fictional-test-only',
      );
      service.pending = Completer<UserCredential>();
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evidence/03-loading.png'),
      );
      service.pending!.completeError(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('evidence/04-network-error.png'),
      );
    },
  );
}
