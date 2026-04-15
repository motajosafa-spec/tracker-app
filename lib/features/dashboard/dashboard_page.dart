
import 'package:flutter/material.dart';
import '../map/map_page.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Systema")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MapPage()),
            );
          },
          child: Text("Abrir Mapa"),
        ),
      ),
    );
  }
}
