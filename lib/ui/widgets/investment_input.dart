import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/investment.dart';
import '../../models/crypto_price.dart';

/// Dialog para inserir valor de investimento
class InvestmentInputDialog extends StatefulWidget {
  /// Dados da criptomoeda
  final CryptoPrice price;

  /// Investimento existente (para edição)
  final Investment? existingInvestment;

  const InvestmentInputDialog({
    super.key,
    required this.price,
    this.existingInvestment,
  });

  /// Exibe o dialog e retorna o investimento criado/editado
  static Future<Investment?> show(
    BuildContext context,
    CryptoPrice price, {
    Investment? existingInvestment,
  }) {
    return showDialog<Investment>(
      context: context,
      builder: (context) => InvestmentInputDialog(
        price: price,
        existingInvestment: existingInvestment,
      ),
    );
  }

  @override
  State<InvestmentInputDialog> createState() => _InvestmentInputDialogState();
}

class _InvestmentInputDialogState extends State<InvestmentInputDialog> {
  late TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existingInvestment?.amountInvested.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coinColor = Color(widget.price.colorValue);
    final isEditing = widget.existingInvestment != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: coinColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.price.symbol.substring(0, 1),
                style: TextStyle(
                  color: coinColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Editar Investimento' : 'Simular Investimento',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info da moeda
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.price.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    widget.price.getFormattedPrice('BRL'),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Campo de valor
            Text(
              'Quanto você investiria?',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                hintText: '0,00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe um valor';
                }
                final parsed = _parseAmount(value);
                if (parsed == null || parsed <= 0) {
                  return 'Valor inválido';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Preview da quantidade de moedas
            if (_getPreviewAmount() > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: coinColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: coinColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: coinColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você teria ${_getPreviewCoins().toStringAsFixed(6)} ${widget.price.symbol}',
                        style: TextStyle(
                          color: coinColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Botão de remover (se editando)
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(isEditing ? 'Salvar' : 'Simular'),
        ),
      ],
    );
  }

  double? _parseAmount(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  double _getPreviewAmount() {
    return _parseAmount(_amountController.text) ?? 0;
  }

  double _getPreviewCoins() {
    final amount = _getPreviewAmount();
    if (amount <= 0) return 0;
    return amount / widget.price.priceBrl;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text)!;
    final investment = Investment(
      coinId: widget.price.coinId,
      amountInvested: amount,
      priceAtPurchase: widget.price.priceBrl,
      purchaseDate: DateTime.now(),
    );

    Navigator.pop(context, investment);
  }
}

/// Widget pequeno para mostrar/editar investimento dentro do card
class InvestmentChip extends StatelessWidget {
  final Investment? investment;
  final CryptoPrice price;
  final VoidCallback onTap;

  const InvestmentChip({
    super.key,
    this.investment,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (investment == null) {
      return ActionChip(
        avatar: const Icon(Icons.add, size: 18),
        label: const Text('Simular'),
        onPressed: onTap,
      );
    }

    final pl = investment!.profitLoss(price.priceBrl);
    final plColor = pl >= 0 ? Colors.green : Colors.red;

    return ActionChip(
      avatar: Icon(
        pl >= 0 ? Icons.trending_up : Icons.trending_down,
        size: 18,
        color: plColor,
      ),
      label: Text(
        investment!.formattedProfitLoss(price.priceBrl),
        style: TextStyle(color: plColor, fontWeight: FontWeight.w500),
      ),
      onPressed: onTap,
    );
  }
}
