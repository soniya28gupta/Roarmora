import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/pookie_verified_badge.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const int maxBioLength = 150;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _allHobbies = [
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
  ];

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.profile?.displayName ?? '');
    final initialBio = user.profile?.bio ?? '';
    final bioCtrl = TextEditingController(
      text: initialBio.length > maxBioLength ? initialBio.substring(0, maxBioLength) : initialBio,
    );
    final cityCtrl = TextEditingController(text: user.profile?.city ?? '');
    String selectedGender = user.profile?.gender ?? 'Woman';
    String selectedGoal = user.profile?.connectionGoal ?? user.profile?.lookingFor ?? 'Long-term partner';
    final selectedHobbies = (user.profile?.interests ?? []).toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final remainingBio = maxBioLength - bioCtrl.text.length;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Edit Profile & Bio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: ['Woman', 'Man', 'Non-binary', 'Prefer not to say'].contains(selectedGender)
                        ? selectedGender
                        : 'Woman',
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Woman', child: Text('Woman')),
                      DropdownMenuItem(value: 'Man', child: Text('Man')),
                      DropdownMenuItem(value: 'Non-binary', child: Text('Non-binary')),
                      DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedGender = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: [
                      'Long-term partner',
                      'Casual dating',
                      'Adventure buddy',
                      'New friends',
                    ].contains(selectedGoal)
                        ? selectedGoal
                        : 'Long-term partner',
                    decoration: const InputDecoration(labelText: 'Connection Goal'),
                    items: const [
                      DropdownMenuItem(value: 'Long-term partner', child: Text('Long-term partner')),
                      DropdownMenuItem(value: 'Casual dating', child: Text('Casual dating')),
                      DropdownMenuItem(value: 'Adventure buddy', child: Text('Adventure buddy')),
                      DropdownMenuItem(value: 'New friends', child: Text('New friends')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedGoal = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bio (Max 150 chars)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$remainingBio / $maxBioLength left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: remainingBio < 15 ? AppColors.error : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 3,
                    maxLength: maxBioLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(maxBioLength),
                    ],
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Share your vibe in 150 characters or fewer...',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hobbies & Interests',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allHobbies.map((hobby) {
                      final active = selectedHobbies.contains(hobby);
                      return FilterChip(
                        label: Text(hobby, style: const TextStyle(fontSize: 11)),
                        selected: active,
                        selectedColor: AppColors.coralSoft,
                        onSelected: (sel) {
                          setModalState(() {
                            if (sel) {
                              selectedHobbies.add(hobby);
                            } else {
                              selectedHobbies.remove(hobby);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final bio = bioCtrl.text.trim();
                  if (bio.length > maxBioLength) return;
                  Navigator.of(ctx).pop();
                  await ref.read(authProvider.notifier).updateProfile({
                    'displayName': nameCtrl.text.trim(),
                    'bio': bio,
                    'city': cityCtrl.text.trim(),
                    'gender': selectedGender,
                    'lookingFor': selectedGoal,
                    'interests': selectedHobbies.toList(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile saved & completion updated!')),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addPhotoFromSource(UserModel user, ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 960,
      maxHeight: 1200,
      imageQuality: 78,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final updatedPhotos = <String>[
      ...(user.profile?.photos ?? []),
      dataUri,
    ];

    if (updatedPhotos.length >= 2) {
      await ref.read(authProvider.notifier).uploadProfilePhotos(updatedPhotos);
    } else {
      await ref.read(authProvider.notifier).updateProfile({
        'photos': updatedPhotos,
        'imageUrl': updatedPhotos.first,
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out of Pookie Match?'),
        content: const Text(
          'You will be logged out of this device session. Your matches and messages are saved safely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Yes, Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }

    final profile = user.profile;
    final completion = user.completion;
    final name = profile?.displayName ?? 'Pookie Member';
    final city = profile?.city ?? 'Mumbai';
    final bio = profile?.bio ?? '';
    final imageUrl = profile?.imageUrl;
    final photos = profile?.photos ?? [];
    final interests = profile?.interests ?? [];
    final stats = user.stats ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded),
            onPressed: () => context.push('/onboarding'),
            tooltip: 'Onboarding Wizard',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(context, user),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildAvatarWidget(imageUrl, name),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        user.age != null ? '$name, ${user.age}' : name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      if (user.isIdentityVerified) const PookieVerifiedBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.coral),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      if (profile?.gender != null && profile!.gender!.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          profile.gender!,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Completion', '${completion.percentage}%'),
                        Container(width: 1, height: 28, color: AppColors.border),
                        _buildStat('Matches', '${stats['matchesCount'] ?? 0}'),
                        Container(width: 1, height: 28, color: AppColors.border),
                        _buildStat('Photos', '${photos.length}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Profile Completion Matrix Card (5 x 20% = 100%)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile Completion Matrix',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: completion.isComplete
                              ? AppColors.emeraldPale
                              : AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          completion.isComplete
                              ? '100% Complete ✨'
                              : '${completion.percentage}% Complete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: completion.isComplete
                                ? AppColors.emerald
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: completion.percentage / 100.0,
                      minHeight: 9,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completion.isComplete ? AppColors.emerald : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMilestoneRow(
                    title: 'Basic Account & Gmail Link',
                    weight: '20%',
                    completed: completion.basicAccountAndGmail,
                    onTap: completion.basicAccountAndGmail
                        ? null
                        : () => context.push(
                              '/otp-verification?email=${Uri.encodeComponent(user.email)}&next=/profile',
                            ),
                  ),
                  _buildMilestoneRow(
                    title: 'Core Demographics & Bio (≤ 150 chars)',
                    weight: '20%',
                    completed: completion.demographicsAndBio,
                    onTap: () => _showEditProfileDialog(context, user),
                  ),
                  _buildMilestoneRow(
                    title: 'Hobbies & Preferences Added',
                    weight: '20%',
                    completed: completion.hobbiesAndPreferences,
                    onTap: () => context.push('/onboarding'),
                  ),
                  _buildMilestoneRow(
                    title: 'Minimum 2 Gallery Photos Uploaded',
                    weight: '20%',
                    completed: completion.minTwoPhotos,
                    onTap: () => _addPhotoFromSource(user, ImageSource.gallery),
                  ),
                  _buildMilestoneRow(
                    title: 'Face Scan Liveness Verified',
                    weight: '20%',
                    completed: completion.faceLivenessVerified,
                    onTap: () => context.push('/face-verification'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gallery Photos Section (Minimum 2 Required)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gallery Photos (Min 2 Required)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addPhotoFromSource(user, ImageSource.gallery),
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (photos.isEmpty)
                    const Text(
                      'Upload at least 2 gallery photos to unlock your +20% photo completion milestone.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    )
                  else
                    SizedBox(
                      height: 115,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 92,
                              height: 115,
                              child: _buildPhotoItem(photos[idx]),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interests Section
            if (interests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hobbies & Interests',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests.map((i) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.coralSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            i,
                            style: const TextStyle(
                              color: AppColors.coralDark,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Face Liveness Verification Banner
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF1D9BF0),
                    size: 20,
                  ),
                ),
                title: Text(
                  user.isIdentityVerified
                      ? 'Pookie Verified (Identity Confirmed)'
                      : 'Verify Identity (Face Liveness Scan)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  user.isIdentityVerified
                      ? 'Your official blue Pookie Verified badge is active'
                      : 'Complete a live selfie check to earn the blue Pookie Verified badge (+20%)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: () => context.push('/face-verification'),
              ),
            ),
            const SizedBox(height: 16),

            // Discovery Preferences & Location Settings
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy & Discovery Preferences',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Discoverable in Nearby Radar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Allow mutual matches to find your profile in Discover',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: profile?.discoverable ?? true,
                    activeThumbColor: AppColors.coral,
                    onChanged: (val) {
                      ref.read(authProvider.notifier).updateProfile({'discoverable': val});
                    },
                  ),
                  const Divider(color: AppColors.border),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Share Location on Adventure Map',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Display distance & marker to consented mutual matches',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: user.preferences?.locationConsent ?? true,
                    activeThumbColor: AppColors.coral,
                    onChanged: (val) {
                      ref.read(authProvider.notifier).updatePreferences({'locationConsent': val});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Safety & Blocked Users
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.coralSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.coral, size: 20),
                ),
                title: const Text(
                  'Blocked Users',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Manage blocked accounts & restore discovery',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: () => context.push('/blocked-users'),
              ),
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coral,
                side: const BorderSide(color: AppColors.coral, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out of Pookie Match'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(String? imageUrl, String name) {
    if (imageUrl != null && imageUrl.startsWith('data:image/')) {
      final commaIdx = imageUrl.indexOf(',');
      if (commaIdx != -1) {
        final bytes = base64Decode(imageUrl.substring(commaIdx + 1));
        return CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.coralSoft,
          backgroundImage: MemoryImage(bytes),
        );
      }
    }
    return CircleAvatar(
      radius: 46,
      backgroundColor: AppColors.coralSoft,
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl)
          : null,
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.coral,
              ),
            )
          : null,
    );
  }

  Widget _buildPhotoItem(String uri) {
    if (uri.startsWith('data:image/')) {
      final commaIdx = uri.indexOf(',');
      if (commaIdx != -1) {
        final bytes = base64Decode(uri.substring(commaIdx + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    }
    return CachedNetworkImage(
      imageUrl: uri,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surfaceMuted,
        child: const Icon(Icons.image_outlined),
      ),
    );
  }

  Widget _buildMilestoneRow({
    required String title,
    required String weight,
    required bool completed,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: completed ? AppColors.emerald : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: completed ? FontWeight.w600 : FontWeight.w500,
                  color: completed ? AppColors.ink : AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: completed ? AppColors.emeraldPale : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$weight',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: completed ? AppColors.emerald : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
