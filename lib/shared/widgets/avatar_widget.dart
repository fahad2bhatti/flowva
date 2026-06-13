import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AvatarSize { xs, sm, md, lg, xl }

class FlowvaAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final AvatarSize size;
  final bool isOnline;
  final bool isVerified;

  const FlowvaAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AvatarSize.md,
    this.isOnline = false,
    this.isVerified = false,
  });

  double get _radius => switch (size) {
    AvatarSize.xs => 10,
    AvatarSize.sm => 16,
    AvatarSize.md => 22,
    AvatarSize.lg => 32,
    AvatarSize.xl => 48,
  };

  double get _fontSize => switch (size) {
    AvatarSize.xs => 8,
    AvatarSize.sm => 11,
    AvatarSize.md => 14,
    AvatarSize.lg => 18,
    AvatarSize.xl => 24,
  };

  Color _nameToColor(String name) {
    final colors = [
      const Color(0xFF4B5563),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: _radius,
          backgroundColor: _nameToColor(name),
          backgroundImage:
          imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _radius * 0.55,
              height: _radius * 0.55,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 1.5,
                ),
              ),
            ),
          ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _radius * 0.6,
              height: _radius * 0.6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: _radius * 0.35,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}