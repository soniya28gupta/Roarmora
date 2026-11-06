class ProfileCompletionModel {
  final int percentage;
  final bool isComplete;
  final bool basicAccountAndGmail;
  final bool demographicsAndBio;
  final bool hobbiesAndPreferences;
  final bool minTwoPhotos;
  final bool faceLivenessVerified;

  const ProfileCompletionModel({
    required this.percentage,
    required this.isComplete,
    required this.basicAccountAndGmail,
    required this.demographicsAndBio,
    required this.hobbiesAndPreferences,
    required this.minTwoPhotos,
    required this.faceLivenessVerified,
  });

  factory ProfileCompletionModel.fromJson(Map<String, dynamic> json) {
    final milestones = json['milestones'] as Map<String, dynamic>? ?? {};
    final basic = milestones['basicAccountAndGmail'] as bool? ?? false;
    final demo = milestones['demographicsAndBio'] as bool? ?? false;
    final hobbies = milestones['hobbiesAndPreferences'] as bool? ?? false;
    final photos = milestones['minTwoPhotos'] as bool? ?? false;
    final face = milestones['faceLivenessVerified'] as bool? ?? false;

    final computedPct = ([basic, demo, hobbies, photos, face].where((e) => e).length) * 20;
    final pct = json['percentage'] as int? ?? computedPct;

    return ProfileCompletionModel(
      percentage: pct,
      isComplete: json['isComplete'] as bool? ?? (pct == 100),
      basicAccountAndGmail: basic,
      demographicsAndBio: demo,
      hobbiesAndPreferences: hobbies,
      minTwoPhotos: photos,
      faceLivenessVerified: face,
    );
  }

  factory ProfileCompletionModel.computeFallback({
    required String email,
    required bool isEmailVerified,
    required bool googleLinked,
    required bool isIdentityVerified,
    int? age,
    ProfileModel? profile,
    UserPreferencesModel? preferences,
  }) {
    final basic = email.isNotEmpty && (isEmailVerified || googleLinked || email.toLowerCase().endsWith('@gmail.com') || profile != null);
    final bioTrimmed = profile?.bio.trim() ?? '';
    final demo = (profile?.displayName.trim().isNotEmpty ?? false) &&
        ((age ?? profile?.age ?? 18) >= 18) &&
        ((profile?.gender?.trim().isNotEmpty ?? false) || bioTrimmed.isNotEmpty) &&
        bioTrimmed.isNotEmpty &&
        bioTrimmed.length <= 150;
    final hobbies = (profile?.interests.isNotEmpty ?? false) &&
        preferences != null;
    final effectivePhotosCount = (profile?.photos.length ?? 0) +
        (((profile?.photos.isEmpty ?? true) && (profile?.imageUrl?.isNotEmpty ?? false)) ? 1 : 0);
    final photos = effectivePhotosCount >= 2;
    final face = isIdentityVerified || (profile?.isIdentityVerified ?? false);

    final count = [basic, demo, hobbies, photos, face].where((v) => v).length;
    final pct = count * 20;

    return ProfileCompletionModel(
      percentage: pct,
      isComplete: pct == 100,
      basicAccountAndGmail: basic,
      demographicsAndBio: demo,
      hobbiesAndPreferences: hobbies,
      minTwoPhotos: photos,
      faceLivenessVerified: face,
    );
  }
}

class ProfileModel {
  final String? id;
  final String displayName;
  final String bio;
  final String city;
  final List<String> interests;
  final String? imageUrl;
  final List<String> photos;
  final String? gender;
  final String? lookingFor;
  final String? connectionGoal;
  final bool isIdentityVerified;
  final int? compatibilityScore;
  final bool discoverable;
  final int? age;

  ProfileModel({
    this.id,
    required this.displayName,
    required this.bio,
    required this.city,
    required this.interests,
    this.imageUrl,
    this.photos = const [],
    this.gender,
    this.lookingFor,
    this.connectionGoal,
    this.isIdentityVerified = false,
    this.compatibilityScore,
    this.discoverable = true,
    this.age,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? [];
    final primaryImage = json['imageUrl'] as String?;
    final mergedPhotos = <String>[
      ...rawPhotos,
      if (rawPhotos.isEmpty && primaryImage != null && primaryImage.isNotEmpty) primaryImage,
    ];

    return ProfileModel(
      id: json['id'] as String?,
      displayName: json['displayName'] as String? ?? 'Pookie Member',
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String? ?? 'Nearby',
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: primaryImage ?? (mergedPhotos.isNotEmpty ? mergedPhotos.first : null),
      photos: mergedPhotos,
      gender: json['gender'] as String?,
      lookingFor: json['lookingFor'] as String?,
      connectionGoal: json['connectionGoal'] as String? ?? json['lookingFor'] as String?,
      isIdentityVerified: json['isIdentityVerified'] as bool? ?? false,
      compatibilityScore: json['compatibilityScore'] as int?,
      discoverable: json['discoverable'] as bool? ?? true,
      age: json['age'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'displayName': displayName,
      'bio': bio,
      'city': city,
      'interests': interests,
      'imageUrl': imageUrl,
      'photos': photos,
      if (gender != null) 'gender': gender,
      if (lookingFor != null) 'lookingFor': lookingFor,
      if (connectionGoal != null) 'connectionGoal': connectionGoal,
      'discoverable': discoverable,
    };
  }
}

class UserPreferencesModel {
  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final int discoveryRadiusMeters;
  final bool globalExploreMode;
  final List<String> interests;
  final List<String> genderPreference;
  final bool locationConsent;

  UserPreferencesModel({
    this.minAge = 18,
    this.maxAge = 99,
    this.maxDistanceKm = 50,
    this.discoveryRadiusMeters = 500,
    this.globalExploreMode = false,
    this.interests = const [],
    this.genderPreference = const [],
    this.locationConsent = false,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      minAge: json['minAge'] as int? ?? 18,
      maxAge: json['maxAge'] as int? ?? 99,
      maxDistanceKm: json['maxDistanceKm'] as int? ?? 50,
      discoveryRadiusMeters: json['discoveryRadiusMeters'] as int? ?? 500,
      globalExploreMode: json['globalExploreMode'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      genderPreference: (json['genderPreference'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      locationConsent: json['locationConsent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistanceKm': maxDistanceKm,
      'discoveryRadiusMeters': discoveryRadiusMeters,
      'globalExploreMode': globalExploreMode,
      'interests': interests,
      'genderPreference': genderPreference,
      'locationConsent': locationConsent,
    };
  }
}

class UserModel {
  final String id;
  final String email;
  final String? birthDate;
  final int? age;
  final bool googleLinked;
  final bool isEmailVerified;
  final bool isIdentityVerified;
  final bool onboardingCompleted;
  final ProfileModel? profile;
  final UserPreferencesModel? preferences;
  final ProfileCompletionModel completion;
  final Map<String, dynamic>? stats;

  UserModel({
    required this.id,
    required this.email,
    this.birthDate,
    this.age,
    this.googleLinked = false,
    this.isEmailVerified = false,
    this.isIdentityVerified = false,
    this.onboardingCompleted = true,
    this.profile,
    this.preferences,
    required this.completion,
    this.stats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final age = json['age'] as int?;
    final googleLinked = json['googleLinked'] as bool? ?? false;
    final isEmailVerified = json['isEmailVerified'] as bool? ?? false;
    final isIdentityVerified = json['isIdentityVerified'] as bool? ?? false;
    final profile = json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null;
    final preferences = json['preferences'] != null ? UserPreferencesModel.fromJson(json['preferences']) : null;

    final hasExistingProfile = profile != null &&
        profile.displayName.trim().isNotEmpty &&
        profile.interests.isNotEmpty;

    final onboardingCompleted = json['onboardingCompleted'] as bool? ?? hasExistingProfile;

    final completion = json['completion'] is Map<String, dynamic>
        ? ProfileCompletionModel.fromJson(json['completion'] as Map<String, dynamic>)
        : ProfileCompletionModel.computeFallback(
            email: email,
            isEmailVerified: isEmailVerified,
            googleLinked: googleLinked,
            isIdentityVerified: isIdentityVerified,
            age: age,
            profile: profile,
            preferences: preferences,
          );

    return UserModel(
      id: json['id'] as String,
      email: email,
      birthDate: json['birthDate'] as String?,
      age: age,
      googleLinked: googleLinked,
      isEmailVerified: isEmailVerified,
      isIdentityVerified: isIdentityVerified || (profile?.isIdentityVerified ?? false),
      onboardingCompleted: onboardingCompleted,
      profile: profile,
      preferences: preferences,
      completion: completion,
      stats: json['stats'] as Map<String, dynamic>?,
    );
  }
}
