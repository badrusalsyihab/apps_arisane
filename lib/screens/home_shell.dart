import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  final String userId;
  const HomeShell({super.key, required this.userId});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  static const _green = Color(0xFF00A884);
  static const _darkBar = Color(0xFF1F2C34);
  static const _titles = ['ArisanApp', 'Notifikasi', 'Profil'];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(userId: widget.userId),
      NotificationsScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  void _onTap(int i) {
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: _darkBar,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: _darkBar,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            color: _green,
            letterSpacing: 0.1,
          ),
        ),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 22),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _ElegantBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Elegant bottom nav ───────────────────────────────────────────────────
class _ElegantBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ElegantBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    _NavDest(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    _NavDest(
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
      label: 'Notifikasi',
    ),
    _NavDest(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(
                child: _NavItem(
                  dest: _items[i],
                  selected: i == selectedIndex,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDest({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─── Individual nav item ──────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final _NavDest dest;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pillWidth;
  late final Animation<double> _iconScale;

  static const _green = Color(0xFF00A884);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.selected ? 1.0 : 0.0,
    );
    _pillWidth = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: const Cubic(0.34, 1.56, 0.64, 1)),
    );
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated pill indicator
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Container(
                height: 32,
                width: 56,
                decoration: BoxDecoration(
                  color: ColorTween(
                    begin: Colors.transparent,
                    end: _green.withValues(alpha: 0.12),
                  ).evaluate(_pillWidth),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: _iconScale.value,
                    child: Icon(
                      widget.selected
                          ? widget.dest.activeIcon
                          : widget.dest.icon,
                      size: 22,
                      color: widget.selected
                          ? _green
                          : const Color(0xFF667781),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.w400,
              color: widget.selected ? _green : const Color(0xFF667781),
              letterSpacing: 0.1,
            ),
            child: Text(widget.dest.label),
          ),
        ],
      ),
    );
  }
}
