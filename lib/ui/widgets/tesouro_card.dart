import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tesouro_simulation.dart';
import '../../services/selic_service.dart';
import '../../services/tesouro_service.dart';

/// Card de simulação de Tesouro Direto
///
/// Permite simular investimento em Tesouro Selic com taxa real do BCB
/// Persiste a simulação e mostra o progresso ao longo do tempo
class TesouroCard extends StatefulWidget {
  final TesouroService tesouroService;

  const TesouroCard({
    super.key,
    required this.tesouroService,
  });

  @override
  State<TesouroCard> createState() => _TesouroCardState();
}

class _TesouroCardState extends State<TesouroCard> {
  final SelicService _selicService = SelicService();
  final TextEditingController _valorController = TextEditingController();

  double _taxaSelic = 13.25;
  bool _isLoadingRate = true;
  int _tempoMeses = 12;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadSelicRate();
    widget.tesouroService.addListener(_onServiceUpdate);
    _loadExistingInvestment();
  }

  void _loadExistingInvestment() {
    if (widget.tesouroService.hasInvestment) {
      final inv = widget.tesouroService.investment!;
      _valorController.text = _formatInputValue(inv.valorInicial);
      _tempoMeses = inv.tempoMeses;
    }
  }

  @override
  void dispose() {
    widget.tesouroService.removeListener(_onServiceUpdate);
    _valorController.dispose();
    _selicService.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSelicRate() async {
    setState(() => _isLoadingRate = true);
    try {
      final rate = await _selicService.fetchSelicRate();
      setState(() {
        _taxaSelic = rate;
        _isLoadingRate = false;
      });
      widget.tesouroService.updateSelicRate(rate);
    } catch (e) {
      setState(() => _isLoadingRate = false);
    }
  }

  String _formatInputValue(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _parseValue(String text) {
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  TesouroSimulation? _getPreviewSimulation() {
    final valor = _parseValue(_valorController.text) ?? 0;
    if (valor <= 0) return null;

    return TesouroSimulation(
      valorInicial: valor,
      tempoMeses: _tempoMeses,
      taxaAnual: _taxaSelic,
    );
  }

  Future<void> _saveInvestment() async {
    final valor = _parseValue(_valorController.text);
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await widget.tesouroService.setInvestment(
      valorInicial: valor,
      tempoMeses: _tempoMeses,
      taxaAnual: _taxaSelic,
    );

    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulação salva! Acompanhe seu rendimento.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeInvestment() async {
    await widget.tesouroService.removeInvestment();
    _valorController.clear();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardColor = Color(0xFF1565C0);
    final hasInvestment = widget.tesouroService.hasInvestment;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(cardColor),

          // Corpo do card
          if (hasInvestment && !_isEditing)
            _buildInvestmentProgress(theme, cardColor)
          else
            _buildInputForm(theme, cardColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.account_balance, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tesouro Selic',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Taxa atual: ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    if (_isLoadingRate)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Text(
                        '${_taxaSelic.toStringAsFixed(2)}% a.a.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSelicRate,
            tooltip: 'Atualizar taxa SELIC',
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentProgress(ThemeData theme, Color cardColor) {
    final service = widget.tesouroService;
    final inv = service.investment!;
    final simulation = service.getCurrentSimulation()!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info do investimento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investido',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    simulation.valorInicialFormatado,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Valor atual',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    simulation.formatCurrency(service.valorAtual),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ganho e tempo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rendimento',
                          style: TextStyle(fontSize: 11, color: Colors.green),
                        ),
                        Text(
                          '${simulation.formatCurrency(service.ganhoAtual)} (+${service.percentualGanhoAtual.toStringAsFixed(2)}%)',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Prazo: ${inv.tempoMeses} meses',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${service.diasRestantes} dias restantes',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Projeção final
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projeção ao final:',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                ),
              ),
              Text(
                '${simulation.valorFinalFormatado} (${simulation.rentabilidadeFormatada})',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeInvestment,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remover'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm(ThemeData theme, Color cardColor) {
    final preview = _getPreviewSimulation();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Valor investido
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Valor investido:',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    hintText: '1.000,00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tempo
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Tempo:',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _tempoMeses,
                      isExpanded: true,
                      isDense: true,
                      items: TempoOptions.options.map((option) {
                        return DropdownMenuItem<int>(
                          value: option.meses,
                          child: Text(option.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _tempoMeses = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Preview do resultado
          if (preview != null && preview.valorInicial > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor final estimado:'),
                      Text(
                        preview.valorFinalFormatado,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ganho:'),
                      Text(
                        '${preview.ganhoBrutoFormatado} (${preview.rentabilidadeFormatada})',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Botão salvar
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveInvestment,
              icon: const Icon(Icons.save),
              label: Text(widget.tesouroService.hasInvestment
                  ? 'Atualizar Simulação'
                  : 'Salvar Simulação'),
              style: FilledButton.styleFrom(
                backgroundColor: cardColor,
              ),
            ),
          ),

          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _loadExistingInvestment();
                setState(() => _isEditing = false);
              },
              child: const Text('Cancelar'),
            ),
          ],
        ],
      ),
    );
  }
}
