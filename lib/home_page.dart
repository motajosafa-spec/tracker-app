import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'main.dart';             // startBackgroundService
import 'permission_service.dart';

// ══════════════════════════════════════════════════════════════
// HomePage
//
// Tela principal do app. Responsabilidades:
//   - Inicializar as configurações do serviço em primeiro plano
//   - Solicitar permissões ao usuário
//   - Iniciar / parar o serviço de rastreamento
//   - Receber atualizações de localização do isolate de segundo plano
//   - Exibir dados em tempo real na UI
// ══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Estado do serviço
  bool _isServiceRunning = false;
  bool _isLoading = false;

  // Dados recebidos do serviço em segundo plano
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  double? _speed;
  int _updateCount = 0;
  String _statusText = 'Aguardando início...';
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    _registerReceivePort(); // Escuta mensagens do serviço em segundo plano
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Inicialização do serviço em primeiro plano
  //
  // Define COMO o serviço se comporta (intervalo, notificação, etc.)
  // Deve ser chamado antes de qualquer startService().
  // ──────────────────────────────────────────────────────────
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_tracking_channel',
        channelName: 'Serviço de Localização',
        channelDescription: 'Mantém o rastreamento de localização ativo em segundo plano.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // Botão de parar diretamente da notificação
        buttons: [
          const NotificationButton(id: 'stop', text: 'Parar'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          5000, // Intervalo entre capturas: 5 segundos
        ),
        autoRunOnBoot: false,    // Não inicia automaticamente ao ligar
        allowWakelock: true,     // Mantém CPU ativa para o serviço
        allowScheduleExactAlarms: true,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Registra o callback que recebe dados do isolate de fundo
  // ──────────────────────────────────────────────────────────
  void _registerReceivePort() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  // Callback chamado quando o isolate de fundo envia dados via sendDataToMain()
  void _onReceiveTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      final status = data['status'] as String?;

      setState(() {
        _lastUpdate = DateTime.now();

        if (status == 'ok') {
          _latitude = data['latitude'] as double?;
          _longitude = data['longitude'] as double?;
          _accuracy = data['accuracy'] as double?;
          _speed = data['speed'] as double?;
          _updateCount = data['counter'] as int? ?? _updateCount;
          _statusText = 'Localização atualizada';
        } else if (status == 'timeout') {
          _statusText = '⚠ Aguardando sinal GPS...';
        } else if (status == 'error') {
          _statusText = '✗ ${data['message'] ?? 'Erro desconhecido'}';
        }
      });
    }
  }

  // ──────────────────────────────────────────────────────────
  // Iniciar rastreamento
  // ──────────────────────────────────────────────────────────
  Future<void> _startTracking() async {
    setState(() => _isLoading = true);

    try {
      // 1. Solicita permissões
      final granted = await PermissionService.requestAll(context);
      if (!granted) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Inicia o serviço em primeiro plano
      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'Rastreador Ativo',
        notificationText: 'Inicializando...',
        callback: startBackgroundService,
      );

      developer.log('[HomePage] startService result: $result');

      setState(() {
        _isServiceRunning = true;
        _isLoading = false;
        _statusText = 'Serviço iniciado. Aguardando GPS...';
        _updateCount = 0;
      });
    } catch (e) {
      developer.log('[HomePage] Erro ao iniciar serviço: $e');
      setState(() {
        _isLoading = false;
        _statusText = 'Erro ao iniciar: $e';
      });
    }
  }

  // ──────────────────────────────────────────────────────────
  // Parar rastreamento
  // ──────────────────────────────────────────────────────────
  Future<void> _stopTracking() async {
    setState(() => _isLoading = true);

    await FlutterForegroundTask.stopService();

    setState(() {
      _isServiceRunning = false;
      _isLoading = false;
      _statusText = 'Rastreamento parado.';
    });

    developer.log('[HomePage] Serviço parado após $_updateCount atualizações.');
  }

  // ──────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _isServiceRunning;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Rastreador GPS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Card de Status ─────────────────────────────────
              _StatusCard(
                isActive: isActive,
                statusText: _statusText,
                updateCount: _updateCount,
                lastUpdate: _lastUpdate,
              ),

              const SizedBox(height: 16),

              // ── Cards de Dados GPS ─────────────────────────────
              Expanded(
                child: _DataGrid(
                  latitude: _latitude,
                  longitude: _longitude,
                  accuracy: _accuracy,
                  speed: _speed,
                ),
              ),

              const SizedBox(height: 24),

              // ── Botões de Controle ─────────────────────────────
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (!isActive)
                  ElevatedButton.icon(
                    onPressed: _startTracking,
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text(
                      'INICIAR RASTREAMENTO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _stopTracking,
                    icon: const Icon(Icons.stop_rounded, size: 28),
                    label: const Text(
                      'PARAR RASTREAMENTO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 12),

              // Aviso de coleta de dados
              Text(
                'Os dados são enviados ao Firebase Firestore a cada 5 segundos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widget: Card de Status
// ══════════════════════════════════════════════════════════════
class _StatusCard extends StatelessWidget {
  final bool isActive;
  final String statusText;
  final int updateCount;
  final DateTime? lastUpdate;

  const _StatusCard({
    required this.isActive,
    required this.statusText,
    required this.updateCount,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF00C896) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Indicador pulsante
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'RASTREAMENTO ATIVO' : 'RASTREAMENTO PARADO',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          if (updateCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$updateCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'envios',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widget: Grid de dados GPS
// ══════════════════════════════════════════════════════════════
class _DataGrid extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? speed;

  const _DataGrid({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.speed,
  });

  @override
  Widget build(BuildContext context) {
    final speedKmh = speed != null ? (speed! * 3.6) : null;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _DataTile(
          icon: Icons.north_rounded,
          label: 'Latitude',
          value: latitude?.toStringAsFixed(6) ?? '--',
          unit: '°',
          color: const Color(0xFF4FC3F7),
        ),
        _DataTile(
          icon: Icons.east_rounded,
          label: 'Longitude',
          value: longitude?.toStringAsFixed(6) ?? '--',
          unit: '°',
          color: const Color(0xFF4FC3F7),
        ),
        _DataTile(
          icon: Icons.speed_rounded,
          label: 'Velocidade',
          value: speedKmh?.toStringAsFixed(1) ?? '--',
          unit: 'km/h',
          color: const Color(0xFFFFB74D),
        ),
        _DataTile(
          icon: Icons.radar_rounded,
          label: 'Precisão',
          value: accuracy?.toStringAsFixed(1) ?? '--',
          unit: 'm',
          color: const Color(0xFFA5D6A7),
        ),
      ],
    );
  }
}

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _DataTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
