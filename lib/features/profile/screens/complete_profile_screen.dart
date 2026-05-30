import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../groups/screens/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String name;
  const CompleteProfileScreen({super.key, required this.name});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  // Step 2
  String _selectedJobRole = '';
  String _selectedExperience = '';
  final List<String> _selectedSkills = [];

  // Step 3
  final List<String> _selectedInterests = [];
  final _statusController = TextEditingController();

  // Options
  final List<String> _jobRoles = [
    'Developer', 'Designer', 'Manager',
    'Marketing', 'Student', 'Freelancer', 'Other',
  ];

  final List<String> _experienceLevels = [
    'Student', 'Junior', 'Mid-Level', 'Senior', 'Lead',
  ];

  final List<String> _skillOptions = [
    'Flutter', 'React', 'Node.js', 'Python', 'Firebase',
    'UI/UX', 'Figma', 'Java', 'Swift', 'Kotlin',
    'DevOps', 'AI/ML', 'Blockchain', 'Product',
  ];

  final List<String> _interestOptions = [
    '#Coding', '#Gym', '#Design', '#AI', '#Startups',
    '#Gaming', '#Reading', '#Music', '#Travel', '#Photography',
    '#Finance', '#Fitness', '#Writing', '#Crypto',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep == 0 && _usernameController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Save to Firestore
  // ─────────────────────────────────────────────

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final profileData = {
        'name': widget.name,
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'jobRole': _selectedJobRole,
        'experienceLevel': _selectedExperience,
        'skills': _selectedSkills,
        'interests': _selectedInterests,
        'currentStatus': _statusController.text.trim(),
        'photoUrl': '',
        'coverPhotoUrl': '',
        'followers': [],
        'following': [],
        'groupIds': [],
        'featuredItems': [],
        'badges': ['early_adopter'],
        'isVerified': false,
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompletion': _calculateCompletion(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateCompletion() {
    int score = 0;
    if (widget.name.isNotEmpty) score += 15;
    if (_usernameController.text.isNotEmpty) score += 15;
    if (_bioController.text.isNotEmpty) score += 15;
    if (_selectedJobRole.isNotEmpty) score += 10;
    if (_selectedExperience.isNotEmpty) score += 10;
    if (_selectedSkills.isNotEmpty) score += 10;
    if (_selectedInterests.isNotEmpty) score += 5;
    if (_statusController.text.isNotEmpty) score += 5;
    return score; // max 85% (photo/cover 15% later)
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress header
            _buildHeader(),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),

            // Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header + Progress
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    final titles = ['Basic Info', 'Professional', 'Interests'];
    final subtitles = [
      'Username aur bio add karo',
      'Role aur skills batao',
      'Interests aur status set karo',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(
            children: List.generate(3, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.accent
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 6),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Step label
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titles[_currentStep],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitles[_currentStep],
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 1 — Basic Info
  // ─────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name display (readonly)
          _SectionLabel(label: 'Full Name'),
          _ReadonlyField(value: widget.name, icon: Icons.person_rounded),
          const SizedBox(height: 20),

          // Username
          _SectionLabel(label: 'Username *'),
          _InputField(
            controller: _usernameController,
            hint: 'e.g. fahad_dev',
            icon: Icons.alternate_email_rounded,
            prefix: '@',
          ),
          const SizedBox(height: 6),
          const Text(
            'Unique username — doosre log is se tumhe dhundh sakte hain',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 20),

          // Bio
          _SectionLabel(label: 'Bio (Optional)'),
          _InputField(
            controller: _bioController,
            hint: 'Flutter Developer 🚀 | Building amazing apps | Gym enthusiast 💪',
            icon: Icons.edit_note_rounded,
            maxLines: 3,
            maxLength: 120,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 2 — Professional Info
  // ─────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Role
          _SectionLabel(label: 'Role'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _jobRoles.map((role) {
              final isSelected = _selectedJobRole == role;
              return _SelectChip(
                label: role,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedJobRole = role),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Experience
          _SectionLabel(label: 'Experience Level'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _experienceLevels.map((level) {
              final isSelected = _selectedExperience == level;
              return _SelectChip(
                label: level,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedExperience = level),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Skills
          _SectionLabel(label: 'Skills (multiple select kar sako)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillOptions.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return _SelectChip(
                label: skill,
                isSelected: isSelected,
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedSkills.remove(skill);
                  } else {
                    _selectedSkills.add(skill);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 3 — Interests & Status
  // ─────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interests
          _SectionLabel(label: 'Interests'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestOptions.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return _SelectChip(
                label: interest,
                isSelected: isSelected,
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Current Status
          _SectionLabel(label: 'Current Status (Optional)'),
          _InputField(
            controller: _statusController,
            hint: '🔥 Building something awesome',
            icon: Icons.bolt_rounded,
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Early adopter badge preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.accent.withValues(alpha: 0.12),
                AppColors.surface,
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🏆', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Early Adopter Badge 🎉',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tum Flowva ke early users mein se ho!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Bottom Buttons
  // ─────────────────────────────────────────────

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),

          // Next / Finish button
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _nextStep,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    _currentStep == 2 ? '🚀  Let\'s Go!' : 'Next  →',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Skip button (only step 2 & 3)
          if (_currentStep > 0) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _currentStep == 2 ? _saveProfile : _nextStep,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Small Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String value;
  final IconData icon;
  const _ReadonlyField({required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 14),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? prefix;
  final int maxLines;
  final int? maxLength;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.prefix,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontFamily: 'Inter',
          ),
          prefixIcon: prefix != null
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 6),
              Text(
                prefix!,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(icon, color: AppColors.textMuted, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}