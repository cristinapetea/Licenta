import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';


void main() => runApp(const ChoreBuddzApp());

class ChoreBuddzApp extends StatelessWidget {
  const ChoreBuddzApp({super.key});

  @override
  Widget build(BuildContext context) {
    // paleta noastră
    const paleRoyalBlue = Color(0xFF7E9BFF); // albastru pal regal
    const palePurple    = Color(0xFFD3B8FF); // mov pal
    const deepIndigo    = Color(0xFF4B4FA7);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChoreBuddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepIndigo,
          primary: deepIndigo,
          secondary: palePurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    const palePurple    = Color(0xFFD3B8FF);
    const deepIndigo    = Color(0xFF4B4FA7);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // gradient albastru pal + mov pal
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [paleRoyalBlue, palePurple],
          ),
        ),
        child: Stack(
          children: [
            // Bule decorative translucide
            Positioned(
              top: -60, left: -40,
              child: _Blob(size: 180, color: Colors.white24),
            ),
            Positioned(
              bottom: -50, right: -30,
              child: _Blob(size: 220, color: Colors.white30),
            ),
            // Conținutul principal
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo rotund cu mătură stilizată
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 16),
                            ),
                          ],
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF7F3FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _BroomPainter(
                            handleColor: deepIndigo,
                            strawColor: const Color(0xFFFFC97A),
                            bandColor: const Color(0xFF8A7CCF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'ChoreBuddy',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.18),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Less stress. Less mess',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Butoane CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PrimaryButton(
                        label: 'Let the cleaning begin!',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                      ),

                          
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// bulă decorativă
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
    );
  }
}

/// buton primar
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// buton conturat alb (ghost)
class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GhostButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white, width: 1.4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// Logo – mătură desenată vectorial
class _BroomPainter extends CustomPainter {
  final Color handleColor;
  final Color strawColor;
  final Color bandColor;

  _BroomPainter({
    required this.handleColor,
    required this.strawColor,
    required this.bandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // centru și scalare
    final cx = w / 2;
    final cy = h / 2;

    // mâner
    final handlePaint = Paint()
      ..color = handleColor
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    // înclinăm puțin mătura
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.35);
    canvas.translate(-cx, -cy);

    // mânerul (o linie lungă)
    canvas.drawLine(
      Offset(cx - w * 0.25, cy - h * 0.30),
      Offset(cx + w * 0.35, cy + h * 0.20),
      handlePaint,
    );

    // capătul de paie
    final headWidth = w * 0.42;
    final headHeight = h * 0.22;
    final headRect = Rect.fromCenter(
      center: Offset(cx + w * 0.30, cy + h * 0.22),
      width: headWidth,
      height: headHeight,
    );

    // corp paie (oval)
    final headPaint = Paint()..color = strawColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.10)),
      headPaint,
    );

    // bandă
    final bandPaint = Paint()..color = bandColor;
    final bandRect = Rect.fromLTWH(
      headRect.left + headWidth * 0.05,
      headRect.top + headHeight * 0.32,
      headWidth * 0.90,
      headHeight * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(w * 0.05)),
      bandPaint,
    );

    // câteva fire (bristles)
    final bristlePaint = Paint()
      ..color = Colors.brown.withOpacity(0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 7; i++) {
      final t = i / 6.0;
      final x = headRect.left + headWidth * t;
      canvas.drawLine(
        Offset(x, headRect.bottom - 4),
        Offset(x + 6 * (t - 0.5), headRect.bottom + 10),
        bristlePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BroomPainter old) => false;
}
