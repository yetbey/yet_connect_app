// ============================================================================
// NAVIGATION PAGE - WITH SWIPE GESTURE
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/core/services/update_service.dart';
import 'package:yet_x_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:yet_x_app/features/dashboard/presentation/providers/ui_provider.dart';
import 'package:yet_x_app/features/feed/presentation/pages/explore_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/search_page.dart';
import 'package:yet_x_app/features/feels/presentation/pages/feels_page.dart';
import 'package:yet_x_app/features/profile/presentation/pages/profile_page.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';

class NavigationPage extends ConsumerStatefulWidget {
  const NavigationPage({super.key});

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage>
    with SingleTickerProviderStateMixin {
  // ============================================================================
  // STATE & CONSTANTS
  // ============================================================================
  int _selectedIndex = 0;
  final Map<int, Widget> _pageCache = {};
  late AnimationController _navBarController;
  late PageController _pageController;
  static const double _navBarHeight = kBottomNavigationBarHeight + 20;
  static const Duration _animationDuration = Duration(milliseconds: 250);

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================
  @override
  void initState() {
    super.initState();

    // Initialize page controller
    _pageController = PageController(initialPage: 0);

    // Initialize navigation bar animation controller
    _navBarController = AnimationController(
      vsync: this,
      duration: _animationDuration,
      value: 1.0,
    );

    // Check for app updates after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForMajorUpdate(context);
    });
  }

  @override
  void dispose() {
    _navBarController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================================
  // PAGE MANAGEMENT
  // ============================================================================
  Widget _buildPage(int index, String? userId) {
    // Return cached page if available and not Profile tab
    if (index != 4 && _pageCache.containsKey(index)) {
      return _pageCache[index]!;
    }

    // Build the page based on index
    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const FeelsPage();
        break;
      case 2:
        page = const ChatListPage();
        break;
      case 3:
        page = const SearchPage();
        break;
      case 4:
        // Profile page requires userId and is not cached
        page = ProfilePage(userId: userId);
        break;
      default:
        page = const HomePage();
    }

    // Cache the page if it's not Profile tab
    if (index != 4) {
      _pageCache[index] = page;
    }

    return page;
  }

  // ============================================================================
  // NAVIGATION HANDLERS
  // ============================================================================
  void _onTabChange(int index) {
    // Prevent rebuilding if same tab is tapped
    if (_selectedIndex == index) return;

    // Provide haptic feedback for better UX
    HapticFeedback.selectionClick();

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Update selected index
    setState(() => _selectedIndex = index);
  }

  void _onPageChanged(int index) {
    // Update selected index when swiping
    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _selectedIndex = index);
    }
  }

  void _handleBackPress(bool didPop) {
    // If already popped, return early
    if (didPop) return;

    // If keyboard is open, dismiss it
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      return;
    }

    // If not on home tab, navigate to home
    if (_selectedIndex != 0) {
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _selectedIndex = 0);
      return;
    }

    // Exit the app
    SystemNavigator.pop();
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================
  Widget _buildBottomNavBar(ThemeData theme, bool isNavBarVisible) {
    return AnimatedBuilder(
      animation: _navBarController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _navBarHeight * (1 - _navBarController.value)),
          child: Opacity(opacity: _navBarController.value, child: child),
        );
      },
      child: Container(
        height: _navBarHeight,
        decoration: BoxDecoration(
          color: theme.bottomAppBarTheme.color ?? theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
            child: _buildGNav(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildGNav(ThemeData theme) {
    return GNav(
      curve: Curves.easeInOutCubic,
      rippleColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
      hoverColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
      haptic: true,
      tabBorderRadius: 16,
      tabBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      duration: const Duration(milliseconds: 350),
      gap: 8,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: theme.iconTheme.color?.withValues(alpha: 0.5),
      activeColor: theme.colorScheme.primary,
      iconSize: 32,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
      tabs: _buildNavItems(),
      selectedIndex: _selectedIndex,
      onTabChange: _onTabChange,
    );
  }

  List<GButton> _buildNavItems() {
    return [
      const GButton(icon: IconsaxPlusBold.home_hashtag),
      const GButton(icon: IconsaxPlusBold.monitor_mobbile),
      const GButton(icon: IconsaxPlusBold.message),
      const GButton(icon: IconsaxPlusBold.search_favorite_1),
      const GButton(icon: IconsaxPlusBold.profile),
    ];
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNavBarVisible = ref.watch(uiProvider);
    final currentUserId = ref.watch(
      userProvider.select((state) => state.currentUser?.id),
    );

    // Listen to navigation bar visibility changes and animate accordingly
    ref.listen(uiProvider, (previous, next) {
      if (next) {
        _navBarController.forward();
      } else {
        _navBarController.reverse();
      }
    });

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        _handleBackPress(didPop);
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          body: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const _CustomPageScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildPage(index, currentUserId);
            },
          ),
          bottomNavigationBar: _buildBottomNavBar(theme, isNavBarVisible),
        ),
      ),
    );
  }
}

/// Custom scroll physics that prevents overscroll at boundaries
/// but allows smooth scrolling between pages
class _CustomPageScrollPhysics extends ScrollPhysics {
  const _CustomPageScrollPhysics({super.parent});

  @override
  _CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Prevent overscroll at the start (first page)
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    // Prevent overscroll at the end (last page)
    if (value > position.pixels &&
        position.pixels >= position.maxScrollExtent) {
      return value - position.pixels;
    }
    // Allow normal scrolling between pages
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Use page-snapping behavior
    final tolerance = toleranceFor(position);
    if (position.outOfRange) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }
      if (end != null) {
        return ScrollSpringSimulation(
          spring,
          position.pixels,
          end,
          velocity,
          tolerance: tolerance,
        );
      }
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
