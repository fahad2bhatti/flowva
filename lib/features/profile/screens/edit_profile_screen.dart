import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();

  String _selectedJobRole = '';
  String _selectedExperience = '';
  final List<String> _selectedSkills = [];
  final List<String> _selectedInterests = [];

  bool _isLoading = false;
  bool _isFetching = true;

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
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final uid = ProfileController.instance.currentUserId;
    if (uid == null) return;
    final user = await ProfileController.instance.getUserById(uid);
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.name;
        _usernameController.text = user.username;
        _bioController.text = user.bio;
        _statusController.text = user.currentStatus;
        _selectedJobRole = user.jobRole;
        _selectedExperience = user.experienceLevel;
        _selectedSkills.addAll(user.skills);
        _selectedInterests.addAll(user.interests);
        _isFetching = false;
      });
    } else {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name required hai');
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showError('Username required hai');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Username availability check
      final available = await ProfileController.instance
          .isUsernameAvailable(_usernameController.text.trim());
      if (!available) {
        _showError('Username already taken hai — koi aur try karo');
        return;
      }

      await ProfileController.instance.updateProfile({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'currentStatus': _statusController.text.trim(),
        'jobRole': _selectedJobRole,
        'experienceLevel': _selectedExperience,
        'skills': _selectedSkills,
        'interests': _selectedInterests,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            )
                : const Text('Save',
                style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Inter')),
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info
            _SectionHeader(title: 'Basic Info'),
            _Field(controller: _nameController, label: 'Full Name', icon: Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _Field(controller: _usernameController, label: 'Username', icon: Icons.alternate_email_rounded, prefix: '@'),
            const SizedBox(height: 12),
            _Field(controller: _bioController, label: 'Bio', icon: Icons.edit_note_rounded, maxLines: 3, maxLength: 120),
            const SizedBox(height: 12),
            _Field(controller: _statusController, label: 'Current Status', icon: Icons.bolt_rounded),

            const SizedBox(height: 24),

            // Professional
            _SectionHeader(title: 'Professional'),
            const _Label(text: 'Role'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobRoles.map((r) => _Chip(
                label: r,
                isSelected: _selectedJobRole == r,
                onTap: () => setState(() => _selectedJobRole = r),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const _Label(text: 'Experience Level'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _experienceLevels.map((e) => _Chip(
                label: e,
                isSelected: _selectedExperience == e,
                onTap: () => setState(() => _selectedExperience = e),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const _Label(text: 'Skills'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillOptions.map((s) => _Chip(
                label: s,
                isSelected: _selectedSkills.contains(s),
                onTap: () => setState(() {
                  _selectedSkills.contains(s)
                      ? _selectedSkills.remove(s)
                      : _selectedSkills.add(s);
                }),
              )).toList(),
            ),

            const SizedBox(height: 24),

            // Interests
            _SectionHeader(title: 'Interests'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interestOptions.map((i) => _Chip(
                label: i,
                isSelected: _selectedInterests.contains(i),
                onTap: () => setState(() {
                  _selectedInterests.contains(i)
                      ? _selectedInterests.remove(i)
                      : _selectedInterests.add(i);
                }),
              )).toList(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter')),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter'));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? prefix;
  final int maxLines;
  final int? maxLength;

  const _Field({
    required this.controller,
    required this.label,
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
            color: AppColors.textPrimary, fontSize: 14, fontFamily: 'Inter'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter'),
          prefixIcon: prefix != null
              ? Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 6),
                Text(prefix!,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter')),
              ],
            ),
          )
              : Icon(icon, color: AppColors.textMuted, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        child: Text(label,
            style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'Inter')),
      ),
    );
  }
}