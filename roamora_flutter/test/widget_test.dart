import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamora_flutter/core/theme/app_theme.dart';
import 'package:roamora_flutter/core/constants/app_colors.dart';
import 'package:roamora_flutter/core/widgets/pookie_verified_badge.dart';
import 'package:roamora_flutter/models/user_model.dart';

void main() {
  testWidgets('AppTheme provides correct Pookie Match coral primary branding and styles', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Pookie Match')),
          body: const Column(
            children: [
              Text('Gamified Dating'),
              PookieVerifiedBadge(),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pookie Match'), findsOneWidget);
    expect(find.text('Gamified Dating'), findsOneWidget);
    expect(find.text('Pookie Verified'), findsOneWidget);
    expect(AppTheme.lightTheme.primaryColor, AppColors.coral);
    expect(AppColors.coral, const Color(0xFFF06B72));
  });

  test('ProfileCompletionModel calculates 5 x 20% = 100% milestones accurately', () {
    final fullUser = UserModel.fromJson({
      'id': 'u-1',
      'email': 'soniya@gmail.com',
      'age': 23,
      'googleLinked': true,
      'isEmailVerified': true,
      'isIdentityVerified': true,
      'onboardingCompleted': true,
      'profile': {
        'displayName': 'Soniya',
        'bio': 'Coffee & sunsets in Mumbai',
        'city': 'Mumbai',
        'gender': 'Woman',
        'lookingFor': 'Long-term partner',
        'interests': ['Travel', 'Music'],
        'photos': ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      },
      'preferences': {
        'minAge': 21,
        'maxAge': 30,
        'maxDistanceKm': 25,
      },
    });

    expect(fullUser.completion.percentage, 100);
    expect(fullUser.completion.isComplete, isTrue);
    expect(fullUser.completion.basicAccountAndGmail, isTrue);
    expect(fullUser.completion.demographicsAndBio, isTrue);
    expect(fullUser.completion.hobbiesAndPreferences, isTrue);
    expect(fullUser.completion.minTwoPhotos, isTrue);
    expect(fullUser.completion.faceLivenessVerified, isTrue);
  });
}
