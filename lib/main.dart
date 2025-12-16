import 'package:flutter/material.dart';
import 'controllers/crypto_controller.dart';
import 'services/notification_service.dart';
import 'ui/screens/home_screen.dart';

/// Função principal do aplicativo Crypto Alert
///
/// Monitora Bitcoin, Ethereum e XRP em tempo real
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa serviço de notificações
  await NotificationService.instance.initialize();

  runApp(const CryptoAlertApp());
}

/// Widget principal da aplicação
class CryptoAlertApp extends StatelessWidget {
  const CryptoAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cria uma instância do controller
    final controller = CryptoController();

    return MaterialApp(
      title: 'Crypto Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
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
          seedColor: const Color(0xFF1E88E5),
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
