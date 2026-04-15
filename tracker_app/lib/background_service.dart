import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

// ══════════════════════════════════════════════════════════════
// LocationTaskHandler
//
// Esta classe é o "cérebro" do serviço de segundo plano.
// O Flutter Foreground Task cria um isolate Dart separado para
// executá-la, o que significa que ela NÃO tem acesso direto ao
// estado da UI — toda comunicação é feita via sendDataToMain().
//
// Ciclo de vida:
//   onStart  → chamado uma vez quando o serviço inicia
//   onEvent  → chamado a cada `interval` milissegundos
//   onDestroy → chamado quando o serviço é encerrado
// ══════════════════════════════════════════════════════════════
class LocationTaskHandler extends TaskHandler {
  int _counter = 0;
  static const String _deviceId = 'device_001'; // TODO: usar ID único do dispositivo

  // ──────────────────────────────────────────────────────────
  // onStart: executado uma única vez ao iniciar o serviço
  // ──────────────────────────────────────────────────────────
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    developer.log('[LocationTask] Serviço iniciado em $timestamp');

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Rastreador Ativo',
      notificationText: 'Inicializando localização...',
    );
  }

  // ──────────────────────────────────────────────────────────
  // onEvent: executado a cada `interval` ms (configurado em home_page.dart)
  // Aqui ocorre a captura e envio da localização.
  // ──────────────────────────────────────────────────────────
  @override
  Future<void> onEvent(DateTime timestamp, TaskStarter starter) async {
    _counter++;
    developer.log('[LocationTask] Execução #$_counter');

    try {
      // 1. Captura a posição atual do GPS
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.balanced,
          // Se não obter posição em 8s, lança TimeoutException
          timeLimit: Duration(seconds: 8),
        ),
      );

      // 2. Monta o payload de dados
      final Map<String, dynamic> locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,       // Precisão em metros
        'speed': position.speed,             // Velocidade em m/s
        'altitude': position.altitude,       // Altitude em metros
        'heading': position.heading,         // Direção em graus (0–360)
        'timestamp': FieldValue.serverTimestamp(), // Timestamp do servidor Firestore
        'dateTimeLocal': DateTime.now().toIso8601String(), // Horário local do dispositivo
        'counter': _counter,
      };

      // 3. Grava no histórico (subcoleção com todos os pontos)
      //    Cada add() cria um documento com ID automático
      await FirebaseFirestore.instance
          .collection('rastreamento')
          .doc(_deviceId)
          .collection('historico')
          .add(locationData);

      // 4. Atualiza o "último ponto" no documento raiz (para leitura rápida)
      //    merge: true preserva campos existentes (ex.: nome do dispositivo)
      await FirebaseFirestore.instance
          .collection('rastreamento')
          .doc(_deviceId)
          .set({
            ...locationData,
            'ultimaAtualizacao': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      final latStr = position.latitude.toStringAsFixed(5);
      final lngStr = position.longitude.toStringAsFixed(5);
      final speedKmh = (position.speed * 3.6).toStringAsFixed(1);

      developer.log('[LocationTask] ✓ Enviado → ($latStr, $lngStr) | ${speedKmh}km/h');

      // 5. Atualiza o texto da notificação com os dados mais recentes
      await FlutterForegroundTask.updateService(
        notificationTitle: '🟢 Rastreador Ativo (#$_counter)',
        notificationText: 'Lat: $latStr  Lng: $lngStr  |  $speedKmh km/h',
      );

      // 6. Envia dados para a UI (se o app estiver aberto)
      FlutterForegroundTask.sendDataToMain({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'counter': _counter,
        'status': 'ok',
      });
    } on TimeoutException {
      developer.log('[LocationTask] ⚠ Timeout ao obter localização');
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Rastreador Ativo',
        notificationText: '⚠ Aguardando sinal GPS...',
      );
      FlutterForegroundTask.sendDataToMain({'status': 'timeout'});
    } catch (e, stack) {
      developer.log('[LocationTask] ✗ Erro: $e\n$stack');
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Rastreador Ativo',
        notificationText: '✗ Erro ao obter localização',
      );
      FlutterForegroundTask.sendDataToMain({'status': 'error', 'message': e.toString()});
    }
  }

  // ──────────────────────────────────────────────────────────
  // onDestroy: chamado ao parar o serviço
  // ──────────────────────────────────────────────────────────
  @override
  void onDestroy(DateTime timestamp, TaskStarter starter) {
    developer.log('[LocationTask] Serviço encerrado em $timestamp após $_counter execuções.');
  }

  // Callbacks opcionais — mantidos para satisfazer a interface
  @override
  void onRepeatEvent(DateTime timestamp, TaskStarter starter) {}

  @override
  void onNotificationButtonPressed(String id) {
    developer.log('[LocationTask] Botão de notificação pressionado: $id');
  }
}
