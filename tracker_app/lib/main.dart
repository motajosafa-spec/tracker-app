import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'background_service.dart'; // Handler de segundo plano
import 'home_page.dart';          // Tela principal

// ══════════════════════════════════════════════════════════════
// PONTO DE ENTRADA DO SERVIÇO EM SEGUNDO PLANO
//
// @pragma('vm:entry-point') instrui o compilador Dart a NÃO
// remover essa função durante o tree-shaking (otimização de build).
// Sem isso, a função pode ser eliminada e o serviço não funciona.
// ══════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
void startBackgroundService() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase antes de qualquer uso do Firestore
  await Firebase.initializeApp();

  runApp(const TrackerApp());
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C896),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
