import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/pookie_brand_mark.dart';
import '../../providers/auth_provider.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  static const int maxBioLength = 150;

  static const List<String> availableHobbies = [
    'Travel',
    'Gaming',
    'Fitness',
    'Art',
    'Music',
    'Cafés',
    'Outdoors',
    'Books',
    'Photography',
    'Food',
    'Movies',
    'Cooking',
    'Dancing',
    'Hiking',
  ];

  static const List<String> genderOptions = [
    'Woman',
    'Man',
    'Non-binary',
    'Prefer not to say',
  ];

  static const List<String> connectionGoals = [
    'Long-term partner',
    'Casual dating',
    'Adventure buddy',
    'New friends',
  ];

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  int _currentStep = 0;
  DateTime _birthDate = DateTime(2001, 5, 15);
  String _selectedGender = 'Woman';
  Set<String> _selectedHobbies = {'Travel', 'Music', 'Cafés'};
  RangeValues _ageRange = const RangeValues(20, 34);
  double _maxDistanceKm = 35;
  String _selectedGoal = 'Long-term partner';
  List<String> _photos = [];
  bool _isSaving = false;
  String? _stepError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final profile = user?.profile;
    final prefs = user?.preferences;

    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _cityController = TextEditingController(
      text: (profile?.city != null && profile!.city.isNotEmpty) ? profile.city : 'Mumbai',
    );
    final initialBio = profile?.bio ?? '';
    _bioController = TextEditingController(
      text: initialBio.length > maxBioLength ? initialBio.substring(0, maxBioLength) : initialBio,
    );

    if (user?.birthDate != null) {
      final parsed = DateTime.tryParse(user!.birthDate!);
      if (parsed != null) _birthDate = parsed;
    }
    if (profile?.gender != null && genderOptions.contains(profile!.gender)) {
      _selectedGender = profile.gender!;
    }
    if (profile != null && profile.interests.isNotEmpty) {
      _selectedHobbies = profile.interests.toSet();
    }
    if (prefs != null) {
      _ageRange = RangeValues(
        prefs.minAge.clamp(18, 99).toDouble(),
        prefs.maxAge.clamp(18, 99).toDouble(),
      );
      _maxDistanceKm = prefs.maxDistanceKm.clamp(1, 150).toDouble();
    }
    final existingGoal = profile?.connectionGoal ?? profile?.lookingFor;
    if (existingGoal != null && connectionGoals.contains(existingGoal)) {
      _selectedGoal = existingGoal;
    }
    if (profile != null && profile.photos.isNotEmpty) {
      _photos = List<String>.from(profile.photos);
    }

    _bioController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickPhoto(ImageSource source, {int? replaceIndex}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 1200,
        imageQuality: 78,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        _stepError = null;
        if (replaceIndex != null && replaceIndex >= 0 && replaceIndex < _photos.length) {
          _photos[replaceIndex] = dataUri;
        } else {
          _photos.add(dataUri);
        }
      });
    } catch (e) {
      setState(() {
        _stepError = 'Unable to pick image: $e';
      });
    }
  }

  Future<void> _saveCurrentStepAndAdvance() async {
    setState(() {
      _stepError = null;
    });

    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _stepError = 'Please enter your Full Name.');
        return;
      }
      if (_calculateAge(_birthDate) < 18) {
        setState(() => _stepError = 'You must be at least 18 years old to join Pookie Match.');
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        setState(() => _stepError = 'Please enter your City.');
        return;
      }
      setState(() => _isSaving = true);
      final birthStr =
          '${_birthDate.year.toString().padLeft(4, '0')}-${_birthDate.month.toString().padLeft(2, '0')}-${_birthDate.day.toString().padLeft(2, '0')}';
      final ok = await ref.read(authProvider.notifier).updateProfile({
        'displayName': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'gender': _selectedGender,
        'birthDate': birthStr,
      });
      setState(() => _isSaving = false);
      if (!ok) {
        setState(() => _stepError = ref.read(authProvider).error ?? 'Failed to save basic details.');
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_selectedHobbies.isEmpty) {
        setState(() => _stepError = 'Please select at least 1 hobby or interest.');
        return;
      }
      setState(() => _isSaving = true);
      final ok = await ref.read(authProvider.notifier).updateProfile({
        'interests': _selectedHobbies.toList(),
      });
      setState(() => _isSaving = false);
      if (!ok) {
        setState(() => _stepError = ref.read(authProvider).error ?? 'Failed to save hobbies.');
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      setState(() => _isSaving = true);
      final prefOk = await ref.read(authProvider.notifier).updatePreferences({
        'minAge': _ageRange.start.round(),
        'maxAge': _ageRange.end.round(),
        'maxDistanceKm': _maxDistanceKm.round(),
        'interests': _selectedHobbies.toList(),
      });
      final goalOk = await ref.read(authProvider.notifier).updateProfile({
        'lookingFor': _selectedGoal,
      });
      setState(() => _isSaving = false);
      if (!prefOk || !goalOk) {
        setState(() => _stepError = ref.read(authProvider).error ?? 'Failed to save preferences.');
        return;
      }
      setState(() => _currentStep = 3);
      return;
    }

    if (_currentStep == 3) {
      final bio = _bioController.text.trim();
      if (bio.isEmpty) {
        setState(() => _stepError = 'Please write a short bio about yourself.');
        return;
      }
      if (bio.length > maxBioLength) {
        setState(() => _stepError = 'Bio cannot exceed 150 characters.');
        return;
      }
      if (_photos.length < 2) {
        setState(() => _stepError = 'Please upload at least 2 photos to continue.');
        return;
      }

      setState(() => _isSaving = true);
      final bioOk = await ref.read(authProvider.notifier).updateProfile({
        'bio': bio,
      });
      final photosOk = await ref.read(authProvider.notifier).uploadProfilePhotos(_photos);
      await ref.read(authProvider.notifier).completeOnboarding();
      setState(() => _isSaving = false);

      if (!bioOk || !photosOk) {
        setState(() => _stepError = ref.read(authProvider).error ?? 'Failed to save bio and photos.');
        return;
      }
      if (!mounted) return;
      context.go('/face-verification?onboarding=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'Basic Profile Details',
      'Hobbies & Interests',
      'Dating Preferences',
      'Bio & Gallery Photos',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() => _currentStep -= 1),
              )
            : null,
        title: Row(
          children: [
            const Flexible(flex: 3, child: PookieBrandMark(size: 28)),
            const SizedBox(width: 10),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of 4',
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    Text(
                      stepTitles[_currentStep],
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 4,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentStep == 0) _buildStep1BasicDetails(),
                        if (_currentStep == 1) _buildStep2Hobbies(),
                        if (_currentStep == 2) _buildStep3Preferences(),
                        if (_currentStep == 3) _buildStep4BioAndPhotos(),

                        if (_stepError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              _stepError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveCurrentStepAndAdvance,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentStep < 3
                                      ? 'Save & Continue →'
                                      : 'Save Profile & Continue to Face Scan →',
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1BasicDetails() {
    final age = _calculateAge(_birthDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Complete your core demographics (+20% profile completion).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City / Area',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Birthdate (18+ required)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final now = DateTime.now();
            final latestAdult = DateTime(now.year - 18, now.month, now.day);
            final picked = await showDatePicker(
              context: context,
              initialDate: _birthDate.isAfter(latestAdult) ? latestAdult : _birthDate,
              firstDate: DateTime(1940),
              lastDate: latestAdult,
            );
            if (picked != null) {
              setState(() => _birthDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_birthDate.day}/${_birthDate.month}/${_birthDate.year} ($age years old)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Gender',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genderOptions.map((g) {
            final selected = _selectedGender == g;
            return ChoiceChip(
              label: Text(g),
              selected: selected,
              selectedColor: AppColors.primaryPale,
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) => setState(() => _selectedGender = g),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2Hobbies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hobbies & Interests',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Pick what you love so Pookie Match can compute shared vibe scores.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: availableHobbies.map((hobby) {
            final isSelected = _selectedHobbies.contains(hobby);
            return FilterChip(
              label: Text(hobby),
              selected: isSelected,
              selectedColor: AppColors.primaryPale,
              checkmarkColor: AppColors.primaryDark,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedHobbies.add(hobby);
                  } else {
                    _selectedHobbies.remove(hobby);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3Preferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dating Preferences',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Customize your discovery filters and connection goals (+20% with hobbies).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Preferred Age Range',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_ageRange.start.round()} – ${_ageRange.end.round()} yrs',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 99,
          divisions: 81,
          activeColor: AppColors.primary,
          labels: RangeLabels(
            '${_ageRange.start.round()}',
            '${_ageRange.end.round()}',
          ),
          onChanged: (values) => setState(() => _ageRange = values),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Maximum Distance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_maxDistanceKm.round()} km',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxDistanceKm,
          min: 1,
          max: 150,
          divisions: 149,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _maxDistanceKm = val),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connection Goal',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: connectionGoals.map((goal) {
            final selected = _selectedGoal == goal;
            return ChoiceChip(
              label: Text(goal),
              selected: selected,
              selectedColor: AppColors.primaryPale,
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) => setState(() => _selectedGoal = goal),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4BioAndPhotos() {
    final remainingChars = maxBioLength - _bioController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio & Gallery Photos',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Write a bio (max 150 chars) and upload at least 2 photos (+20% completion).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Your Bio (Strict 150-Character Limit)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$remainingChars / $maxBioLength left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: remainingChars < 15 ? AppColors.error : AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioController,
          maxLength: maxBioLength,
          maxLines: 3,
          inputFormatters: [
            LengthLimitingTextInputFormatter(maxBioLength),
          ],
          decoration: const InputDecoration(
            hintText: 'Coffee walks, board games & spontaneous weekend drives...',
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Profile Photos (Minimum 2 Required)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _photos.length >= 2 ? AppColors.emeraldPale : AppColors.primaryPale,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_photos.length} / 2+ uploaded',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _photos.length >= 2 ? AppColors.emerald : AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: (_photos.length < 6) ? _photos.length + 1 : 6,
          itemBuilder: (context, index) {
            if (index < _photos.length) {
              final uri = _photos[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildPhotoPreview(uri),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _photos.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showPhotoSourceSheet(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDark),
                    SizedBox(height: 6),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(String uri) {
    if (uri.startsWith('data:image/')) {
      final commaIdx = uri.indexOf(',');
      if (commaIdx != -1) {
        final bytes = base64Decode(uri.substring(commaIdx + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    }
    return Image.network(
      uri,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceMuted,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryDark),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark),
                title: const Text('Take a Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
