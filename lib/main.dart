
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SystemaApp());
}

class SystemaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Systema',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: DashboardPage(),
    );
  }
}
