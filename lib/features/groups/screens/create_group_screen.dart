import 'package:flutter/material.dart';
import 'package:flowva/core/constants/app_colors.dart';
import '../controllers/group_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String _selectedColor = '#00D4AA';

  final List<Map<String, dynamic>> _colorOptions = [
    {'hex': '#00D4AA', 'color': const Color(0xFF00D4AA), 'label': 'Teal'},
    {'hex': '#4A90FF', 'color': const Color(0xFF4A90FF), 'label': 'Blue'},
    {'hex': '#8B5CF6', 'color': const Color(0xFF8B5CF6), 'label': 'Purple'},
    {'hex': '#F59E0B', 'color': const Color(0xFFF59E0B), 'label': 'Amber'},
    {'hex': '#EF4444', 'color': const Color(0xFFEF4444), 'label': 'Red'},
    {'hex': '#22C55E', 'color': const Color(0xFF22C55E), 'label': 'Green'},
    {'hex': '#EC4899', 'color': const Color(0xFFEC4899), 'label': 'Pink'},
    {'hex': '#F97316', 'color': const Color(0xFFF97316), 'label': 'Orange'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Group name is required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await GroupController.instance.createGroup(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        color: _selectedColor,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Create Group',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Color Preview Circle ──
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorOptions.firstWhere(
                                (c) => c['hex'] == _selectedColor,
                          )['color'] as Color,
                          boxShadow: [
                            BoxShadow(
                              color: (_colorOptions.firstWhere(
                                    (c) => c['hex'] == _selectedColor,
                              )['color'] as Color).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Group Name ──
                    const Text(
                      'Group Name',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Design Team, Flutter Project...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.group_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Description ──
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What is this group about?',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(
                              Icons.notes_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Color Picker ──
                    const Text(
                      'Group Color',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colorOptions.map((option) {
                        final isSelected = _selectedColor == option['hex'];
                        return GestureDetector(
                          onTap: () => setState(
                                () => _selectedColor = option['hex'] as String,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: option['color'] as Color,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: (option['color'] as Color)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // ── Error Box ──
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Create Button ──
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading ? null : _createGroup,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Create Group',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}