# 📍 Rastreador GPS — Flutter + Firebase

Sistema de rastreamento de localização em tempo real com serviço em segundo plano.

\---

## 📦 Estrutura de Arquivos

```
lib/
  main.dart               → Ponto de entrada + inicialização do Firebase
  background\_service.dart → Handler do isolate de segundo plano (captura e envia GPS)
  permission\_service.dart → Lógica de permissões centralizada
  home\_page.dart          → UI principal com controles e exibição de dados

android/app/src/main/
  AndroidManifest.xml     → Permissões e declaração do ForegroundService

ios/Runner/
  Info.plist              → Permissões e Background Modes para iOS
```

\---

## 🚀 Como Configurar

### 1\. Instalar dependências

```bash
flutter pub get
```

### 2\. Configurar o Firebase

> \*\*Obrigatório\*\* — sem isso o app não compila.

1. Acesse https://console.firebase.google.com e crie um projeto
2. Instale o Firebase CLI: `npm install -g firebase-tools`
3. Instale o FlutterFire CLI: `dart pub global activate flutterfire\_cli`
4. Execute na raiz do projeto:

```bash
   flutterfire configure
   ```

   Isso gera automaticamente `lib/firebase\_options.dart` e adiciona
os arquivos nativos necessários (`google-services.json` no Android,
`GoogleService-Info.plist` no iOS).

5. Atualize o `main.dart` para usar as opções geradas:

   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

   ### 3\. Configurar Firestore

   No console do Firebase:

* Vá em **Firestore Database** → Criar banco
* Regras de segurança iniciais (desenvolvimento):

  ```
  rules\_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=\*\*} {
        allow read, write: if true; // ⚠ TROCAR antes de ir para produção!
      }
    }
  }
  ```

  ### 4\. Personalizar o ID do dispositivo

  Em `lib/background\_service.dart`, linha:

  ```dart
static const String \_deviceId = 'device\_001';
```

  Troque por um identificador único real (ex.: `device\_info\_plus` para obter o ID do hardware).





  apiKey:     AIzaSyD2JZF15ZMqoVBttJTeYp6MrSHpuGJD3so

  &#x20; 

  authDomain: rastreamento-adad3.firebaseapp.com

  &#x20;

  projectId:  rastreamento-adad3

  &#x20;

  appId:      1:212296863886:web:c8af7233ab1f5e9cb4b9df



  \---

  ## ▶️ Executar

  ```bash
# Android
flutter run

# iOS (requer Mac + Xcode)
flutter run -d ios
```

  \---

  ## 📊 Estrutura dos Dados no Firestore

  ```
rastreamento/
  {deviceId}/                    ← último ponto conhecido
    latitude: -12.9714
    longitude: -38.5014
    accuracy: 5.2
    speed: 13.8
    altitude: 22.0
    heading: 180.5
    timestamp: (server timestamp)
    dateTimeLocal: "2025-01-15T10:30:00.000"
    ultimaAtualizacao: (server timestamp)

    historico/
      {autoId}/                  ← um documento por captura
        (mesmos campos acima)
```

  \---

  ## ⚙️ Ajustar o intervalo de captura

  Em `home\_page.dart`, método `\_initForegroundTask()`:

  ```dart
eventAction: ForegroundTaskEventAction.repeat(
  5000, // ← altere aqui (em milissegundos)
),
```

|Valor|Frequência|Impacto na bateria|
|-|-|-|
|5000|5 segundos|Alto|
|15000|15 segundos|Médio|
|30000|30 segundos|Baixo|
|60000|1 minuto|Muito baixo|

\---

## 🔋 Notas Importantes

* **Android Doze Mode**: Em dispositivos com Android 6+, o sistema pode
atrazar ou bloquear o serviço para economizar bateria. O `WAKE\_LOCK`
e `allowWakelock: true` mitigam isso, mas fabricantes como Xiaomi,
Huawei e Samsung têm camadas extras de otimização que podem interferir.
* **Android 14+**: A permissão `FOREGROUND\_SERVICE\_LOCATION` é obrigatória
no manifest. Já está incluída.
* **iOS Limitações**: O iOS é mais restritivo com localização em segundo
plano. O app pode ser suspenso em situações de bateria baixa mesmo com
as permissões corretas.

\---

## 🛣️ Próximos Passos (Roadmap)

* \[ ] Identificação única do dispositivo (`device\_info\_plus`)
* \[ ] Autenticação com Firebase Auth
* \[ ] Dashboard web para visualização no mapa
* \[ ] Agrupamento por rota/missão
* \[ ] Alertas de geofence
* \[ ] Modo offline com sincronização posterior

