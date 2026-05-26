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
    const palePurple = Color(0xFFD3B8FF);
    const deepIndigo = Color(0xFF4B4FA7);

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
        '/landing': (_) => const LandingPage(),
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignUpPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    const palePurple = Color(0xFFD3B8FF);

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
              top: -60,
              left: -40,
              child: _Blob(size: 180, color: Colors.white24),
            ),
            Positioned(
              bottom: -50,
              right: -30,
              child: _Blob(size: 220, color: Colors.white30),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE2DCFF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 16)
                            ),
                          ],
                          
                        ),
                        child: CustomPaint(
                          painter: _SprayLogoPainter(),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        ),
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

  const _Blob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class _SprayLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Culori conform imaginii primite
    final liquidPink = const Color(0xFFFF69B4);
    final liquidPinkDark = const Color(0xFFE0218A);
    final triggerRed = const Color(0xFFD32F2F);
    final capRed = const Color(0xFFB71C1C);

    final bottlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          liquidPink.withOpacity(0.85),
          liquidPinkDark.withOpacity(0.95),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bodyPath = Path();
    // Pornim de sub gât (stânga)
    bodyPath.moveTo(w * 0.38, h * 0.40);
    // Curbă lină stânga sus spre umăr
    bodyPath.quadraticBezierTo(w * 0.32, h * 0.42, w * 0.28, h * 0.52);
    // Marginea stângă dreaptă a sticlei
    bodyPath.lineTo(w * 0.22, h * 0.80);
    // Baza sticlei curbată larg jos
    bodyPath.quadraticBezierTo(w * 0.48, h * 0.94, w * 0.74, h * 0.82);
    // Partea dreaptă cu adâncitura ergonomică pentru degete (ca în poză)
    bodyPath.quadraticBezierTo(w * 0.76, h * 0.65, w * 0.65, h * 0.55);
    bodyPath.quadraticBezierTo(w * 0.52, h * 0.46, w * 0.48, h * 0.40);
    bodyPath.close();

    canvas.drawPath(bodyPath, bottlePaint);
    canvas.drawPath(bodyPath, outlinePaint);

    
    final labelPath = Path();
    labelPath.moveTo(w * 0.34, h * 0.55);
    labelPath.quadraticBezierTo(w * 0.48, h * 0.50, w * 0.64, h * 0.58);
    labelPath.lineTo(w * 0.70, h * 0.78);
    labelPath.quadraticBezierTo(w * 0.48, h * 0.86, w * 0.26, h * 0.76);
    labelPath.close();

    canvas.drawPath(
      labelPath,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    
    final labelDecor = Path();
    labelDecor.moveTo(w * 0.28, h * 0.72);
    labelDecor.quadraticBezierTo(w * 0.48, h * 0.78, w * 0.68, h * 0.70);
    labelDecor.lineTo(w * 0.70, h * 0.74);
    labelDecor.quadraticBezierTo(w * 0.48, h * 0.82, w * 0.27, h * 0.75);
    labelDecor.close();
    canvas.drawPath(labelDecor, Paint()..color = liquidPink.withOpacity(0.5));

    
    
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.37, h * 0.28, w * 0.13, h * 0.05),
      const Radius.circular(2),
    );
    canvas.drawRRect(neck, Paint()..color = capRed);

    
    final sprayHead = Path();
    sprayHead.moveTo(w * 0.38, h * 0.28);
    sprayHead.lineTo(w * 0.38, h * 0.16);
    sprayHead.quadraticBezierTo(w * 0.42, h * 0.14, w * 0.54, h * 0.15);
    sprayHead.lineTo(w * 0.66, h * 0.18); // vârful duzei orientat spre dreapta-sus
    sprayHead.lineTo(w * 0.64, h * 0.24);
    sprayHead.lineTo(w * 0.48, h * 0.28);
    sprayHead.close();

    canvas.drawPath(
      sprayHead,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    
    final trigger = Path();
    trigger.moveTo(w * 0.39, h * 0.18);
    trigger.quadraticBezierTo(w * 0.28, h * 0.24, w * 0.26, h * 0.34);
    trigger.quadraticBezierTo(w * 0.30, h * 0.36, w * 0.33, h * 0.30);
    trigger.lineTo(w * 0.40, h * 0.26);
    trigger.close();
    canvas.drawPath(trigger, Paint()..color = triggerRed);

    
    canvas.drawRect(
      Rect.fromLTWH(w * 0.64, h * 0.18, w * 0.03, h * 0.04),
      Paint()..color = triggerRed,
    );

    
    final tubePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(w * 0.44, h * 0.33), Offset(w * 0.46, h * 0.85), tubePaint);

    
    final origin = Offset(w * 0.67, h * 0.19);

    
    final glitterPaint = Paint()..color = const Color(0xFFFFF176); 
    final glitterPoints = [
      Offset(w * 0.74, h * 0.12),
      Offset(w * 0.84, h * 0.10),
      Offset(w * 0.78, h * 0.22),
      Offset(w * 0.88, h * 0.18),
      Offset(w * 0.92, h * 0.26),
    ];
    for (var pt in glitterPoints) {
      _drawSparkle(canvas, pt, 3.5, glitterPaint);
    }

    
    _drawMiniFlower(canvas, Offset(w * 0.76, h * 0.17), const Color(0xFFFFB4D9), 4);
    _drawMiniFlower(canvas, Offset(w * 0.85, h * 0.13), const Color(0xFFCDB4FF), 5);
    _drawMiniFlower(canvas, Offset(w * 0.83, h * 0.24), const Color(0xFF90CAF9), 4.5);
    _drawMiniFlower(canvas, Offset(w * 0.92, h * 0.11), const Color(0xFFFF8A80), 5);
    _drawMiniFlower(canvas, Offset(w * 0.94, h * 0.20), const Color(0xFFA5D6A7), 4);

    
    final streamPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(origin, Offset(w * 0.73, h * 0.16), streamPaint);
    canvas.drawLine(origin, Offset(w * 0.71, h * 0.21), streamPaint);
  }

  
  void _drawSparkle(Canvas canvas, Offset c, double size, Paint paint) {
    final path = Path();
    path.moveTo(c.dx, c.dy - size);
    path.quadraticBezierTo(c.dx, c.dy, c.dx + size, c.dy);
    path.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + size);
    path.quadraticBezierTo(c.dx, c.dy, c.dx - size, c.dy);
    path.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - size);
    path.close();
    canvas.drawPath(path, paint);
  }

  
  void _drawMiniFlower(Canvas canvas, Offset c, Color color, double r) {
    final paint = Paint()..color = color;
    
    canvas.drawCircle(Offset(c.dx, c.dy - r), r * 0.6, paint);
    canvas.drawCircle(Offset(c.dx + r, c.dy), r * 0.6, paint);
    canvas.drawCircle(Offset(c.dx, c.dy + r), r * 0.6, paint);
    canvas.drawCircle(Offset(c.dx - r, c.dy), r * 0.6, paint);
    
    canvas.drawCircle(c, r * 0.4, Paint()..color = const Color(0xFFFFF59D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}