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

  String       _selectedJobRole    = '';
  String       _selectedExperience = '';
  final List<String> _selectedSkills     = [];
  final List<String> _selectedInterests  = [];

  final _jobRoles = ['Developer','Designer','Manager','Marketing','Student','Freelancer','Other'];
  final _experienceLevels = ['Student','Junior','Mid-Level','Senior','Lead'];
  final _skillOptions = ['Flutter','React','Node.js','Python','Firebase','UI/UX','Figma','Java','Swift','Kotlin','DevOps','AI/ML','Blockchain','Product'];
  final _interestOptions = ['#Coding','#Gym','#Design','#AI','#Startups','#Gaming','#Reading','#Music','#Travel','#Photography','#Finance','#Fitness','#Writing','#Crypto'];

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _next() {
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
      _save();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
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

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name'            : widget.name,
        'username'        : _usernameController.text.trim().toLowerCase(),
        'bio'             : _bioController.text.trim(),
        'jobRole'         : _selectedJobRole,
        'experienceLevel' : _selectedExperience,
        'skills'          : _selectedSkills,
        'interests'       : _selectedInterests,
        'currentStatus'   : _statusController.text.trim(),
        'badges'          : ['early_adopter'],
        'isOnline'        : true,
        'lastActive'      : FieldValue.serverTimestamp(),
        'joinedAt'        : FieldValue.serverTimestamp(),
        'profileCompletion': _calcCompletion(),
      }, SetOptions(merge: true));

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calcCompletion() {
    int s = 0;
    if (widget.name.isNotEmpty)               s += 15;
    if (_usernameController.text.isNotEmpty)  s += 15;
    if (_bioController.text.isNotEmpty)       s += 15;
    if (_selectedJobRole.isNotEmpty)          s += 10;
    if (_selectedExperience.isNotEmpty)       s += 10;
    if (_selectedSkills.isNotEmpty)           s += 10;
    if (_selectedInterests.isNotEmpty)        s += 5;
    if (_statusController.text.isNotEmpty)    s += 5;
    return s;
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
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const titles    = ['Basic Info', 'Professional', 'Interests'];
    const subtitles = [
      'Add your username and bio',
      'Tell us your role and skills',
      'Set interests and status',
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
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  fontFamily: 'Inter')),
          const SizedBox(height: 3),
          Text(subtitles[_currentStep],
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Inter')),
          const SizedBox(height: 20),
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
          _Label('Full Name'),
          _ReadOnly(value: widget.name),
          const SizedBox(height: 18),
          _Label('Username *'),
          _Input(
              controller: _usernameController,
              hint: 'e.g. fahad_dev',
              icon: Icons.alternate_email_rounded,
              prefix: '@'),
          const SizedBox(height: 5),
          const Text('Others can find you by username',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter')),
          const SizedBox(height: 18),
          _Label('Bio (Optional)'),
          _Input(
              controller: _bioController,
              hint: 'Flutter Developer | Building apps | Gym enthusiast',
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
          _Label('Role'),
          _ChipWrap(
            options   : _jobRoles,
            selected  : [_selectedJobRole],
            onTap     : (r) => setState(() => _selectedJobRole = r),
            multiSelect: false,
          ),
          const SizedBox(height: 18),
          _Label('Experience Level'),
          _ChipWrap(
            options   : _experienceLevels,
            selected  : [_selectedExperience],
            onTap     : (e) => setState(() => _selectedExperience = e),
            multiSelect: false,
          ),
          const SizedBox(height: 18),
          _Label('Skills'),
          _ChipWrap(
            options   : _skillOptions,
            selected  : _selectedSkills,
            onTap     : (s) => setState(() {
              _selectedSkills.contains(s)
                  ? _selectedSkills.remove(s)
                  : _selectedSkills.add(s);
            }),
            multiSelect: true,
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
          _Label('Interests'),
          _ChipWrap(
            options   : _interestOptions,
            selected  : _selectedInterests,
            onTap     : (i) => setState(() {
              _selectedInterests.contains(i)
                  ? _selectedInterests.remove(i)
                  : _selectedInterests.add(i);
            }),
            multiSelect: true,
          ),
          const SizedBox(height: 18),
          _Label('Current Status (Optional)'),
          _Input(
              controller: _statusController,
              hint: 'Building something awesome',
              icon: Icons.bolt_rounded),
          const SizedBox(height: 16),
          // Early adopter card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.rocket_launch_outlined,
                      color: AppColors.accent, size: 18),
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

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prev,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E1A),
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
              onTap: _isLoading ? null : _next,
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
                    _currentStep == 2 ? 'Get Started' : 'Next',
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
              onTap: _currentStep == 2 ? _save : _next,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Inter')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter')),
    );
  }
}

class _ReadOnly extends StatelessWidget {
  final String value;
  const _ReadOnly({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              color: AppColors.textMuted, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Inter')),
          ),
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.textMuted, size: 13),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String  hint;
  final IconData icon;
  final String? prefix;
  final int     maxLines;
  final int?    maxLength;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.prefix,
    this.maxLines  = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller : controller,
        maxLines   : maxLines,
        maxLength  : maxLength,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText : hint,
          hintStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 13, fontFamily: 'Inter'),
          prefixIcon: prefix != null
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 14),
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          counterStyle:
          const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final void Function(String) onTap;
  final bool multiSelect;

  const _ChipWrap({
    required this.options,
    required this.selected,
    required this.onTap,
    required this.multiSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return GestureDetector(
          onTap: () => onTap(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : const Color(0xFF0E0E1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(o,
                style: TextStyle(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontFamily: 'Inter')),
          ),
        );
      }).toList(),
    );
  }
}