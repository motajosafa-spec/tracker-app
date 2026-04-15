import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// ══════════════════════════════════════════════════════════════
// PermissionService
//
// Centraliza toda a lógica de permissões do app.
// Separado em classe própria para facilitar testes e reutilização.
//
// Fluxo de permissões no Android:
//   1. Notificações (Android 13+)
//   2. Localização em uso (location)
//   3. Localização em segundo plano (locationAlways)
//      → Android exige que o usuário vá às Configurações para isso
//
// No iOS, o permission_handler cuida do fluxo automaticamente.
// ══════════════════════════════════════════════════════════════
class PermissionService {
  // Solicita todas as permissões necessárias e retorna true se todas foram concedidas
  static Future<bool> requestAll(BuildContext context) async {
    // ── Passo 1: Notificações (Android 13+ / iOS) ──────────────
    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.status;
      if (notifStatus.isDenied) {
        developer.log('[Permissions] Solicitando notificações...');
        final result = await Permission.notification.request();
        developer.log('[Permissions] Notificações: $result');
        // Não bloqueia o fluxo se negada — apenas não mostrará notificações
      }
    }

    // ── Passo 2: Localização em uso ────────────────────────────
    final locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      developer.log('[Permissions] Solicitando localização...');
      final result = await Permission.location.request();
      developer.log('[Permissions] Localização: $result');

      if (result.isDenied || result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            title: 'Localização necessária',
            message: 'O Rastreador precisa de acesso à localização para funcionar. '
                'Por favor, conceda a permissão nas configurações.',
          );
        }
        return false;
      }
    }

    if (await Permission.location.isPermanentlyDenied) {
      if (context.mounted) {
        _showOpenSettingsDialog(context, 'localização');
      }
      return false;
    }

    // ── Passo 3: Localização em segundo plano ─────────────────
    // No Android 10+, esta permissão é separada e EXIGE que o usuário
    // vá às configurações do app e selecione "Permitir sempre".
    final bgStatus = await Permission.locationAlways.status;
    if (bgStatus.isDenied) {
      developer.log('[Permissions] Solicitando localização em segundo plano...');

      // Avisa o usuário antes de abrir o diálogo do sistema
      if (context.mounted) {
        final shouldRequest = await _showBackgroundLocationExplanation(context);
        if (!shouldRequest) return false;
      }

      final result = await Permission.locationAlways.request();
      developer.log('[Permissions] Localização em segundo plano: $result');

      if (result.isDenied || result.isPermanentlyDenied) {
        if (context.mounted) {
          _showOpenSettingsDialog(context, 'localização em segundo plano');
        }
        return false;
      }
    }

    if (await Permission.locationAlways.isPermanentlyDenied) {
      if (context.mounted) {
        _showOpenSettingsDialog(context, 'localização em segundo plano');
      }
      return false;
    }

    developer.log('[Permissions] ✓ Todas as permissões concedidas.');
    return true;
  }

  // Verifica (sem solicitar) se todas as permissões estão ativas
  static Future<PermissionSummary> check() async {
    final location = await Permission.location.status;
    final background = await Permission.locationAlways.status;
    final notification = Platform.isAndroid
        ? await Permission.notification.status
        : PermissionStatus.granted;

    return PermissionSummary(
      locationGranted: location.isGranted,
      backgroundGranted: background.isGranted,
      notificationGranted: notification.isGranted,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Diálogos auxiliares
  // ──────────────────────────────────────────────────────────

  static Future<bool> _showBackgroundLocationExplanation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Localização em Segundo Plano'),
        content: const Text(
          'Para rastrear sua localização com o app fechado, você precisará '
          'conceder a permissão "Permitir sempre" na próxima tela.\n\n'
          'Procure pela opção de localização e selecione "Permitir sempre".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ?? false;
  }

  static void _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showOpenSettingsDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permissão necessária'),
        content: Text(
          'A permissão de $permissionName foi negada permanentemente. '
          'Abra as configurações do app para concedê-la manualmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }
}

// Estrutura de dados com o status atual de cada permissão
class PermissionSummary {
  final bool locationGranted;
  final bool backgroundGranted;
  final bool notificationGranted;

  const PermissionSummary({
    required this.locationGranted,
    required this.backgroundGranted,
    required this.notificationGranted,
  });

  bool get allGranted => locationGranted && backgroundGranted && notificationGranted;
}
