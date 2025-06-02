// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_lulusin/login_page.dart';
import 'package:flutter_lulusin/nilai_tryout.dart';
import 'package:flutter_lulusin/pembahasan_page.dart'; // Ini kemungkinan SoalPembahasanPage Anda
import 'package:flutter_lulusin/register_page.dart';
import 'package:flutter_lulusin/Dashboard.dart'; // Mengimpor kelas Dashboard
import 'package:flutter_lulusin/soal_page.dart';
import 'package:flutter_lulusin/listTryout.dart'; // Mengimpor kelas DashboardPage (atau TryoutListPage)
import 'package:flutter_lulusin/tryout_detail.dart';

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
      // Definisi rute statis yang tidak memerlukan argumen dinamis
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/siswa/dashboard': (context) => const Dashboard(),
        '/siswa/tryout': (context) =>
            const DashboardPage(), // Untuk daftar tryout
        '/siswa/tryout/hasil': (context) => const NilaiTryout(),
        // Rute '/siswa/tryout/pembahasan' dipindahkan ke onGenerateRoute
        // '/siswa/tryout/pembahasan': (context) => const SoalPembahasanPage(), // DIHAPUS DARI SINI
      },
      // Gunakan onGenerateRoute untuk rute yang perlu dilewatkan argumen
      onGenerateRoute: (settings) {
        // Log untuk debugging: Apa yang diterima onGenerateRoute
        print(
            'DEBUG (main.dart): Route requested: ${settings.name}, Arguments: ${settings.arguments}');

        // Menangani rute '/siswa/tryout/pembahasan' (halaman pembahasan)
        if (settings.name == '/siswa/tryout/pembahasan') {
          final args = settings.arguments;
          // Pastikan argumen adalah String (tryoutId)
          if (args is String && args.isNotEmpty) {
            print(
                'DEBUG (main.dart): Navigating to SoalPembahasanPage with tryoutId: $args');
            return MaterialPageRoute(
              builder: (context) {
                // Pastikan SoalPembahasanPage memiliki constructor yang menerima tryoutId
                return SoalPembahasanPage(tryoutId: args);
              },
            );
          }
          // Jika argumen tidak ada atau tidak valid
          print(
              'DEBUG (main.dart): Error: tryoutId argument is missing or invalid for /siswa/tryout/pembahasan. Args: $args');
          return MaterialPageRoute(
              builder: (context) =>
                  const Text('Error: Tryout ID diperlukan untuk pembahasan.'));
        }

        // Menangani rute '/siswa/tryout/id' (halaman detail tryout)
        if (settings.name == '/siswa/tryout/id') {
          final args = settings.arguments;
          if (args is String && args.isNotEmpty) {
            print(
                'DEBUG (main.dart): Navigating to TryoutPage with tryoutId: $args');
            return MaterialPageRoute(
              builder: (context) {
                return TryoutPage(
                  tryoutId: args, // Lewatkan tryoutId yang diterima
                );
              },
            );
          }
          // Jika argumen tidak ada atau tidak valid
          print(
              'DEBUG (main.dart): Error: tryoutId argument is missing or invalid for /siswa/tryout/id. Args: $args');
          return MaterialPageRoute(
              builder: (context) => const Text('Error: Tryout ID diperlukan.'));
        }

        // Menangani rute '/siswa/pengerjaan' (halaman soal)
        if (settings.name == '/siswa/pengerjaan') {
          final args = settings.arguments;
          if (args is Map<String, String>) {
            final tryoutId = args['tryoutId'];
            final subjectId = args['subjectId'];

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
                    allSubjects: [],
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

        // Fallback untuk rute yang tidak dikenal
        print('DEBUG (main.dart): Unknown route requested: ${settings.name}');
        return MaterialPageRoute(
            builder: (context) => const Text('Error: Rute tidak dikenal.'));
      },
    );
  }
}
