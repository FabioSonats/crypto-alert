import 'package:flutter/material.dart';
import 'controllers/crypto_controller.dart';
import 'services/notification_service.dart';
import 'ui/screens/home_screen.dart';

/// Função principal do aplicativo NexusStack
///
/// Monitor de 26 criptomoedas com alertas e simulador de investimentos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa serviço de notificações
  await NotificationService.instance.initialize();

  runApp(const NexusStackApp());
}

/// Widget principal da aplicação
class NexusStackApp extends StatelessWidget {
  const NexusStackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cria uma instância do controller
    final controller = CryptoController();

    return MaterialApp(
      title: 'NexusStack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7), // Roxo tech
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7), // Roxo tech
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller),
    );
  }
}
