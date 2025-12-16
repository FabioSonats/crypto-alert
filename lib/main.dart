import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Descomente após configurar Firebase
import 'controllers/bitcoin_controller.dart';
import 'ui/screens/home_screen.dart';

/// Função principal do aplicativo Crypto Alert
/// 
/// Inicializa o Firebase (se configurado) e inicia o app Flutter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase apenas se os arquivos de configuração estiverem presentes
  // Isso permite que o app funcione mesmo sem Firebase configurado
  try {
    // Comentado até que o Firebase seja configurado
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
  } catch (e) {
    // Se Firebase não estiver configurado, continua sem ele
    debugPrint('Firebase não configurado: $e');
  }
  
  runApp(const CryptoAlertApp());
}

/// Widget principal da aplicação
class CryptoAlertApp extends StatelessWidget {
  const CryptoAlertApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Cria uma instância do controller que será compartilhada
    final controller = BitcoinController();
    
    return MaterialApp(
      title: 'Crypto Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller),
    );
  }
}
