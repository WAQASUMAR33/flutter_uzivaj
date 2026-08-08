import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/screens/home.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> subscription;
  final String packageTitle;
  final double totalPaid;

  const PaymentSuccessScreen({
    super.key,
    required this.subscription,
    required this.packageTitle,
    required this.totalPaid,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _smileyFade;
  late Animation<double> _smileyScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _smileyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _smileyScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final planLabel = widget.packageTitle;
    final totalPaid = widget.totalPaid;
    final renewsDate = _formatEndDate(sub['endDate'] as String?);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Apptheme.bluecolor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Animated smiley ────────────────────────────────────
                FadeTransition(
                  opacity: _smileyFade,
                  child: ScaleTransition(
                    scale: _smileyScale,
                    child: CustomPaint(
                      size: const Size(200, 100),
                      painter: _SmileyPainter(color: Apptheme.ambercolor),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Animated title + content ───────────────────────────
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      children: [
                        // Title
                        const Text(
                          'Welcome to Uživaj!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        const Text(
                          "Your founding membership is active.\nStart exploring Zagreb's best restaurants now.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Summary card ────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _SummaryRow(
                                label: 'Plan',
                                value: planLabel,
                                isFirst: true,
                              ),
                              _SummaryRow(
                                label: 'Paid today',
                                value:
                                    '€${totalPaid.toStringAsFixed(2)} incl. VAT',
                              ),
                              _SummaryRow(
                                label: 'Renews',
                                value: '$renewsDate · Auto-renew on',
                                valueColor: Apptheme.ambercolor,
                              ),
                              _SummaryRow(
                                label: 'Receipt',
                                value: 'Sent to your email ✓',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Start exploring button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                                (_) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Start exploring →',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Apptheme.bluecolor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Manage renewal hint ─────────────────────────
                        const Text(
                          'Manage renewal anytime in Profile → Subscription',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── Footer label ───────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'PAYMENT SUCCESS',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
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

  String _formatEndDate(String? iso) {
    if (iso == null || iso.isEmpty) {
      // Fallback: one year from today
      final next = DateTime.now().add(const Duration(days: 365));
      return '${_monthName(next.month)} ${next.year}';
    }
    try {
      final dt = DateTime.parse(iso);
      return '${_monthName(dt.month)} ${dt.year}';
    } catch (_) {
      final next = DateTime.now().add(const Duration(days: 365));
      return '${_monthName(next.month)} ${next.year}';
    }
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

// ── Summary card row ──────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 18,
            endIndent: 18,
          ),
      ],
    );
  }
}

// ── Smiley arc painter (same as splash) ──────────────────────────────────────

class _SmileyPainter extends CustomPainter {
  final Color color;
  const _SmileyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.9,
      size.width * 0.85,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
