import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Halo"),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Text("Hallo world"),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Random',
          onPressed: null,
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }
}
