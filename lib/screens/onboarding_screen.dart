import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/theme/app_theme.dart';
import '/screens/login.dart';
import '/services/userStorageService.dart';
import '/providers/locale_provider.dart';
import '/l10n/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  /// First-launch flow → navigates to Login when finished.
  /// Replay (opened from Profile → Help) → just pops back.
  final bool replay;
  const OnboardingScreen({super.key, this.replay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Replay from Help: just close, don't touch first-launch flow.
    if (widget.replay) {
      if (mounted) Navigator.pop(context);
      return;
    }
    await UserStorageService().setOnboardingDone();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Scaffold(
      backgroundColor: Apptheme.bluecolor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _OnboardingPage(
                topContent: const _Slide1Top(),
                title: l.onboarding1Title,
                description: l.onboarding1Desc,
                currentPage: _currentPage,
                onNext: _next,
                isLast: false,
                nextLabel: l.next,
              ),
              _OnboardingPage(
                topContent: _Slide2Top(l: l),
                title: l.onboarding2Title,
                description: l.onboarding2Desc,
                currentPage: _currentPage,
                onNext: _next,
                isLast: false,
                nextLabel: l.next,
              ),
              _OnboardingPage(
                topContent: _Slide3Top(l: l),
                title: l.onboarding3Title,
                description: l.onboarding3Desc,
                currentPage: _currentPage,
                onNext: _next,
                isLast: true,
                nextLabel: l.startExploring,
              ),
            ],
          ),
          // Skip + Language row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _OnboardingLangToggle(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      l.skip,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language toggle for onboarding ───────────────────────────────────────────

class _OnboardingLangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final isEN = provider.isEnglish;
    return TextButton.icon(
      onPressed: () => provider.toggleLocale(),
      icon: const Icon(Icons.language, color: Colors.white70, size: 16),
      label: Text(
        isEN ? 'EN' : 'HR',
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Shared page template ──────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final Widget topContent;
  final String title;
  final String description;
  final int currentPage;
  final VoidCallback onNext;
  final bool isLast;
  final String nextLabel;

  const _OnboardingPage({
    required this.topContent,
    required this.title,
    required this.description,
    required this.currentPage,
    required this.onNext,
    required this.isLast,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(child: SafeArea(bottom: false, child: topContent)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(3, (i) {
                  final active = i == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Apptheme.bluecolor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.55),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Apptheme.bluecolor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    nextLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Slide 1 top — Logo ────────────────────────────────────────────────────────

class _Slide1Top extends StatelessWidget {
  const _Slide1Top();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 140),
            painter: _SmileyPainter(color: Apptheme.ambercolor),
          ),
          const SizedBox(height: 28),
          Image.asset('assets/SVG/uzivaj_logo.png', height: 110),
        ],
      ),
    );
  }
}

// ── Slide 2 top — Steps ───────────────────────────────────────────────────────

class _Slide2Top extends StatelessWidget {
  final AppStrings l;
  const _Slide2Top({required this.l});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepCard(emoji: '👆', title: l.tapAnOffer, subtitle: l.chooseBogo),
          const _StepArrow(),
          _StepCard(emoji: '📱', title: l.handToWaiter, subtitle: l.enterPin),
          const _StepArrow(),
          _StepCard(emoji: '✅', title: l.offerUnlocked, subtitle: l.enjoyMeal, highlighted: true),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool highlighted;

  const _StepCard(
      {required this.emoji, required this.title, required this.subtitle, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? Colors.orange : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text('↓',
            style: TextStyle(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w300)),
      ),
    );
  }
}

// ── Slide 3 top — Features ────────────────────────────────────────────────────

class _Slide3Top extends StatelessWidget {
  final AppStrings l;
  const _Slide3Top({required this.l});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeatureCard(emoji: '🎫', title: l.offersPerRestaurant, subtitle: l.eachRedeemableOnce),
          const SizedBox(height: 10),
          _FeatureCard(emoji: '📍', title: l.zagrebVenues, subtitle: l.newPlacesMonthly),
          const SizedBox(height: 10),
          _FeatureCard(
            emoji: '💳',
            title: l.oneDinnerPaysBack,
            subtitle: l.pricePerYear,
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool highlighted;

  const _FeatureCard(
      {required this.emoji, required this.title, required this.subtitle, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? Colors.orange : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Smiley arc painter ────────────────────────────────────────────────────────

class _SmileyPainter extends CustomPainter {
  final Color color;
  const _SmileyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 1.0, size.width * 0.9, size.height * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
