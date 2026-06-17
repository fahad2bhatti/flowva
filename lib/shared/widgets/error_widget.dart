import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'custom_button.dart';

// ─────────────────────────────────────────────
// Error Types
// ─────────────────────────────────────────────

enum FlowvaErrorType {
  network,
  firebase,
  auth,
  notFound,
  permission,
  unknown,
  crash,
}

// ─────────────────────────────────────────────
// Main Error Widget
// ─────────────────────────────────────────────

class FlowvaErrorWidget extends StatefulWidget {
  final FlowvaErrorType type;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool fullScreen;

  const FlowvaErrorWidget({
    super.key,
    this.type = FlowvaErrorType.unknown,
    this.title,
    this.message,
    this.onRetry,
    this.fullScreen = false,
  });

  // Named constructors for quick use
  const FlowvaErrorWidget.network({
    super.key,
    this.onRetry,
    this.fullScreen = false,
  })  : type = FlowvaErrorType.network,
        title = 'No Internet Connection',
        message = 'Check your connection and try again.';

  const FlowvaErrorWidget.firebase({
    super.key,
    this.onRetry,
    this.fullScreen = false,
  })  : type = FlowvaErrorType.firebase,
        title = 'Failed to Load',
        message = 'Could not fetch data. Please try again.';

  const FlowvaErrorWidget.auth({
    super.key,
    this.onRetry,
    this.fullScreen = false,
  })  : type = FlowvaErrorType.auth,
        title = 'Session Expired',
        message = 'Please log in again to continue.';

  const FlowvaErrorWidget.notFound({
    super.key,
    this.onRetry,
    this.fullScreen = false,
  })  : type = FlowvaErrorType.notFound,
        title = 'Not Found',
        message = 'This content no longer exists.';

  const FlowvaErrorWidget.permission({
    super.key,
    this.onRetry,
    this.fullScreen = false,
  })  : type = FlowvaErrorType.permission,
        title = 'Access Denied',
        message = 'You don\'t have permission to view this.';

  const FlowvaErrorWidget.crash({
    super.key,
    this.onRetry,
    this.fullScreen = false,
  })  : type = FlowvaErrorType.crash,
        title = 'Something Crashed',
        message = 'An unexpected error occurred. We\'re on it!';

  @override
  State<FlowvaErrorWidget> createState() => _FlowvaErrorWidgetState();
}

class _FlowvaErrorWidgetState extends State<FlowvaErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController, curve: Curves.easeOutBack),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Error Config
  // ─────────────────────────────────────────────

  _ErrorConfig get _config => switch (widget.type) {
    FlowvaErrorType.network => _ErrorConfig(
      icon: Icons.wifi_off_rounded,
      color: const Color(0xFF6366F1),
      bgColor: const Color(0xFF6366F1),
      emoji: '📡',
    ),
    FlowvaErrorType.firebase => _ErrorConfig(
      icon: Icons.cloud_off_rounded,
      color: const Color(0xFFFFB347),
      bgColor: const Color(0xFFFFB347),
      emoji: '☁️',
    ),
    FlowvaErrorType.auth => _ErrorConfig(
      icon: Icons.lock_outline_rounded,
      color: const Color(0xFF8B5CF6),
      bgColor: const Color(0xFF8B5CF6),
      emoji: '🔐',
    ),
    FlowvaErrorType.notFound => _ErrorConfig(
      icon: Icons.search_off_rounded,
      color: const Color(0xFF14B8A6),
      bgColor: const Color(0xFF14B8A6),
      emoji: '🔍',
    ),
    FlowvaErrorType.permission => _ErrorConfig(
      icon: Icons.block_rounded,
      color: AppColors.warning,
      bgColor: AppColors.warning,
      emoji: '🚫',
    ),
    FlowvaErrorType.crash => _ErrorConfig(
      icon: Icons.bug_report_rounded,
      color: AppColors.error,
      bgColor: AppColors.error,
      emoji: '💥',
    ),
    FlowvaErrorType.unknown => _ErrorConfig(
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
      bgColor: AppColors.error,
      emoji: '⚠️',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final title = widget.title ?? 'Something went wrong';
    final message = widget.message;

    final content = FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
            widget.fullScreen ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Animated icon container
              ScaleTransition(
                scale: _scaleAnim,
                child: _buildIconContainer(cfg),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Buttons
              if (widget.onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: FlowvaButton(
                    label: 'Try Again',
                    onPressed: widget.onRetry,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    prefixIcon: Icons.refresh_rounded,
                  ),
                ),

              if (widget.type == FlowvaErrorType.auth) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FlowvaButton(
                    label: 'Go to Login',
                    onPressed: () =>
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/auth/login',
                              (route) => false,
                        ),
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.large,
                    prefixIcon: Icons.login_rounded,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }

  Widget _buildIconContainer(_ErrorConfig cfg) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cfg.bgColor.withValues(alpha: 0.06),
            border: Border.all(
              color: cfg.bgColor.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
        ),
        // Inner circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cfg.bgColor.withValues(alpha: 0.12),
            border: Border.all(
              color: cfg.bgColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              cfg.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Inline Error Banner (for inside screens)
// ─────────────────────────────────────────────

class FlowvaErrorBanner extends StatelessWidget {
  final String message;
  final FlowvaErrorType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const FlowvaErrorBanner({
    super.key,
    required this.message,
    this.type = FlowvaErrorType.unknown,
    this.onDismiss,
    this.onRetry,
  });

  Color get _color => switch (type) {
    FlowvaErrorType.network   => const Color(0xFF6366F1),
    FlowvaErrorType.firebase  => const Color(0xFFFFB347),
    FlowvaErrorType.auth      => const Color(0xFF8B5CF6),
    FlowvaErrorType.permission => AppColors.warning,
    _                         => AppColors.error,
  };

  IconData get _icon => switch (type) {
    FlowvaErrorType.network   => Icons.wifi_off_rounded,
    FlowvaErrorType.firebase  => Icons.cloud_off_rounded,
    FlowvaErrorType.auth      => Icons.lock_outline_rounded,
    FlowvaErrorType.permission => Icons.block_rounded,
    _                         => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: _color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  color: _color,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _color,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded,
                  color: _color, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Crash Screen (full screen — for app crashes)
// ─────────────────────────────────────────────

class FlowvaCrashScreen extends StatelessWidget {
  final String? error;
  final VoidCallback? onRestart;

  const FlowvaCrashScreen({
    super.key,
    this.error,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Big emoji
                const Text('💥', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                const Text(
                  'Oops! App crashed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Something unexpected happened.\nDon\'t worry, we\'re already on it!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FlowvaButton(
                    label: 'Restart App',
                    onPressed: onRestart,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    prefixIcon: Icons.refresh_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Snackbar Helper
// ─────────────────────────────────────────────

class FlowvaSnackbar {
  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Private config class
// ─────────────────────────────────────────────

class _ErrorConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String emoji;

  const _ErrorConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.emoji,
  });
}