import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';

void main() => runApp(const ChoreBuddzApp());

class ChoreBuddzApp extends StatelessWidget {
  const ChoreBuddzApp({super.key});

  @override
  Widget build(BuildContext context) {
    const palePurple    = Color(0xFFD3B8FF);
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
      initialRoute: '/landing',
      routes: {
        '/landing'   : (_) => const LandingPage(),
        '/login'     : (_) => const LoginPage(),
        '/signup'    : (_) => const SignUpPage(),
        '/home'      : (_) => const HomePage(),
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    const palePurple    = Color(0xFFD3B8FF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [paleRoyalBlue, palePurple],
          ),
        ),
        child: Stack(
          children: [
           
            Positioned(
              top: -60, left: -40,
              child: _Blob(size: 180, color: Colors.white24),
            ),
            Positioned(
              bottom: -50, right: -30,
              child: _Blob(size: 220, color: Colors.white30),
            ),
            
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 140,
                        height: 140,
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
                          painter: _FamilyLogoPainter(),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// Logo cu mătură și flori maturate
class _FamilyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Culori
    const handleColor = Color(0xFF8B6F47);  // maro pentru mâner
    const bristleColor = Color(0xFFFFD700); // galben auriu pentru paie
    const flowerColors = [
      Color(0xFFFF9AA2), // roz
      Color(0xFFFFDAB9), // piersică
      Color(0xFFB5EAD7), // mint
      Color(0xFFC7CEEA), // lavandă
    ];

    // Desenăm florile maturate jos
    _drawFlowers(canvas, Offset(cx - w * 0.18, cy + h * 0.25), flowerColors, w * 0.08);
    _drawFlowers(canvas, Offset(cx + w * 0.15, cy + h * 0.28), flowerColors, w * 0.07);
    _drawFlowers(canvas, Offset(cx - w * 0.05, cy + h * 0.30), flowerColors, w * 0.06);

    // Desenăm mătura
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.3); // înclinare ușoară
    canvas.translate(-cx, -cy);

    // Mânerul măturii - mai subțire și mai elegant
    final handlePaint = Paint()
      ..color = handleColor
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - w * 0.15, cy - h * 0.25),
      Offset(cx + w * 0.20, cy + h * 0.15),
      handlePaint,
    );

    // Capul de paie stufoase
    final bristleStartX = cx + w * 0.15;
    final bristleStartY = cy + h * 0.12;
    
    final bristlePaint = Paint()
      ..color = bristleColor
      ..strokeCap = StrokeCap.round;

    // Paiele individuale pentru efect stufoasa
    for (int i = 0; i < 25; i++) {
      final angle = -0.6 + (i / 24.0) * 1.2; // spread de la -0.6 la 0.6 radiani
      final length = w * 0.12 + (i % 3) * w * 0.015; // lungimi variate
      final thickness = w * 0.008 - (i % 2) * w * 0.002;
      
      bristlePaint.strokeWidth = thickness;
      
      final endX = bristleStartX + length * Math.cos(angle);
      final endY = bristleStartY + length * Math.sin(angle);
      
      canvas.drawLine(
        Offset(bristleStartX, bristleStartY),
        Offset(endX, endY),
        bristlePaint,
      );
    }

    // Banda care leagă paiele
    final bandPaint = Paint()..color = const Color(0xFF4B4FA7);
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bristleStartX, bristleStartY),
        width: w * 0.15,
        height: w * 0.05,
      ),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(bandRect, bandPaint);

    canvas.restore();
  }

  void _drawFlowers(Canvas canvas, Offset center, List<Color> colors, double size) {
    // Desenăm 2-3 floricele grupate
    final numFlowers = 2 + (center.dx.toInt() % 2);
    
    for (int i = 0; i < numFlowers; i++) {
      final offsetX = (i - 1) * size * 0.6;
      final flowerCenter = Offset(center.dx + offsetX, center.dy);
      final color = colors[i % colors.length];
      
      // Petalele (5 petale)
      final petalPaint = Paint()..color = color;
      
      for (int p = 0; p < 5; p++) {
        final angle = (p * 2 * Math.pi / 5) - Math.pi / 2;
        final petalX = flowerCenter.dx + size * 0.3 * Math.cos(angle);
        final petalY = flowerCenter.dy + size * 0.3 * Math.sin(angle);
        
        canvas.drawCircle(Offset(petalX, petalY), size * 0.2, petalPaint);
      }
      
      // Centrul florii
      final centerPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(flowerCenter, size * 0.15, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper class pentru Math
class Math {
  static const double pi = 3.14159265359;
  
  static double cos(double radians) {
    return _cos(radians);
  }
  
  static double sin(double radians) {
    return _sin(radians);
  }
  
  static double _cos(double x) {
    // Taylor series approximation
    x = x % (2 * pi);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
  
  static double _sin(double x) {
    x = x % (2 * pi);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}