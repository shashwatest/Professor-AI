import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'current_session_screen.dart';
import 'session_history_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Home',
      title: 'Home',
    ),
    NavigationItem(
      icon: Icons.mic,
      label: 'Current Session',
      title: 'Current Session',
    ),
    NavigationItem(
      icon: Icons.history,
      label: 'Session History',
      title: 'Session History',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      title: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    
    if (_isSidebarOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
      // Always close sidebar when selecting an item on all devices
      _isSidebarOpen = false;
    });
    _sidebarController.reverse();
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = false;
      });
      _sidebarController.reverse();
    }
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(
          onStartRecording: () => _selectItem(1),
          onUploadDocument: () => _selectItem(1),
          onViewHistory: () => _selectItem(2),
          onOpenSettings: () => _selectItem(3),
        );
      case 1:
        return CurrentSessionScreen(
          onNavigateToSettings: () => _selectItem(3),
        );
      case 2:
        return SessionHistoryScreen(
          aiService: null, // Will be handled in the screen
          educationLevel: 'Undergraduate', // Will be loaded from settings
        );
      case 3:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    // Close sidebar when switching from mobile to desktop or vice versa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDesktop && _isSidebarOpen) {
        // On mobile/tablet, ensure sidebar can be closed
      }
    });

    return Scaffold(
      // Add keyboard listener for Escape key
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey.keyLabel == 'Escape' && _isSidebarOpen) {
            _closeSidebar();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: _buildBody(context, isDesktop),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
              Theme.of(context).colorScheme.secondary.withOpacity(0.03),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.all(0), // No margin needed since sidebar is now overlay
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(child: _buildCurrentScreen()),
                ],
              ),
            ),
            
            // Overlay - must be above main content but below sidebar
            if (_isSidebarOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSidebar,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _sidebarAnimation,
                    builder: (context, child) {
                      return Container(
                        color: Colors.black.withOpacity(
                          isDesktop 
                            ? 0.1 * _sidebarAnimation.value  // Lighter overlay for desktop
                            : 0.3 * _sidebarAnimation.value  // Darker overlay for mobile
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Sidebar - must be on top
            if (_isSidebarOpen)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(isDesktop ? 0 : -280 * (1 - _sidebarAnimation.value), 0),
                      child: _buildSidebar(context, isDesktop),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleSidebar,
            icon: AnimatedRotation(
              turns: _isSidebarOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.menu),
            ),
            tooltip: 'Toggle Navigation',
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.school,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _navigationItems[_selectedIndex].title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (MediaQuery.of(context).size.width > 600)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    return Container(
      width: 280,
      height: double.infinity,
      child: GlassContainer(
        margin: EdgeInsets.only(
          top: 16,
          left: 16,
          bottom: 16,
          right: isDesktop ? 0 : 16,
        ),
        child: Column(
          children: [
            // Sidebar Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Classroom Edition',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final isSelected = _selectedIndex == index;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectItem(index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                size: 20,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms);
                },
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'v1.0.0 • Made with ❤️',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String title;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.title,
  });
}