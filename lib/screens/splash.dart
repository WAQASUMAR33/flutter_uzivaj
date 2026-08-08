import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/screens/login.dart';
import '/screens/onboarding_screen.dart';
import '/screens/home.dart';
import '/services/userStorageService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Smiley: draws itself + soft fade ---
  late AnimationController _smileyController;
  late Animation<double> _smileyDraw; // 0 → 1 stroke progress
  late Animation<double> _smileyFade;

  // --- Logo: fade + gentle scale settle ---
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // --- Exit: whole screen fades out into next route ---
  late AnimationController _exitController;
  late Animation<double> _exitFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Smiley: 2000 ms — stroke traces on smoothly (easeInOut = natural draw)
    _smileyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _smileyDraw = CurvedAnimation(
      parent: _smileyController,
      curve: Curves.easeInOutCubic,
    );
    // Fade the smiley in fast over the first third so the draw feels alive
    _smileyFade = CurvedAnimation(
      parent: _smileyController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    // Logo: 650 ms — fade in + settle from a hair larger (0.94 → 1.0)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Exit: 500 ms — cross-fade the whole splash out before navigating
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    // Chain: smiley finishes → short beat → logo eases in
    _smileyController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 160), () {
          if (mounted) _logoController.forward();
        });
      }
    });

    // When logo settles → hold briefly → fade the whole screen out
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) _exitController.forward();
        });
      }
    });

    // Navigate exactly as the fade-out lands → seamless hand-off
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _go();
    });

    // Start the sequence
    _smileyController.forward();
  }

  Future<void> _go() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final storage = UserStorageService();
    final isLoggedIn = await storage.isLoggedIn();
    if (!mounted) return;

    Widget next;
    if (isLoggedIn) {
      next = const HomeScreen();
    } else {
      final onboardingDone = await storage.isOnboardingDone();
      if (!mounted) return;
      next = onboardingDone ? const LoginScreen() : const OnboardingScreen();
    }

    // Smooth fade route so the next screen eases in (no hard cut)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _smileyController.dispose();
    _logoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Apptheme.bluecolor,
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Step 1 — smiley draws itself stroke-by-stroke
              FadeTransition(
                opacity: _smileyFade,
                child: AnimatedBuilder(
                  animation: _smileyDraw,
                  builder: (_, __) => CustomPaint(
                    size: const Size(200, 120),
                    painter: SmileyPainter(
                      color: Apptheme.ambercolor,
                      progress: _smileyDraw.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Step 2 — logo fades in + settles after smiley is drawn
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/SVG/uzivaj_logo.png',
                    height: 120,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmileyPainter extends CustomPainter {
  final Color color;
  final double progress; // 0 → 1: how much of the smile is drawn

  SmileyPainter({required this.color, this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Thicker + more compact to match the brand smiley (the accent above the Z)
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.34
      ..strokeCap = StrokeCap.round;

    // Narrower horizontal span + deeper bowl = less long, more proportionate
    final path = Path();
    path.moveTo(size.width * 0.22, size.height * 0.40);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.92,
      size.width * 0.78,
      size.height * 0.40,
    );

    // Draw only the traced portion so the smile appears to be sketched on
    for (final metric in path.computeMetrics()) {
      final extracted = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SmileyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
