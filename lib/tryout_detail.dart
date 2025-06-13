// lib/tryout_detail.dart
import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/soal_page.dart'; // Pastikan path ini benar
import 'package:flutter_lulusin/widget/navbar.dart';
import 'package:flutter_lulusin/widget/dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lulusin/model/subject.dart'; // Impor model Subject

// Definisi kelas AppColors yang sekarang disertakan
class AppColors {
  static const Color primary = Color(0xFF213555);
  static const Color secondary = Color(0xFF3E5879);
  static const Color neutral = Color(0xFFD8C4B6);
  static const Color background = Color(0xFFF5EFE7);
  static const Color white = Colors.white;
}

class TryoutPage extends StatefulWidget {
  final String tryoutId;

  const TryoutPage({super.key, required this.tryoutId});

  @override
  State<TryoutPage> createState() => _TryoutPageState();
}

class _TryoutPageState extends State<TryoutPage> {
  bool _isDropdownMenuOpen = false;
  final String _baseUrl = 'https://cardinal-helpful-simply.ngrok-free.app';

  String _tryoutName = 'Loading Tryout...';
  String _totalQuestions = '...';
  String _totalTime = '...';
  bool _isLoadingTryout = true;
  String _tryoutErrorMessage = '';
  String? _firstSubjectId;
  List<Subject> _fetchedAllSubjects =
      []; // State untuk menyimpan daftar mata pelajaran unik

  @override
  void initState() {
    super.initState();
    print(
        'DEBUG (tryout_detail.dart): TryoutPage received tryoutId: ${widget.tryoutId}');
    if (widget.tryoutId.isNotEmpty) {
      _fetchTryoutDetails(widget.tryoutId);
    } else {
      setState(() {
        _isLoadingTryout = false;
        _tryoutErrorMessage =
            'ID Tryout tidak valid. Silakan pilih tryout lagi.';
      });
      _showSnackBar('ID Tryout tidak valid.');
    }
  }

  void _toggleDropdownMenu() {
    setState(() {
      _isDropdownMenuOpen = !_isDropdownMenuOpen;
    });
  }

  void _handleDropdownItemSelected(String item) {
    _toggleDropdownMenu();
    if (item == 'Dashboard') {
      Navigator.pushReplacementNamed(context, '/siswa/dashboard');
    }
  }

  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final response =
          await http.post(Uri.parse('$_baseUrl/api/logout'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      });
      if (mounted) {
        await prefs.remove('auth_token');
        if (response.statusCode == 200) {
          _showSnackBar('Logout berhasil!');
        }
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Terjadi kesalahan jaringan saat logout.');
    }
  }

  Future<void> _fetchTryoutDetails(String idTryout) async {
    if (!mounted) return;
    setState(() {
      _isLoadingTryout = true;
      _tryoutErrorMessage = '';
      _firstSubjectId = null;
      _fetchedAllSubjects = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) _navigateToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/tryout/$idTryout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final tryoutData = responseData['getTryout'];
        final dataOverview = responseData['dataTryout'];

        List<Subject> parsedUniqueSubjects = [];
        String? tempFirstSubjectId;

        if (tryoutData is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              _tryoutName = tryoutData['tryout_name'] ?? 'Tryout Detail';
              if (dataOverview is Map<String, dynamic>) {
                _totalQuestions =
                    dataOverview['total_minimal_questions']?.toString() ??
                        'N/A';
                _totalTime =
                    dataOverview['total_time_limit']?.toString() ?? 'N/A';
              }
            });
          }

          // --- LOGIKA DEDUPLIKASI KRUSIAL DI SINI ---
          if (tryoutData['subjects'] is List) {
            final List<dynamic> subjectsJson = tryoutData['subjects'];
            Set<String> uniqueSubjectIds = {}; // Untuk melacak ID unik

            if (subjectsJson.isNotEmpty) {
              for (var subjectJson in subjectsJson) {
                if (subjectJson is Map<String, dynamic>) {
                  // Konversi ke string untuk konsistensi
                  final subjectIdString = subjectJson['subject_id']?.toString();
                  // Hanya tambahkan jika ID belum ada di Set
                  if (subjectIdString != null &&
                      !uniqueSubjectIds.contains(subjectIdString)) {
                    parsedUniqueSubjects.add(Subject.fromJson(subjectJson));
                    uniqueSubjectIds.add(subjectIdString);
                  }
                }
              }

              if (parsedUniqueSubjects.isNotEmpty) {
                tempFirstSubjectId = parsedUniqueSubjects.first.id;
              }
            }
          }
          // --- AKHIR LOGIKA DEDUPLIKASI ---
        }

        if (mounted) {
          setState(() {
            _fetchedAllSubjects =
                parsedUniqueSubjects; // Simpan daftar subjek yang sudah unik
            _firstSubjectId = tempFirstSubjectId;
            _isLoadingTryout = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _tryoutErrorMessage =
                'Gagal memuat detail tryout. Status: ${response.statusCode}';
            _isLoadingTryout = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tryoutErrorMessage = 'Terjadi kesalahan jaringan: $e';
          _isLoadingTryout = false;
        });
      }
      print('DEBUG (tryout_detail.dart): Fetch Tryout Details Error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Navbar(
        onMenuPressed: _toggleDropdownMenu,
        onLogoutPressed: _logoutUser,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDropdownMenuOpen)
            DropdownMenu(
              onItemSelected: _handleDropdownItemSelected,
            ),
          Expanded(
            child: _isLoadingTryout
                ? const Center(child: CircularProgressIndicator())
                : _tryoutErrorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _tryoutErrorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tryoutName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInfoBox(
                                    icon: Icons.list_alt,
                                    label: 'Jumlah Soal',
                                    value: _totalQuestions),
                                _buildInfoBox(
                                    icon: Icons.timer,
                                    label: 'Waktu',
                                    value: '$_totalTime Menit'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTryoutRules(),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Pastikan _firstSubjectId dan _fetchedAllSubjects sudah terisi
                                  if (_firstSubjectId != null &&
                                      _firstSubjectId!.isNotEmpty &&
                                      _fetchedAllSubjects.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SoalPage(
                                          tryoutId: widget.tryoutId,
                                          subjectId: _firstSubjectId!,
                                          // PERBAIKAN: Teruskan daftar mata pelajaran yang sudah unik
                                          allSubjects: _fetchedAllSubjects,
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showSnackBar(
                                        'Tidak dapat memulai: Detail mata pelajaran tidak lengkap atau tidak ditemukan.');
                                    print(
                                        'DEBUG (tryout_detail.dart): Cannot start. _firstSubjectId: $_firstSubjectId, _fetchedAllSubjects count: ${_fetchedAllSubjects.length}');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Mulai',
                                  style: TextStyle(
                                      color: AppColors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk InfoBox dan TryoutRules tetap sama
  Widget _buildInfoBox(
      {required IconData icon, required String label, required String value}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTryoutRules() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Peraturan Tryout',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Persiapan Sebelum Tryout\n'
            '1. Pastikan perangkat dalam kondisi baik dan koneksi stabil.\n'
            '2. Gunakan browser terbaru.\n'
            '3. Siapkan alat tulis jika diperlukan.\n'
            '4. Cari tempat yang nyaman dan minim gangguan.\n'
            '5. Pastikan baterai cukup atau sambungkan ke charger.',
            style: TextStyle(color: AppColors.white),
          ),
          SizedBox(height: 12),
          Text(
            'Syarat Tryout Berlangsung:\n'
            '1. Tidak membuka tab baru atau aplikasi lain.\n'
            '2. Tidak refresh halaman.\n'
            '3. Tidak keluar dari halaman ini.\n'
            '4. Tidak menggunakan bantuan orang lain.\n'
            '5. Tidak mengambil gambar soal.\n'
            '6. Mengisi semua soal.\n'
            '7. Pelanggaran akan membuat tryout dihentikan otomatis.',
            style: TextStyle(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
