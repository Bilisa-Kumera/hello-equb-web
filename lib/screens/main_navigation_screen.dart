import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/provider/joined_equbs_status_provider.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/screens/profile_screen.dart';
import 'package:helloequb/utils/custom_bottom_nav.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _navBarVisible = true;
  bool? _lastShowMyEqub;

  @override
  void initState() {
    super.initState();
    final showMyEqub =
        DataController().retrieveData<bool>('hasJoinedEqubs') ?? false;
    _lastShowMyEqub = showMyEqub;
    _currentIndex = widget.initialIndex.clamp(0, showMyEqub ? 2 : 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<JoinedEqubsStatusProvider>();
      provider.refresh();
      if (!kIsWeb) {
        provider.startApprovalWatch();
      }
    });
  }

  void _setNavBarVisible(bool visible) {
    if (_navBarVisible == visible) return;
    setState(() => _navBarVisible = visible);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      if (notification.metrics.pixels <= 0) {
        _setNavBarVisible(true);
      } else if (delta > 2) {
        _setNavBarVisible(false);
      } else if (delta < -2) {
        _setNavBarVisible(true);
      }
    }

    return false;
  }

  int _resolveStackIndex(bool showMyEqub, int pageCount) {
    if (pageCount <= 0) return 0;

    final maxIndex = pageCount - 1;

    if (_lastShowMyEqub != null && _lastShowMyEqub != showMyEqub) {
      final wasShowing = _lastShowMyEqub!;
      if (showMyEqub && !wasShowing) {
        return (_currentIndex + 1).clamp(0, maxIndex);
      }
      if (!showMyEqub && wasShowing) {
        return _currentIndex == 0 ? 0 : (_currentIndex - 1).clamp(0, maxIndex);
      }
    }

    return _currentIndex.clamp(0, maxIndex);
  }

  void _handleJoinStatusChange(bool showMyEqub) {
    if (!mounted || _lastShowMyEqub == showMyEqub) return;

    final wasShowing = _lastShowMyEqub ?? false;
    _lastShowMyEqub = showMyEqub;

    final int newIndex;
    if (showMyEqub && !wasShowing) {
      // My Equb tab inserted at index 0 — keep the same visible screen.
      newIndex = (_currentIndex + 1).clamp(0, 2);
    } else if (!showMyEqub && wasShowing) {
      newIndex = _currentIndex == 0
          ? 0
          : (_currentIndex - 1).clamp(0, 1);
    } else {
      newIndex = _currentIndex.clamp(0, showMyEqub ? 2 : 1);
    }

    setState(() {
      _currentIndex = newIndex;
      _navBarVisible = true;
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    _setNavBarVisible(true);
    setState(() => _currentIndex = index);
  }

  List<Widget> _buildPages(bool showMyEqub) {
    if (showMyEqub) {
      return const [
        ActiveEqubsScreen(embedInShell: true),
        HomeScreen(embedInShell: true),
        ProfileScreen(embedInShell: true),
      ];
    }

    return const [
      HomeScreen(embedInShell: true),
      ProfileScreen(embedInShell: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinedEqubsStatusProvider>(
      builder: (context, joinStatus, _) {
        final showMyEqub = joinStatus.hasJoinedEqubs;

        final pages = _buildPages(showMyEqub);
        final stackIndex = _resolveStackIndex(showMyEqub, pages.length);

        if (_lastShowMyEqub != showMyEqub) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleJoinStatusChange(showMyEqub);
          });
        }

        return PopScope(
          canPop: stackIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && stackIndex != 0) {
              _onTabTapped(0);
            }
          },
          child: Scaffold(
            extendBody: true,
            body: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: IndexedStack(
                index: stackIndex,
                children: pages,
              ),
            ),
            bottomNavigationBar: IgnorePointer(
              ignoring: !_navBarVisible,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                offset: _navBarVisible ? Offset.zero : const Offset(0, 1.5),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _navBarVisible ? 1 : 0,
                  child: CustomBottomNavigationBar(
                    showMyEqubTab: showMyEqub,
                    currentIndex: stackIndex,
                    onTap: _onTabTapped,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
