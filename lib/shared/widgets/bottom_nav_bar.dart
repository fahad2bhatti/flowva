import 'package:flutter/material.dart';
import 'package:flowva/core/constants/app_colors.dart';

// ─────────────────────────────────────────────
// NavItem Model
// ─────────────────────────────────────────────

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─────────────────────────────────────────────
// Bottom Nav Bar Widget
// ─────────────────────────────────────────────

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<NavItem> items = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.dynamic_feed_outlined,
      activeIcon: Icons.dynamic_feed_rounded,
      label: 'Feed',
    ),
    NavItem(
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
      label: 'Tasks',
    ),
    NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'AI',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          // Middle slot — FAB ke liye space
          if (i == 2) return const SizedBox(width: 56);

          final isSelected = selectedIndex == i;
          return _NavBarItem(
            item: items[i],
            isSelected: isSelected,
            onTap: () => onItemSelected(i),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single Nav Item
// ─────────────────────────────────────────────

class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.accent : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                fontSize: 10,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

