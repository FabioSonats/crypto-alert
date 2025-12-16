import 'package:flutter/material.dart';
import '../../controllers/bitcoin_controller.dart';
import '../../models/bitcoin_price.dart';
import '../widgets/price_card.dart';
import '../widgets/action_indicator.dart';

/// Tela principal do aplicativo Crypto Alert
class HomeScreen extends StatefulWidget {
  final BitcoinController controller;
  
  const HomeScreen({
    super.key,
    required this.controller,
  });
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.startAutoUpdate();
  }
  
  @override
  void dispose() {
    widget.controller.stopAutoUpdate();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Alert'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ValueListenableBuilder<BitcoinPrice?>(
        valueListenable: widget.controller,
        builder: (context, price, _) {
          final action = widget.controller.suggestAction();
          final variation = price?.variationPercentage;
          
          return RefreshIndicator(
            onRefresh: () => widget.controller.manualUpdate(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Toggle de moeda
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Moeda: '),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'BRL', label: Text('BRL')),
                            ButtonSegment(value: 'USD', label: Text('USD')),
                          ],
                          selected: {widget.controller.selectedCurrency},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              widget.controller.changeCurrency(newSelection.first);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Card de preço
                  PriceCard(
                    price: price,
                    currency: widget.controller.selectedCurrency,
                    isLoading: widget.controller.isLoading,
                  ),
                  
                  // Indicador de ação
                  ActionIndicator(
                    action: action,
                    variationPercentage: variation,
                  ),
                  
                  // Botão de atualização manual
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: widget.controller.isLoading
                          ? null
                          : () => widget.controller.manualUpdate(),
                      icon: widget.controller.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Atualizar Agora'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  // Mensagem de erro
                  if (widget.controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.controller.errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

