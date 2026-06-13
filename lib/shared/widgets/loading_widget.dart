import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum LoaderType { fullScreen, inline, overlay }

class FlowvaLoader extends StatelessWidget {
  final LoaderType type;
  final String? message;

  const FlowvaLoader({
    super.key,
    this.type = LoaderType.fullScreen,
    this.message,
  });

  const FlowvaLoader.inline({super.key})
      : type = LoaderType.inline,
        message = null;

  const FlowvaLoader.overlay({super.key, this.message})
      : type = LoaderType.overlay;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      LoaderType.fullScreen => _buildFullScreen(),
      LoaderType.inline     => _buildInline(),
      LoaderType.overlay    => _buildOverlay(),
    };
  }

  Widget _buildFullScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.5,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInline() {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}