import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_math_with_ai/app/theme.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/core/widgets/double_back_exit_scope.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    this.nowProvider,
  });

  final Widget child;
  final DateTime Function()? nowProvider;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    if (widget.nowProvider != null) {
      DoubleBackExitService.instance.nowProvider = widget.nowProvider;
    }
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nowProvider != null) {
      DoubleBackExitService.instance.nowProvider = widget.nowProvider;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/practice')) return 1;
      if (location.startsWith('/stats')) return 2;
      if (location.startsWith('/report')) return 3;
      if (location.startsWith('/settings')) return 4;
    } catch (_) {}
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    DoubleBackExitService.instance.reset();
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/practice');
        break;
      case 2:
        context.go('/stats');
        break;
      case 3:
        context.go('/report');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nowProvider != null) {
      DoubleBackExitService.instance.nowProvider = widget.nowProvider;
    }
    final selectedIndex = _calculateSelectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        DoubleBackExitService.instance.handleBackPress(context);
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (notification) {
          // When the inner navigator (_shellNavigatorKey) has only 1 route, it dispatches
          // canHandlePop: false. We intercept this so that Android does not disable
          // framework back handling and kill the app.
          if (!notification.canHandlePop) {
            const NavigationNotification(canHandlePop: true).dispatch(context);
            return true;
          }
          return false;
        },
        child: Scaffold(
          backgroundColor: AppTheme.canvasBackground,
          body: SafeArea(
            top: true,
            bottom: false,
            child: widget.child,
          ),
          bottomNavigationBar: _AnimatedPillBottomNavBar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) => _onDestinationSelected(context, index),
            items: const [
            _NavBarItemData(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: AppStrings.tabHome,
            ),
            _NavBarItemData(
              icon: Icons.calculate_outlined,
              selectedIcon: Icons.calculate_rounded,
              label: AppStrings.tabPractice,
            ),
            _NavBarItemData(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart_rounded,
              label: AppStrings.tabStats,
            ),
            _NavBarItemData(
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights_rounded,
              label: AppStrings.tabReport,
            ),
            _NavBarItemData(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: AppStrings.tabSettings,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavBarItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavBarItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _AnimatedPillBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<_NavBarItemData> items;

  const _AnimatedPillBottomNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = selectedIndex == index;
              final item = items[index];

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onItemSelected(index),
                    splashColor: AppTheme.primaryTint.withValues(alpha: 0.5),
                    highlightColor: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryTint
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
