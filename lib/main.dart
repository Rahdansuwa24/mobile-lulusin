// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_lulusin/explanation_detail.dart'; // Mengandung ExplanationDetailPage
import 'package:flutter_lulusin/login_page.dart';
import 'package:flutter_lulusin/nilai_tryout.dart'; // Halaman NilaiTryout (jika berbeda dari TryoutResultPage)
import 'package:flutter_lulusin/pembahasan_page.dart'; // SEKARANG HARUSNYA MENGANDUNG TryoutResultPage
import 'package:flutter_lulusin/register_page.dart';
import 'package:flutter_lulusin/Dashboard.dart'; // Mengandung kelas Dashboard (untuk /siswa/dashboard)
import 'package:flutter_lulusin/soal_page.dart';
import 'package:flutter_lulusin/listTryout.dart'; // Mengandung DashboardPage (untuk daftar tryout /siswa/tryout)
import 'package:flutter_lulusin/tryout_detail.dart'; // Mengandung TryoutPage

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
      initialRoute: '/', // Rute awal aplikasi
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/siswa/dashboard': (context) =>
            const Dashboard(), // Halaman dashboard utama siswa
        '/siswa/tryout': (context) => const DashboardPage(),
        '/siswa/explanation_fallback': (context) => const ExplanationDetailPage(
              tryoutId: 'DEFAULT_TRYOUT_ID',
              subjectId: 'DEFAULT_SUBJECT_ID',
            ),
      },
      onGenerateRoute: (settings) {
        print(
            'DEBUG (main.dart): Route requested: ${settings.name}, Arguments: ${settings.arguments}');
        if (settings.name == '/siswa/tryout/hasil') {
          final args = settings.arguments;
          if (args is String && args.isNotEmpty) {
            print(
                'DEBUG (main.dart): Navigating to TryoutResultPage with tryoutId: $args');
            return MaterialPageRoute(
              builder: (context) {
                return TryoutResultPage(tryoutId: args);
              },
            );
          }
          print(
              'DEBUG (main.dart): Error: tryoutId argument is missing or invalid for /siswa/tryout/hasil. Args: $args');
          return MaterialPageRoute(
              builder: (context) => const Text(
                  'Error: Tryout ID diperlukan untuk melihat hasil.'));
        }
        if (settings.name == '/siswa/tryout/detail') {
          final args = settings.arguments;
          if (args is String && args.isNotEmpty) {
            print(
                'DEBUG (main.dart): Navigating to TryoutPage with tryoutId: $args');
            return MaterialPageRoute(
              builder: (context) {
                return TryoutPage(
                  tryoutId: args,
                );
              },
            );
          }
          print(
              'DEBUG (main.dart): Error: tryoutId argument is missing or invalid for /siswa/tryout/detail. Args: $args');
          return MaterialPageRoute(
              builder: (context) => const Text('Error: Tryout ID diperlukan.'));
        }
        if (settings.name == '/siswa/pengerjaan') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            // Lebih aman menggunakan Map<String, dynamic>
            final tryoutId = args['tryoutId'] as String?;
            final subjectId = args['subjectId'] as String?;
            if (tryoutId != null &&
                tryoutId.isNotEmpty &&
                subjectId != null &&
                subjectId.isNotEmpty) {
              print(
                  'DEBUG (main.dart): Navigating to SoalPage with tryoutId: $tryoutId, subjectId: $subjectId.');
              return MaterialPageRoute(
                builder: (context) {
                  return SoalPage(
                    tryoutId: tryoutId,
                    subjectId: subjectId,
                    allSubjects: const [], // Sediakan list kosong atau data yang sesuai
                  );
                },
              );
            }
          }
          print(
              'DEBUG (main.dart): Error: Tryout ID or Subject ID arguments are missing or invalid for /siswa/pengerjaan. Args: $args');
          return MaterialPageRoute(
              builder: (context) => const Text(
                  'Error: Tryout ID dan Subject ID diperlukan untuk SoalPage.'));
        }
        if (settings.name == '/siswa/explanation') {
          final args = settings.arguments;
          if (args is Map<String, String>) {
            final tryoutId = args['tryoutId'];
            final subjectId = args['subjectId'];
            if (tryoutId != null && subjectId != null) {
              return MaterialPageRoute(
                builder: (context) => ExplanationDetailPage(
                  tryoutId: tryoutId,
                  subjectId: subjectId,
                ),
              );
            }
          }
          return MaterialPageRoute(
            builder: (context) => const Text(
                'Error: Argumen tidak lengkap untuk halaman pembahasan.'),
          );
        }

        print('DEBUG (main.dart): Unknown route requested: ${settings.name}');
        return MaterialPageRoute(
            builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text("Error")),
                  body: Center(
                      child: Text(
                          'Error: Rute tidak dikenal (${settings.name}).')),
                ));
      },
    );
  }
}
