import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../utils/config.dart';
import '../widgets/app_icon.dart';

/// Tela de configurações do aplicativo
///
/// Permite ajustar o threshold de variação para sugestões
class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _threshold;

  @override
  void initState() {
    super.initState();
    _threshold = widget.settingsService.variationThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de Threshold
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Variação para alerta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define quando sugerir COMPRAR ou VENDER',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Valor atual
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_threshold.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Slider
                  Row(
                    children: [
                      Text(
                        '${Config.minVariationThreshold.toInt()}%',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _threshold,
                          min: Config.minVariationThreshold,
                          max: Config.maxVariationThreshold,
                          divisions: 14,
                          label: '${_threshold.toStringAsFixed(0)}%',
                          onChanged: (value) {
                            setState(() => _threshold = value);
                          },
                          onChangeEnd: (value) {
                            widget.settingsService.setVariationThreshold(value);
                          },
                        ),
                      ),
                      Text(
                        '${Config.maxVariationThreshold.toInt()}%',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Preview
                  _buildPreview(theme),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card de explicação
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Como funciona?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExplanationRow(
                    theme,
                    Icons.arrow_downward,
                    Colors.green,
                    'COMPRAR',
                    'Quando o preço cair mais de ${_threshold.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  _buildExplanationRow(
                    theme,
                    Icons.arrow_upward,
                    Colors.red,
                    'VENDER',
                    'Quando o preço subir mais de ${_threshold.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  _buildExplanationRow(
                    theme,
                    Icons.remove,
                    Colors.orange,
                    'MANTER',
                    'Quando a variação estiver entre -${_threshold.toStringAsFixed(0)}% e +${_threshold.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dica
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Investimentos menores geralmente precisam de variações maiores para valer a pena agir.',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sobre o App
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const AppIcon(size: 80),
                  const SizedBox(height: 12),
                  const Text(
                    'Crypto Alert',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitore suas criptomoedas e simule investimentos em tempo real.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IconPreviewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver ícone em detalhes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREVIEW',
          style: TextStyle(
            color: theme.colorScheme.outline,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPreviewChip(
              'COMPRAR',
              '-${_threshold.toStringAsFixed(0)}%',
              Colors.green,
            ),
            _buildPreviewChip(
              'MANTER',
              '±${(_threshold / 2).toStringAsFixed(0)}%',
              Colors.orange,
            ),
            _buildPreviewChip(
              'VENDER',
              '+${_threshold.toStringAsFixed(0)}%',
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewChip(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationRow(
    ThemeData theme,
    IconData icon,
    Color color,
    String label,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
