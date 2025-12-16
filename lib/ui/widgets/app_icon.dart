import 'package:flutter/material.dart';

/// Widget que renderiza a logo do Crypto Alert
///
/// Estilo: Radar de Mercado com Neon/Tech
class AppIcon extends StatelessWidget {
  final double size;

  const AppIcon({super.key, this.size = 512});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppIconPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Cores
    const darkBlue = Color(0xFF1A237E);
    const darkerBlue = Color(0xFF0D1442);
    const bitcoinOrange = Color(0xFFF7931A);
    const ethereumPurple = Color(0xFF627EEA);
    const xrpBlue = Color(0xFF00AAE4);
    const greenProfit = Color(0xFF4CAF50);

    // Fundo com gradiente
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius * 0.2),
    );
    
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [darkBlue, darkerBlue],
    );
    
    final bgPaint = Paint()
      ..shader = bgGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    
    canvas.drawRRect(bgRect, bgPaint);

    // Círculos do radar
    _drawRadarCircle(canvas, center, radius * 0.7, bitcoinOrange.withOpacity(0.3), 2);
    _drawRadarCircle(canvas, center, radius * 0.5, bitcoinOrange.withOpacity(0.5), 2);
    _drawRadarCircle(canvas, center, radius * 0.3, bitcoinOrange.withOpacity(0.7), 3);

    // Linhas cruzadas
    final linePaint = Paint()
      ..color = bitcoinOrange.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Vertical
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.7),
      Offset(center.dx, center.dy + radius * 0.7),
      linePaint,
    );
    
    // Horizontal
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy),
      Offset(center.dx + radius * 0.7, center.dy),
      linePaint,
    );

    // Diagonais
    linePaint.strokeWidth = 1.5;
    linePaint.color = bitcoinOrange.withOpacity(0.3);
    canvas.drawLine(
      Offset(center.dx - radius * 0.5, center.dy - radius * 0.5),
      Offset(center.dx + radius * 0.5, center.dy + radius * 0.5),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.5),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.5),
      linePaint,
    );

    // Pontos das moedas
    // Bitcoin (topo)
    _drawCoinPoint(
      canvas,
      Offset(center.dx, center.dy - radius * 0.6),
      radius * 0.09,
      bitcoinOrange,
      '₿',
      darkBlue,
    );

    // Ethereum (esquerda)
    _drawCoinPoint(
      canvas,
      Offset(center.dx - radius * 0.6, center.dy),
      radius * 0.07,
      ethereumPurple,
      'Ξ',
      Colors.white,
    );

    // XRP (direita)
    _drawCoinPoint(
      canvas,
      Offset(center.dx + radius * 0.6, center.dy),
      radius * 0.07,
      xrpBlue,
      'X',
      Colors.white,
    );

    // Centro - círculo principal com gradiente
    final centerGradient = RadialGradient(
      colors: [
        const Color(0xFFFF9800),
        bitcoinOrange,
        const Color(0xFFFF5722),
      ],
    );
    
    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.18),
      );

    // Glow do centro
    final glowPaint = Paint()
      ..color = bitcoinOrange.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius * 0.18, glowPaint);
    
    canvas.drawCircle(center, radius * 0.18, centerPaint);

    // Sino de alerta no centro
    _drawBell(canvas, center, radius * 0.1, darkBlue);

    // Ondas de sinal (verde)
    _drawSignalWaves(canvas, center, radius, greenProfit);

    // Seta de alta (verde) no canto
    _drawUpArrow(
      canvas,
      Offset(center.dx + radius * 0.5, center.dy + radius * 0.45),
      radius * 0.12,
      greenProfit,
    );
  }

  void _drawRadarCircle(Canvas canvas, Offset center, double radius, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCoinPoint(Canvas canvas, Offset center, double radius, Color color, String symbol, Color textColor) {
    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, glowPaint);

    // Círculo
    final circlePaint = Paint()..color = color;
    canvas.drawCircle(center, radius, circlePaint);

    // Texto
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: textColor,
          fontSize: radius * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawBell(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    
    // Corpo do sino
    final bellPath = Path();
    bellPath.moveTo(center.dx, center.dy - size * 0.6);
    bellPath.quadraticBezierTo(
      center.dx - size * 0.8, center.dy - size * 0.3,
      center.dx - size * 0.8, center.dy + size * 0.2,
    );
    bellPath.lineTo(center.dx - size, center.dy + size * 0.4);
    bellPath.lineTo(center.dx + size, center.dy + size * 0.4);
    bellPath.lineTo(center.dx + size * 0.8, center.dy + size * 0.2);
    bellPath.quadraticBezierTo(
      center.dx + size * 0.8, center.dy - size * 0.3,
      center.dx, center.dy - size * 0.6,
    );
    bellPath.close();
    
    canvas.drawPath(bellPath, paint);

    // Bolinha do sino
    canvas.drawCircle(
      Offset(center.dx, center.dy + size * 0.6),
      size * 0.2,
      paint,
    );
  }

  void _drawSignalWaves(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Primeira onda
    final wave1 = Path();
    wave1.moveTo(center.dx + radius * 0.22, center.dy - radius * 0.15);
    wave1.quadraticBezierTo(
      center.dx + radius * 0.32, center.dy,
      center.dx + radius * 0.22, center.dy + radius * 0.15,
    );
    canvas.drawPath(wave1, paint);

    // Segunda onda (mais fraca)
    paint.color = color.withOpacity(0.6);
    paint.strokeWidth = 3;
    final wave2 = Path();
    wave2.moveTo(center.dx + radius * 0.3, center.dy - radius * 0.22);
    wave2.quadraticBezierTo(
      center.dx + radius * 0.42, center.dy,
      center.dx + radius * 0.3, center.dy + radius * 0.22,
    );
    canvas.drawPath(wave2, paint);
  }

  void _drawUpArrow(Canvas canvas, Offset position, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final arrowPath = Path();
    arrowPath.moveTo(position.dx, position.dy - size);
    arrowPath.lineTo(position.dx + size * 0.6, position.dy - size * 0.3);
    arrowPath.lineTo(position.dx + size * 0.25, position.dy - size * 0.3);
    arrowPath.lineTo(position.dx + size * 0.25, position.dy + size * 0.5);
    arrowPath.lineTo(position.dx - size * 0.25, position.dy + size * 0.5);
    arrowPath.lineTo(position.dx - size * 0.25, position.dy - size * 0.3);
    arrowPath.lineTo(position.dx - size * 0.6, position.dy - size * 0.3);
    arrowPath.close();

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tela para visualizar e exportar o ícone
class IconPreviewScreen extends StatelessWidget {
  const IconPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Preview do Ícone'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone grande
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF7931A).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const AppIcon(size: 256),
            ),
            const SizedBox(height: 40),
            // Ícones em tamanhos menores
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(size: 96),
                SizedBox(width: 20),
                AppIcon(size: 72),
                SizedBox(width: 20),
                AppIcon(size: 48),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Crypto Alert',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: const Color(0xFFF7931A).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Radar de Mercado • Neon Tech',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

