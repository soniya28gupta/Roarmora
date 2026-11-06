import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const int maxBioLength = 150;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController(text: 'Mumbai');
  final _bioController = TextEditingController();

  DateTime? _birthDate;
  String _selectedGender = 'Woman';
  bool _obscurePassword = true;

  final List<String> _availableInterests = [
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
  ];
  final Set<String> _selectedInterests = {'Travel', 'Music', 'Cafés'};

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    FocusScope.of(context).unfocus();
    final email = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted || email == null) return;
    final encoded = Uri.encodeComponent(email);
    context.go('/otp-verification?email=$encoded&preSent=true');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birth date (must be 18+)')),
      );
      return;
    }

    final cleanEmail = _emailController.text.trim().toLowerCase();
    final formattedDate = DateFormat('yyyy-MM-dd').format(_birthDate!);
    final bioText = _bioController.text.trim().isEmpty
        ? 'Exploring the city and meeting genuine people.'
        : _bioController.text.trim();

    final success = await ref.read(authProvider.notifier).register(
          email: cleanEmail,
          password: _passwordController.text,
          birthDate: formattedDate,
          displayName: _nameController.text.trim(),
          bio: bioText.length > maxBioLength ? bioText.substring(0, maxBioLength) : bioText,
          city: _cityController.text.trim(),
          interests: _selectedInterests.toList(),
          gender: _selectedGender,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isDuplicateEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An account with this email already exists. Redirecting to Log In...'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      context.go('/login?email=${Uri.encodeComponent(cleanEmail)}');
      return;
    }

    if (success) {
      context.go('/otp-verification?email=${Uri.encodeComponent(cleanEmail)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final remainingBio = maxBioLength - _bioController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join Pookie Match',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'One Email ID = One Profile. Verify with 6-digit OTP & set up your profile.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                // Google Sign-Up Button
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _handleGoogleSignUp,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  label: const Text('Sign Up with Google (Gmail)'),
                ),
                const SizedBox(height: 16),

                if (authState.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                        if (authState.isDuplicateEmail) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              final email = Uri.encodeComponent(_emailController.text.trim().toLowerCase());
                              context.go('/login?email=$email');
                            },
                            child: const Text('Log in with this email instead →'),
                          ),
                        ],
                      ],
                    ),
                  ),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Soniya Gupta',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Gmail)',
                    hintText: 'name@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password (min 12 characters)',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 12 ? 'Password must be at least 12 characters' : null,
                ),
                const SizedBox(height: 14),

                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Text(
                          _birthDate == null
                              ? 'Select Birth Date (18+ Required)'
                              : DateFormat('MMM dd, yyyy').format(_birthDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _birthDate == null ? AppColors.textDisabled : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_rounded, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Woman', child: Text('Woman')),
                    DropdownMenuItem(value: 'Man', child: Text('Man')),
                    DropdownMenuItem(value: 'Non-binary', child: Text('Non-binary')),
                    DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGender = val);
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'City required' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Short Bio (Max 150 Characters)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
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
                TextFormField(
                  controller: _bioController,
                  maxLines: 2,
                  maxLength: maxBioLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxBioLength),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Share what excites you or your favorite weekend ritual…',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v != null && v.trim().length > maxBioLength) {
                      return 'Bio cannot exceed 150 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                const Text(
                  'Select Your Hobbies & Interests',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      selectedColor: AppColors.coralSoft,
                      checkmarkColor: AppColors.coral,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.coralDark : AppColors.ink,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.coral : AppColors.border,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Account & Send 6-Digit OTP →'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
