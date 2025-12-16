import 'package:flutter/material.dart';
import '../../models/crypto_price.dart';

/// Widget que exibe a setinha de tendência de preço
///
/// ↑ Verde quando subindo
/// ↓ Vermelho quando caindo
/// → Cinza quando estável
class TrendIndicator extends StatelessWidget {
  /// Tendência do preço
  final PriceTrend trend;

  /// Tamanho do ícone
  final double size;

  /// Se deve mostrar animação
  final bool animated;

  const TrendIndicator({
    super.key,
    required this.trend,
    this.size = 24,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconAndColor();

    Widget indicator = Icon(
      icon,
      color: color,
      size: size,
    );

    if (animated && trend != PriceTrend.stable) {
      indicator = _AnimatedTrendIcon(
        icon: icon,
        color: color,
        size: size,
        trend: trend,
      );
    }

    return indicator;
  }

  (IconData, Color) _getIconAndColor() {
    switch (trend) {
      case PriceTrend.up:
        return (Icons.arrow_upward_rounded, Colors.green);
      case PriceTrend.down:
        return (Icons.arrow_downward_rounded, Colors.red);
      case PriceTrend.stable:
        return (Icons.remove_rounded, Colors.grey);
    }
  }
}

/// Ícone animado de tendência
class _AnimatedTrendIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final PriceTrend trend;

  const _AnimatedTrendIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.trend,
  });

  @override
  State<_AnimatedTrendIcon> createState() => _AnimatedTrendIconState();
}

class _AnimatedTrendIconState extends State<_AnimatedTrendIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: widget.trend == PriceTrend.up ? -4 : 4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Widget compacto que mostra preço + tendência + variação
class PriceWithTrend extends StatelessWidget {
  /// Preço da criptomoeda
  final CryptoPrice price;

  /// Moeda para exibição (BRL ou USD)
  final String currency;

  /// Tamanho da fonte do preço
  final double priceFontSize;

  const PriceWithTrend({
    super.key,
    required this.price,
    this.currency = 'BRL',
    this.priceFontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final variation = currency == 'BRL'
        ? price.variationPercentageBrl
        : price.variationPercentageUsd;

    final variationColor = variation == null
        ? Colors.grey
        : variation >= 0
            ? Colors.green
            : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preço
        Text(
          price.getFormattedPrice(currency),
          style: TextStyle(
            fontSize: priceFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Setinha de tendência
        TrendIndicator(
          trend: price.trend,
          size: priceFontSize,
        ),
        const SizedBox(width: 4),
        // Variação percentual
        Text(
          price.getFormattedVariation(currency),
          style: TextStyle(
            fontSize: priceFontSize * 0.7,
            color: variationColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
