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
  // Main entrance animation controller (smiley down + logo up into center)
  late AnimationController _entranceController;
  late Animation<Offset> _smileySlide;
  late Animation<double> _smileyFade;
  late Animation<double> _smileyDraw;

  late Animation<Offset> _logoSlide;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Exit transition controller (screen fade out)
  late AnimationController _exitController;
  late Animation<double> _exitFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (1100ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Smiley icon glides down from the TOP into center
    _smileySlide = Tween<Offset>(
      begin: const Offset(0.0, -2.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _smileyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _smileyDraw = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.95, curve: Curves.easeInOutCubic),
    );

    // Uživaj logo glides up from the BOTTOM into center
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, 2.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 2. Exit transition (450ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    // Sequence: Entrance finishes -> hold briefly -> trigger exit fade out
    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 750), () {
          if (mounted) _exitController.forward();
        });
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _go();
      }
    });

    // Start entrance animation
    _entranceController.forward();
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
    _entranceController.dispose();
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Smiley icon: slides from top to center
              SlideTransition(
                position: _smileySlide,
                child: FadeTransition(
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
              ),
              const SizedBox(height: 28),
              // Uživaj logo: slides from bottom to center
              SlideTransition(
                position: _logoSlide,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      'assets/SVG/uzivaj_logo.png',
                      height: 120,
                    ),
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
