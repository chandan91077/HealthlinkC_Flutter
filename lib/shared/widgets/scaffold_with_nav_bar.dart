import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    required this.branchNavigatorKeys,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;
  final List<GlobalKey<NavigatorState>> branchNavigatorKeys;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  final List<int> _tabHistory = <int>[];
  DateTime? _lastExitAttemptAt;
  static const Duration _exitConfirmWindow = Duration(seconds: 2);

  Future<void> _onBackPressed() async {
    final int currentIndex = widget.navigationShell.currentIndex;
    final NavigatorState? currentBranchNavigator =
        widget.branchNavigatorKeys[currentIndex].currentState;

    // 1) Pop inside the currently selected tab first.
    if (currentBranchNavigator != null) {
      final didPopInTab = await currentBranchNavigator.maybePop();
      if (didPopInTab) {
        return;
      }
    }

    // 2) If this tab has no more pages, switch to the previous visited tab.
    if (_tabHistory.isNotEmpty) {
      final int previousTab = _tabHistory.removeLast();
      widget.navigationShell.goBranch(previousTab);
      return;
    }

    // 3) Fall back to home tab before exiting.
    if (currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    // 4) Confirm exit when already at home root.
    final now = DateTime.now();
    final recentAttempt = _lastExitAttemptAt != null &&
        now.difference(_lastExitAttemptAt!) <= _exitConfirmWindow;

    if (recentAttempt) {
      await SystemNavigator.pop();
      return;
    }

    _lastExitAttemptAt = now;
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Press again to exit app'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onBackPressed();
        }
      },
      child: Scaffold(
        appBar: const MediConnectHeader(),
        drawer: const MediConnectDrawer(),
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BottomNavigationBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: _onTap,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: const Color(0xFF64748B),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today_rounded),
                  label: 'Appointments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search_rounded),
                  label: 'Find Doctor',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    final int currentIndex = widget.navigationShell.currentIndex;
    if (index != currentIndex) {
      if (_tabHistory.isEmpty || _tabHistory.last != currentIndex) {
        _tabHistory.add(currentIndex);
      }
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == currentIndex,
    );
  }
}
