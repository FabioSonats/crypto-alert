import 'package:flutter/material.dart';
import '../../models/crypto_price.dart';
import '../../utils/config.dart';

/// Widget para selecionar o período do gráfico
class ChartPeriodSelector extends StatelessWidget {
  final ChartPeriod selectedPeriod;
  final ValueChanged<ChartPeriod> onPeriodChanged;
  final Color? activeColor;

  const ChartPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = activeColor ?? theme.colorScheme.primary;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChartPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return GestureDetector(
            onTap: () => onPeriodChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                period.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Colors.white 
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget que exibe um gráfico de linha do histórico de preços
///
/// Gráfico simples usando CustomPaint (sem dependências externas)
class PriceChart extends StatelessWidget {
  /// Lista de pontos de preço
  final List<PricePoint> priceHistory;

  /// Cor da linha do gráfico
  final Color lineColor;

  /// Altura do gráfico
  final double height;

  /// Se está carregando
  final bool isLoading;

  /// Callback para recarregar quando vazio
  final VoidCallback? onRetry;

  const PriceChart({
    super.key,
    required this.priceHistory,
    this.lineColor = Colors.blue,
    this.height = 120,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (priceHistory.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                color: theme.colorScheme.outline.withOpacity(0.5),
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Gráfico indisponível',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    'Toque para recarregar',
                    style: TextStyle(
                      color: lineColor,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          priceHistory: priceHistory,
          lineColor: lineColor,
        ),
      ),
    );
  }
}

/// Painter customizado para desenhar o gráfico de linha
class _ChartPainter extends CustomPainter {
  final List<PricePoint> priceHistory;
  final Color lineColor;

  _ChartPainter({
    required this.priceHistory,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty || priceHistory.length < 2) return;

    // Encontra valores mínimo e máximo
    double minPrice = priceHistory.first.priceUsd;
    double maxPrice = priceHistory.first.priceUsd;
    for (final point in priceHistory) {
      if (point.priceUsd < minPrice) minPrice = point.priceUsd;
      if (point.priceUsd > maxPrice) maxPrice = point.priceUsd;
    }

    // Se todos os preços são iguais, adiciona margem artificial
    if (minPrice == maxPrice) {
      minPrice *= 0.99;
      maxPrice *= 1.01;
    }

    // Adiciona margem
    final range = maxPrice - minPrice;
    minPrice -= range * 0.1;
    maxPrice += range * 0.1;
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    // Padding
    const paddingTop = 10.0;
    const paddingBottom = 10.0;
    const paddingLeft = 5.0;
    const paddingRight = 5.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Cria o path da linha
    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < priceHistory.length; i++) {
      final point = priceHistory[i];
      final x = paddingLeft + (i / (priceHistory.length - 1)) * chartWidth;
      final y = paddingTop +
          chartHeight -
          ((point.priceUsd - minPrice) / priceRange) * chartHeight;

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height - paddingBottom);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fecha o path de preenchimento
    fillPath.lineTo(paddingLeft + chartWidth, size.height - paddingBottom);
    fillPath.close();

    // Desenha o preenchimento com gradiente
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.3),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Desenha a linha
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Desenha o ponto final
    final lastPoint = priceHistory.last;
    final lastX = paddingLeft + chartWidth;
    final lastY = paddingTop +
        chartHeight -
        ((lastPoint.priceUsd - minPrice) / priceRange) * chartHeight;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(lastX, lastY), 4, dotPaint);

    // Círculo branco interno
    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(lastX, lastY), 2, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.priceHistory != priceHistory ||
        oldDelegate.lineColor != lineColor;
  }
}

/// Mini gráfico sparkline para uso em listas
class SparklineChart extends StatelessWidget {
  final List<PricePoint> priceHistory;
  final Color? lineColor;
  final double width;
  final double height;

  const SparklineChart({
    super.key,
    required this.priceHistory,
    this.lineColor,
    this.width = 80,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    // Determina cor baseado na tendência
    Color color = lineColor ?? Colors.blue;
    if (priceHistory.length >= 2) {
      final first = priceHistory.first.priceUsd;
      final last = priceHistory.last.priceUsd;
      if (lineColor == null) {
        color = last >= first ? Colors.green : Colors.red;
      }
    }

    return SizedBox(
      width: width,
      height: height,
      child: PriceChart(
        priceHistory: priceHistory,
        lineColor: color,
        height: height,
      ),
    );
  }
}
