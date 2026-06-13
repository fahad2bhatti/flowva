import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ButtonVariant { primary, secondary, danger, ghost, ai }
enum ButtonSize { small, medium, large }

class FlowvaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? prefixIcon;
  final double? width;

  const FlowvaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.prefixIcon,
    this.width,
  });

  double get _height => switch (size) {
    ButtonSize.small  => 36,
    ButtonSize.medium => 44,
    ButtonSize.large  => 52,
  };

  double get _fontSize => switch (size) {
    ButtonSize.small  => 13,
    ButtonSize.medium => 14,
    ButtonSize.large  => 16,
  };

  Color get _bgColor => switch (variant) {
    ButtonVariant.primary   => AppColors.accent,
    ButtonVariant.secondary => Colors.transparent,
    ButtonVariant.danger    => AppColors.error,
    ButtonVariant.ghost     => Colors.transparent,
    ButtonVariant.ai        => const Color(0xFF8B5CF6),
  };

  Color get _textColor => switch (variant) {
    ButtonVariant.primary   => Colors.white,
    ButtonVariant.secondary => AppColors.accent,
    ButtonVariant.danger    => Colors.white,
    ButtonVariant.ghost     => AppColors.textSecondary,
    ButtonVariant.ai        => Colors.white,
  };

  Border? get _border => switch (variant) {
    ButtonVariant.secondary => Border.all(color: AppColors.accent, width: 1),
    ButtonVariant.ghost     => Border.all(color: AppColors.border, width: 1),
    _                       => null,
  };

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedScale(
        scale: isDisabled ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: width,
            height: _height,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: _border,
              boxShadow: variant == ButtonVariant.primary || variant == ButtonVariant.ai
                  ? [
                BoxShadow(
                  color: _bgColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _textColor,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon, size: _fontSize + 2, color: _textColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                      letterSpacing: 0.2,
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
}