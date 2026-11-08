import 'dart:math';
import 'package:flutter/material.dart';

import 'card_colors.dart';

/// Authentic TORI MFI Virtual Debit / Somriddhi Member Card Widget.
/// Rendered using Flutter CustomPainter for 100% crisp vector fidelity on all screen densities.
/// Exactly conforms to standard banking CR80 aspect ratio (1.586:1).
class VirtualDebitCardWidget extends StatelessWidget {
  final String cardholderName;
  final String cardNumber;
  final String expiry;
  final String mfiId;
  final bool isBengali;
  final bool isFrozen;

  const VirtualDebitCardWidget({
    super.key,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiry,
    required this.mfiId,
    required this.isBengali,
    this.isFrozen = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.6), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0F172A),
              offset: Offset(0, 10),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // 1. Vector Fluid Geometric Wave Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _ToriCardWavePainter(),
                ),
              ),

              // 2. Card Content Layout
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Logo & Contactless Symbol
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TORI mFi Logo & Identity
                        Row(
                          children: [
                            // TORI Symbol Badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A),
                                    Color(0xFF0B132B)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                    color: const Color(0xFF1E2D54), width: 1),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.account_balance,
                                  color: ToriColors.vividCyan,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'TORI ',
                                      style: TextStyle(
                                        color: ToriColors.deepNavy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: ToriColors.primaryTeal,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'mFi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Somriddhi Member Card',
                                  style: TextStyle(
                                    color: const Color(0xFF475569),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Contactless Icon
                        CustomPaint(
                          size: const Size(22, 22),
                          painter: _ContactlessWavePainter(),
                        ),
                      ],
                    ),

                    // Middle: Metallic Gold EMV Chip
                    _buildEmvChip(),

                    // Card Number (Monospace Embossed Look)
                    Text(
                      cardNumber,
                      style: const TextStyle(
                        color: ToriColors.deepNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        letterSpacing: 2.2,
                        shadows: [
                          Shadow(
                              color: Color(0x22000000),
                              offset: Offset(0, 1),
                              blurRadius: 1),
                        ],
                      ),
                    ),

                    // Bottom Row: Cardholder, Expiry & VISA Debit Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cardholder Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (isBengali
                                    ? 'কার্ডধারীর নাম'
                                    : 'CARDHOLDER NAME'),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                cardholderName,
                                style: const TextStyle(
                                  color: ToriColors.deepNavy,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'MFI ID: $mfiId',
                                style: const TextStyle(
                                  color: ToriColors.primaryTeal,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Valid Thru
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (isBengali ? 'মেয়াদ' : 'VALID THRU'),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                expiry,
                                style: const TextStyle(
                                  color: ToriColors.deepNavy,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // VISA DEBIT Brand Mark
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'VISA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'DEBIT',
                              style: TextStyle(
                                color: ToriColors.vividCyan,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Frosted Glass Frozen Overlay
              if (isFrozen)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: ToriColors.criticalRose,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'CARD FROZEN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
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

  Widget _buildEmvChip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: ToriColors.emvChipGradient,
        border: Border.all(
            color: ToriColors.goldChipBorder.withValues(alpha: 0.6), width: 1),
      ),
      child: CustomPaint(
        painter: _EmvChipPainter(),
      ),
    );
  }
}

/// CustomPainter drawing the EMV microchip etched circuit division lines.
class _EmvChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF855D18).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal line
    canvas.drawLine(Offset(0, size.height * 0.48),
        Offset(size.width, size.height * 0.48), paint);
    // Vertical left branch
    canvas.drawLine(Offset(size.width * 0.32, 0),
        Offset(size.width * 0.32, size.height), paint);
    // Vertical right branch
    canvas.drawLine(Offset(size.width * 0.68, 0),
        Offset(size.width * 0.68, size.height), paint);
    // Center notch
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.38, size.height * 0.30, size.width * 0.24,
            size.height * 0.38),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter for the Contactless wave arcs.
class _ContactlessWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final center = Offset(size.width * 0.15, size.height * 0.5);
    final radii = [size.width * 0.30, size.width * 0.50, size.width * 0.70];

    for (final r in radii) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -pi / 4,
        pi / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter for the elegant TORI corporate waves (white + deep navy + royal blue + teal/cyan).
class _ToriCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Subtle hairline curves on white side
    final hairline = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < 5; i++) {
      final y = height * (0.12 + i * 0.16);
      final p = Path()
        ..moveTo(0, y)
        ..cubicTo(
            width * 0.20, y - 12, width * 0.40, y + 16, width * 0.65, y - 8);
      canvas.drawPath(p, hairline);
    }

    // 2. Teal / Cyan Wave
    final tealWave = Path()
      ..moveTo(width * 0.62, 0)
      ..cubicTo(width * 0.52, height * 0.35, width * 0.42, height * 0.70,
          width * 0.52, height)
      ..lineTo(width, height)
      ..lineTo(width, 0)
      ..close();

    final tealPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0D9488), Color(0xFF14B8A6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(width * 0.5, 0, width * 0.5, height));

    canvas.drawPath(tealWave, tealPaint);

    // 3. Royal Blue Mid Wave
    final royalWave = Path()
      ..moveTo(width * 0.69, 0)
      ..cubicTo(width * 0.59, height * 0.38, width * 0.49, height * 0.75,
          width * 0.60, height)
      ..lineTo(width, height)
      ..lineTo(width, 0)
      ..close();

    final royalPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(width * 0.6, 0, width * 0.4, height));

    canvas.drawPath(royalWave, royalPaint);

    // 4. Deep Midnight Navy Top Wave
    final navyWave = Path()
      ..moveTo(width * 0.75, 0)
      ..cubicTo(width * 0.66, height * 0.40, width * 0.56, height * 0.72,
          width * 0.68, height)
      ..lineTo(width, height)
      ..lineTo(width, 0)
      ..close();

    final navyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B132B), Color(0xFF0F172A), Color(0xFF081430)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(width * 0.68, 0, width * 0.32, height));

    canvas.drawPath(navyWave, navyPaint);

    // 5. Glowing Cyan Ribbon Edge
    final cyanEdge = Path()
      ..moveTo(width * 0.75, 0)
      ..cubicTo(width * 0.66, height * 0.40, width * 0.56, height * 0.72,
          width * 0.68, height);

    final edgePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22D3EE), Color(0xFF38BDF8), Color(0xFF0D9488)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(width * 0.56, 0, width * 0.2, height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(cyanEdge, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
