import 'package:flutter/material.dart';
import 'package:flutter_lulusin/login_page.dart';
import 'package:flutter_lulusin/register_page.dart';
import 'package:flutter_lulusin/Dashboard.dart';
import 'package:flutter_lulusin/soal_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lulusin',
      theme: ThemeData(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/siswa/dashboard': (context) => const Dashboard(),
        '/siswa/pengerjaan': (context) => const SoalPage()
      },
    );
  }
}
