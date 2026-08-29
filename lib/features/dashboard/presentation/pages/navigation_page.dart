// ============================================================================
// NAVIGATION PAGE - WITH SWIPE GESTURE
// ============================================================================
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/core/services/update_service.dart';
import 'package:yet_x_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:yet_x_app/features/dashboard/presentation/providers/ui_provider.dart';
import 'package:yet_x_app/features/feed/presentation/pages/explore_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/search_page.dart';
import 'package:yet_x_app/features/feels/presentation/pages/feels_page.dart';
import 'package:yet_x_app/features/gamification/presentation/providers/points_provider.dart';
import 'package:yet_x_app/features/profile/presentation/pages/profile_page.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/gamification/presentation/widgets/rank_up_dialog.dart';

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
  bool _isTabTapped = false;
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
    if (_selectedIndex == index) return;

    HapticFeedback.selectionClick();

    setState(() {
      _selectedIndex = index;
      _isTabTapped = true; // Geçiş süresince aradaki sekmeleri yoksayması için kilitliyoruz
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic, // Lense uygun daha yumuşak bir geçiş eğrisi
    ).then((_) {
      // Sayfa animasyonu bittiğinde kilidi aç
      if (mounted) {
        _isTabTapped = false;
      }
    });
  }

  void _onPageChanged(int index) {
    // Eğer sayfa değişimi kullanıcının alt bara tıklamasıyla tetiklendiyse,
    // aradaki sayfaların lensi şaşırtmasını engelle
    if (_isTabTapped) return;

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
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _navBarController,
      builder: (context, child) {
        // Küçülme (Scale) ve Aşağı Kayma (Translate) efekti
        return Transform.translate(
          offset: Offset(0, (_navBarHeight + 30) * (1 - _navBarController.value)),
          child: Transform.scale(
            scale: 0.9 + (0.1 * _navBarController.value), // Gizlenirken hafifçe küçülür
            child: Opacity(
                opacity: _navBarController.value,
                child: child
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: (theme.bottomAppBarTheme.color ?? theme.colorScheme.surface)
                    .withValues(alpha: isDark ? 0.65 : 0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: _buildLiquidNav(theme), // GNav yerine özel lensli yapı kullanıyoruz
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidNav(ThemeData theme) {
    final icons = [
      IconsaxPlusBold.home_hashtag,
      IconsaxPlusBold.monitor_mobbile,
      IconsaxPlusBold.message,
      IconsaxPlusBold.search_favorite_1,
      IconsaxPlusBold.profile,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / 5; // Genişliği 5 sekmeye bölüyoruz

        return Stack(
          children: [
            // Arka planda kayan Lens
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: _selectedIndex * tabWidth,
              top: 0,
              bottom: 0,
              width: tabWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            // İkonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTabChange(index),
                    child: Container(
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0, // Seçili ikon hafifçe büyür
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            icons[index],
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color?.withValues(alpha: 0.6),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
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

    ref.listen(uiProvider, (previous, next) {
      if (next) {
        _navBarController.forward();
      } else {
        _navBarController.reverse();
      }
    });

    ref.listen(pointsProvider, (previous, next) {
      if (previous != null &&
          previous.currentRank != null &&
          next.currentRank != null) {
        if (previous.currentRank!.id != next.currentRank!.id &&
            next.userPoints!.totalPoints > previous.userPoints!.totalPoints) {
          showRankUpDialog(context, previous.currentRank!, next.currentRank!);
        }
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
          extendBody: true,
          // Aşağı/yukarı kaydırma hareketlerini dinleyen yapı
          body: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              // Yalnızca dikey (iç sayfalardaki) kaydırmaları algıla, PageView'in yatay geçişlerini yoksay
              if (notification.metrics.axis == Axis.vertical) {
                if (notification.direction == ScrollDirection.reverse) {
                  // Ekranda aşağı inildiğinde nav barı gizle
                  if (_navBarController.isCompleted) _navBarController.reverse();
                } else if (notification.direction == ScrollDirection.forward) {
                  // Ekranda yukarı çıkıldığında nav barı göster
                  if (_navBarController.isDismissed) _navBarController.forward();
                }
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const _CustomPageScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildPage(index, currentUserId);
              },
            ),
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
