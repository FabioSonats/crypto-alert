import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tesouro_simulation.dart';

/// Serviço para persistir simulação de Tesouro Direto
///
/// Guarda o investimento simulado e mostra o progresso ao longo do tempo
class TesouroService extends ChangeNotifier {
  static const String _storageKey = 'tesouro_investment';

  TesouroInvestment? _investment;
  double _currentSelicRate = 13.25;

  /// Investimento atual
  TesouroInvestment? get investment => _investment;

  /// Taxa SELIC atual
  double get currentSelicRate => _currentSelicRate;

  /// Verifica se há investimento
  bool get hasInvestment => _investment != null;

  /// Atualiza a taxa SELIC
  void updateSelicRate(double rate) {
    _currentSelicRate = rate;
    notifyListeners();
  }

  /// Inicializa carregando dados salvos
  Future<void> initialize() async {
    await _loadInvestment();
  }

  /// Salva uma nova simulação de investimento
  Future<void> setInvestment({
    required double valorInicial,
    required int tempoMeses,
    required double taxaAnual,
  }) async {
    _investment = TesouroInvestment(
      valorInicial: valorInicial,
      tempoMeses: tempoMeses,
      taxaAnual: taxaAnual,
      dataInvestimento: DateTime.now(),
    );
    await _saveInvestment();
    notifyListeners();
  }

  /// Remove o investimento
  Future<void> removeInvestment() async {
    _investment = null;
    await _clearInvestment();
    notifyListeners();
  }

  /// Calcula o valor atual considerando o tempo decorrido
  TesouroSimulation? getCurrentSimulation() {
    if (_investment == null) return null;

    // Calcula quanto tempo passou desde o investimento
    final diasDecorridos = DateTime.now()
        .difference(_investment!.dataInvestimento)
        .inDays;
    
    // Usa a taxa atual para cálculo
    return TesouroSimulation(
      valorInicial: _investment!.valorInicial,
      tempoMeses: _investment!.tempoMeses,
      taxaAnual: _currentSelicRate,
      diasDecorridos: diasDecorridos,
    );
  }

  /// Valor atual do investimento (considerando tempo decorrido)
  double get valorAtual {
    final sim = getCurrentSimulation();
    if (sim == null) return 0;
    return sim.valorAtualProporcional;
  }

  /// Ganho atual (considerando tempo decorrido)
  double get ganhoAtual {
    if (_investment == null) return 0;
    return valorAtual - _investment!.valorInicial;
  }

  /// Percentual de ganho atual
  double get percentualGanhoAtual {
    if (_investment == null || _investment!.valorInicial <= 0) return 0;
    return (ganhoAtual / _investment!.valorInicial) * 100;
  }

  /// Dias restantes até o final
  int get diasRestantes {
    if (_investment == null) return 0;
    final diasDecorridos = DateTime.now()
        .difference(_investment!.dataInvestimento)
        .inDays;
    final diasTotais = (_investment!.tempoMeses * 30.44).round();
    return (diasTotais - diasDecorridos).clamp(0, diasTotais);
  }

  /// Carrega do storage
  Future<void> _loadInvestment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _investment = TesouroInvestment.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar investimento Tesouro: $e');
    }
  }

  /// Salva no storage
  Future<void> _saveInvestment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_investment != null) {
        await prefs.setString(_storageKey, jsonEncode(_investment!.toJson()));
      }
    } catch (e) {
      debugPrint('Erro ao salvar investimento Tesouro: $e');
    }
  }

  /// Remove do storage
  Future<void> _clearInvestment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Erro ao remover investimento Tesouro: $e');
    }
  }
}

/// Representa um investimento em Tesouro Direto persistido
class TesouroInvestment {
  final double valorInicial;
  final int tempoMeses;
  final double taxaAnual;
  final DateTime dataInvestimento;

  const TesouroInvestment({
    required this.valorInicial,
    required this.tempoMeses,
    required this.taxaAnual,
    required this.dataInvestimento,
  });

  Map<String, dynamic> toJson() => {
        'valorInicial': valorInicial,
        'tempoMeses': tempoMeses,
        'taxaAnual': taxaAnual,
        'dataInvestimento': dataInvestimento.toIso8601String(),
      };

  factory TesouroInvestment.fromJson(Map<String, dynamic> json) {
    return TesouroInvestment(
      valorInicial: (json['valorInicial'] as num).toDouble(),
      tempoMeses: json['tempoMeses'] as int,
      taxaAnual: (json['taxaAnual'] as num).toDouble(),
      dataInvestimento: DateTime.parse(json['dataInvestimento'] as String),
    );
  }
}

