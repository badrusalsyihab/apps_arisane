import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignIn;
  const LoginScreen({super.key, required this.onSignIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: const Cubic(0.22, 1, 0.36, 1)));
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background orbs ──────────────────────────────────────────────
          _BackgroundOrbs(size: size),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 0 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo float
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: child,
                            ),
                            child: const _LogoMark(),
                          ),
                          const SizedBox(height: 40),

                          // Card
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eyebrow
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14B8A6).withValues(alpha:0.12),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: const Color(0xFF14B8A6).withValues(alpha:0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: const Text(
                                    'ARISAN DIGITAL · INDONESIA',
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF14B8A6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Headline
                                const Text(
                                  'Kelola arisan\nlebih mudah.',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Setoran, giliran, kas — semua tercatat rapi.\nTidak ada lagi grup WhatsApp yang berantakan.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white.withValues(alpha:0.45),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Divider
                                Row(children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha:0.08),
                                      thickness: 0.5,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Masuk dengan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha:0.3),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha:0.08),
                                      thickness: 0.5,
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 24),

                                // Google Button
                                _GoogleButton(
                                  onTap: widget.onSignIn,
                                ),

                                const SizedBox(height: 24),

                                // Footer
                                Center(
                                  child: Text(
                                    'Dengan masuk, kamu menyetujui Syarat & Ketentuan\ndan Kebijakan Privasi kami.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.white.withValues(alpha:0.22),
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Stats row
                          _StatsRow(fadeAnim: _fadeAnim),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background animated orbs ──────────────────────────────────────────────
class _BackgroundOrbs extends StatelessWidget {
  final Size size;
  const _BackgroundOrbs({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.15,
          left: -size.width * 0.2,
          child: _Orb(
            size: size.width * 0.85,
            color: const Color(0xFF0D9488).withValues(alpha:0.18),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.1,
          right: -size.width * 0.25,
          child: _Orb(
            size: size.width * 0.75,
            color: const Color(0xFF6366F1).withValues(alpha:0.12),
          ),
        ),
        Positioned(
          top: size.height * 0.4,
          left: size.width * 0.5,
          child: _Orb(
            size: size.width * 0.4,
            color: const Color(0xFF14B8A6).withValues(alpha:0.07),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─── Logo mark ────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Outer shell (double-bezel)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.08),
              width: 0.5,
            ),
            color: Colors.white.withValues(alpha:0.03),
          ),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha:0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'ArísanApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Glass card ───────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    // Outer shell
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha:0.12),
            Colors.white.withValues(alpha:0.03),
          ],
        ),
      ),
      // Inner core
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.5),
          color: const Color(0xFF0E1525).withValues(alpha:0.85),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.3),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Google Sign-In button ────────────────────────────────────────────────
class _GoogleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressing = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) {
          setState(() => _pressing = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressing = false),
        child: AnimatedScale(
          scale: _pressing ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: const Cubic(0.32, 0.72, 0, 1),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _hovering
                  ? Colors.white.withValues(alpha:0.1)
                  : Colors.white.withValues(alpha:0.06),
              border: Border.all(
                color: _hovering
                    ? Colors.white.withValues(alpha:0.2)
                    : Colors.white.withValues(alpha:0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google G logo
                _GoogleLogo(),
                const SizedBox(width: 12),
                const Text(
                  'Lanjutkan dengan Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                // Trailing icon pill (button-in-button pattern)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha:_hovering ? 0.12 : 0.06),
                  ),
                  child: Center(
                    child: AnimatedSlide(
                      offset: _hovering
                          ? const Offset(0.15, -0.15)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      curve: const Cubic(0.32, 0.72, 0, 1),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha:0.7),
                      ),
                    ),
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

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Google colors — simplified 4-arc approach
    final segments = [
      (const Color(0xFF4285F4), -math.pi / 6, math.pi / 2),
      (const Color(0xFF34A853), math.pi / 3, math.pi / 2),
      (const Color(0xFFFBBC05), math.pi * 5 / 6, math.pi / 2),
      (const Color(0xFFEA4335), math.pi * 4 / 3, math.pi / 2 + math.pi / 6),
    ];

    for (final (color, start, sweep) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        start,
        sweep,
        false,
        paint,
      );
    }

    // White center cutout for G shape suggestion
    final whitePaint = Paint()..color = Colors.transparent;
    canvas.drawCircle(center, radius * 0.38, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Stats row below card ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Animation<double> fadeAnim;
  const _StatsRow({required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Gratis', 'Mulai sekarang'),
      ('Aman', 'Google Auth'),
      ('Realtime', 'Firebase sync'),
    ];

    return FadeTransition(
      opacity: fadeAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i != 0)
              Container(
                width: 0.5,
                height: 28,
                color: Colors.white.withValues(alpha:0.1),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
            Column(
              children: [
                Text(
                  stats[i].$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats[i].$2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.35),
                    fontSize: 10.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
