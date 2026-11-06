import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roamora_flutter/core/theme/app_theme.dart';
import 'package:roamora_flutter/providers/auth_provider.dart';
import 'package:roamora_flutter/screens/auth/otp_verification_screen.dart';
import 'package:roamora_flutter/screens/onboarding/onboarding_wizard_screen.dart';

class _FakeAuth extends AuthNotifier {
  String? verifiedCode;

  @override
  Future<void> checkAuth() async {
    state = AuthState(isLoading: false);
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String email) async =>
      {'sent': true, 'expiresInSeconds': 60};

  @override
  Future<bool> verifyOtp(String email, String code) async {
    verifiedCode = code;
    return true;
  }

  @override
  Future<bool> updateProfile(Map<String, dynamic> data) async => true;

  @override
  Future<bool> updatePreferences(Map<String, dynamic> data) async => true;
}

final List<FlutterErrorDetails> _errors = [];

/// Collects every framework error (including RenderFlex overflow) and prints it,
/// so a test can assert that none occurred.
void _collectErrors() {
  _errors.clear();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    _errors.add(details);
  };
}

Widget _app(Widget home, _FakeAuth auth) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => home),
    GoRoute(path: '/onboarding', builder: (_, __) => const Scaffold(body: Text('ONBOARDING'))),
  ]);
  return ProviderScope(
    overrides: [authProvider.overrideWith((ref) => auth)],
    child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
}

void _setSize(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder get _verifyButton => find.widgetWithText(ElevatedButton, 'Verify 6-Digit Code');
bool _verifyEnabled(WidgetTester t) => t.widget<ElevatedButton>(_verifyButton).onPressed != null;

void main() {
  // flutter_test renders text with the "Ahem" font (every glyph is 1em wide),
  // which makes layouts look ~2x wider than on a device. Load a real proportional
  // font under the Roboto family when one is available on the host.
  setUpAll(() async {
    final candidates = [
      File(r'C:\Windows\Fonts\arial.ttf'),
      File('/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'),
      File('/System/Library/Fonts/Supplemental/Arial.ttf'),
    ];
    for (final f in candidates) {
      if (f.existsSync()) {
        final loader = FontLoader('Roboto')
          ..addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
        await loader.load();
        break;
      }
    }
  });

  for (final width in [280.0, 320.0, 360.0, 412.0]) {
    testWidgets('OTP screen: no overflow, paste/manual/backspace/verify at ${width}px', (tester) async {
      _collectErrors();
      _setSize(tester, width, 760);
      final auth = _FakeAuth();
      await tester.pumpWidget(_app(
        const OtpVerificationScreen(email: 'soniyagupta0228@gmail.com'),
        auth,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      final field = find.byType(TextField);
      expect(_verifyEnabled(tester), isFalse);

      // Manual entry, one digit at a time
      for (final partial in ['1', '12', '123']) {
        await tester.enterText(field, partial);
        await tester.pump();
      }
      expect(find.text('3'), findsOneWidget);
      expect(_verifyEnabled(tester), isFalse);

      // Backspace
      await tester.enterText(field, '12');
      await tester.pump();
      expect(find.text('3'), findsNothing);

      // Partial paste (fewer than six digits, with separators)
      await tester.enterText(field, '45-67');
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '4567');
      expect(_verifyEnabled(tester), isFalse);

      // Full paste in one action, includes whitespace and extra characters
      await tester.enterText(field, ' 482 913 99');
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '482913');
      expect(_verifyEnabled(tester), isTrue);

      await tester.ensureVisible(_verifyButton);
      await tester.tap(_verifyButton);
      await tester.pump();
      expect(auth.verifiedCode, '482913');
      await tester.pump(const Duration(seconds: 2));

      expect(_errors, isEmpty);
    });
  }

  testWidgets('OTP screen stays usable with keyboard open', (tester) async {
    _collectErrors();
    _setSize(tester, 320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(const OtpVerificationScreen(email: 'a@b.com'), _FakeAuth()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_errors, isEmpty);
  });

  for (final width in [280.0, 320.0, 360.0]) {
    testWidgets('Onboarding steps 1-4 (header, photo counter) no overflow at ${width}px', (tester) async {
      _collectErrors();
      _setSize(tester, width, 900);
      await tester.pumpWidget(_app(const OnboardingWizardScreen(), _FakeAuth()));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Soniya');
      for (var i = 0; i < 3; i++) {
        final next = find.textContaining('Save');
        await tester.ensureVisible(next.last);
        await tester.tap(next.last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(_errors, isEmpty);
    });
  }
}
