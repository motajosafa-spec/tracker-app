// Arquivo gerado automaticamente com as credenciais do Firebase
// Projeto: rastreamento-adad3

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS não configurado. Execute flutterfire configure para iOS.',
        );
      default:
        throw UnsupportedError(
          'Plataforma não suportada: $defaultTargetPlatform',
        );
    }
  }

  // Configuração Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAalQQDrMkoE4XXC3Yr2PXtv9zDP9-QVMQ',
    appId: '1:212296863886:android:81700211444f85b6b4b9df',
    messagingSenderId: '212296863886',
    projectId: 'rastreamento-adad3',
    storageBucket: 'rastreamento-adad3.firebasestorage.app',
  );

  // Configuração Web (para o Dashboard)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAalQQDrMkoE4XXC3Yr2PXtv9zDP9-QVMQ',
    appId: '1:212296863886:web:placeholder',
    messagingSenderId: '212296863886',
    projectId: 'rastreamento-adad3',
    storageBucket: 'rastreamento-adad3.firebasestorage.app',
  );
}
