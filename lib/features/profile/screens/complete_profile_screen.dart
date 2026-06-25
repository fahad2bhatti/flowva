import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String name;
  const CompleteProfileScreen({super.key, required this.name});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _pageController    = PageController();
  int  _currentStep        = 0;
  bool _isLoading          = false;

  final _usernameController = TextEditingController();
  final _bioController      = TextEditingController();
  final _statusController   = TextEditingController();

  String _selectedJobRole    = '';
  String _selectedExperience = '';
  final List<String> _selectedSkills    = [];
  final List<String> _selectedInterests = [];

  static const _jobRoles = [
    'Developer','Designer','Manager','Marketing','Student','Freelancer','Other',
  ];
  static const _experienceLevels = [
    'Student','Junior','Mid-Level','Senior','Lead',
  ];
  static const _skillOptions = [
    'Flutter','React','Node.js','Python','Firebase',
    'UI/UX','Figma','Java','Swift','Kotlin','DevOps','AI/ML','Blockchain','Product',
  ];
  static const _interestOptions = [
    '#Coding','#Gym','#Design','#AI','#Startups',
    '#Gaming','#Reading','#Music','#Travel','#Photography',
    '#Finance','#Fitness','#Writing','#Crypto',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _usernameController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name'             : widget.name,
        'username'         : _usernameController.text.trim().toLowerCase(),
        'bio'              : _bioController.text.trim(),
        'jobRole'          : _selectedJobRole,
        'experienceLevel'  : _selectedExperience,
        'skills'           : _selectedSkills,
        'interests'        : _selectedInterests,
        'currentStatus'    : _statusController.text.trim(),
        'badges'           : ['early_adopter'],
        'isOnline'         : true,
        'lastActive'       : FieldValue.serverTimestamp(),
        'joinedAt'         : FieldValue.serverTimestamp(),
        'profileCompletion': _calculateCompletion(),
      }, SetOptions(merge: true));

      if (mounted) context.go('/home'); // ✅ GoRouter
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateCompletion() {
    int score = 0;
    if (widget.name.isNotEmpty)                score += 15;
    if (_usernameController.text.isNotEmpty)   score += 15;
    if (_bioController.text.isNotEmpty)        score += 15;
    if (_selectedJobRole.isNotEmpty)           score += 10;
    if (_selectedExperience.isNotEmpty)        score += 10;
    if (_selectedSkills.isNotEmpty)            score += 10;
    if (_selectedInterests.isNotEmpty)         score += 5;
    if (_statusController.text.isNotEmpty)     score += 5;
    return score;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles    = ['Basic Info', 'Professional', 'Interests'];
    final subtitles = [
      'Username and bio add karo',
      'Role and skills batao',
      'Interests and status set karo',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i == _currentStep;
              final done   = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          color: done || active
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
          Text('Step ${_currentStep + 1} of 3',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(titles[_currentStep],
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(subtitles[_currentStep],
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Inter')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(text: 'Full Name'),
          _ReadonlyField(value: widget.name),
          const SizedBox(height: 20),
          const _Label(text: 'Username *'),
          _InputField(
              controller: _usernameController,
              hint: 'e.g. fahad_dev',
              icon: Icons.alternate_email_rounded,
              prefix: '@'),
          const SizedBox(height: 6),
          const Text('Unique username — others can find you with this',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter')),
          const SizedBox(height: 20),
          const _Label(text: 'Bio (Optional)'),
          _InputField(
              controller: _bioController,
              hint: 'Flutter Developer | Building amazing apps',
              icon: Icons.edit_note_rounded,
              maxLines: 3,
              maxLength: 120),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(text: 'Role'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _jobRoles.map((r) => _SelectChip(
              label: r,
              isSelected: _selectedJobRole == r,
              onTap: () => setState(() => _selectedJobRole = r),
            )).toList(),
          ),
          const SizedBox(height: 20),
          const _Label(text: 'Experience Level'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _experienceLevels.map((e) => _SelectChip(
              label: e,
              isSelected: _selectedExperience == e,
              onTap: () => setState(() => _selectedExperience = e),
            )).toList(),
          ),
          const SizedBox(height: 20),
          const _Label(text: 'Skills'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillOptions.map((s) => _SelectChip(
              label: s,
              isSelected: _selectedSkills.contains(s),
              onTap: () => setState(() => _selectedSkills.contains(s)
                  ? _selectedSkills.remove(s)
                  : _selectedSkills.add(s)),
            )).toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(text: 'Interests'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestOptions.map((i) => _SelectChip(
              label: i,
              isSelected: _selectedInterests.contains(i),
              onTap: () => setState(() => _selectedInterests.contains(i)
                  ? _selectedInterests.remove(i)
                  : _selectedInterests.add(i)),
            )).toList(),
          ),
          const SizedBox(height: 20),
          const _Label(text: 'Current Status (Optional)'),
          _InputField(
              controller: _statusController,
              hint: 'Building something awesome',
              icon: Icons.bolt_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Early Adopter Badge',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter')),
                      SizedBox(height: 2),
                      Text('You are among Flowva\'s first users!',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Inter')),
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

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _nextStep,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : Text(
                    _currentStep == 2 ? 'Finish Setup' : 'Continue',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
              ),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _currentStep == 2 ? _saveProfile : _nextStep,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontFamily: 'Inter')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter')),
  );
}

class _ReadonlyField extends StatelessWidget {
  final String value;
  const _ReadonlyField({required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.person_rounded,
            color: AppColors.textMuted, size: 17),
        const SizedBox(width: 12),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontFamily: 'Inter')),
        const Spacer(),
        const Icon(Icons.lock_outline_rounded,
            color: AppColors.textMuted, size: 13),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
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
          fontSize: 14,
          fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textMuted, fontSize: 13, fontFamily: 'Inter'),
        prefixIcon: prefix != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: AppColors.textMuted, size: 17),
            const SizedBox(width: 5),
            Text(prefix!,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
          ],
        )
            : Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, color: AppColors.textMuted, size: 17),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        counterStyle: const TextStyle(
            color: AppColors.textMuted, fontSize: 10),
      ),
    ),
  );
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectChip(
      {required this.label,
        required this.isSelected,
        required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              color: isSelected
                  ? AppColors.accent
                  : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
              fontFamily: 'Inter')),
    ),
  );
}



