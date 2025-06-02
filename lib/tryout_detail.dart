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
  final String _baseUrl = 'http://localhost:3000';

  String _tryoutName = 'Loading Tryout...';
  String _totalQuestions = '...';
  String _totalTime = '...';
  bool _isLoadingTryout = true;
  String _tryoutErrorMessage = '';
  String? _firstSubjectId;
  List<Subject> _fetchedAllSubjects =
      []; // State untuk menyimpan daftar semua mata pelajaran

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
        print(
            'DEBUG (tryout_detail.dart): Error: TryoutPage received an empty tryoutId.');
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
    } else if (item == 'Tryout') {
      print(
          'DEBUG (tryout_detail.dart): Navigating to Tryout List (or staying on current page)');
      // Navigator.pushReplacementNamed(context, '/siswa/tryout_list');
    }
  }

  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        _showSnackBar('Tidak ada token ditemukan. Anda sudah logout.');
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          await prefs.remove('auth_token');
          _showSnackBar('Logout berhasil!');
          Navigator.pushReplacementNamed(context, '/');
        } else {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          _showSnackBar(
              'Logout gagal: ${responseData['message'] ?? 'Terjadi kesalahan.'}');
          await prefs.remove('auth_token');
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Terjadi kesalahan jaringan saat logout: $e');
      print('DEBUG (tryout_detail.dart): Logout Error: $e');
    }
  }

  Future<void> _fetchTryoutDetails(String idTryout) async {
    if (!mounted) return;
    setState(() {
      _isLoadingTryout = true;
      _tryoutErrorMessage = '';
      _firstSubjectId = null;
      _fetchedAllSubjects = []; // Reset daftar mata pelajaran
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          _showSnackBar('Anda tidak terautentikasi. Silakan login kembali.');
          Navigator.pushReplacementNamed(context, '/');
        }
        return;
      }

      // Endpoint untuk detail tryout, yang juga berisi daftar mata pelajaran
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/student/tryout/$idTryout'), // Sesuai dengan contoh JSON Anda
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print(
            'DEBUG (tryout_detail.dart): API Response for Tryout Details (tryoutId: $idTryout): ${response.body}');

        setState(() {
          final tryoutData = responseData['getTryout'];
          final dataOverview = responseData[
              'dataTryout']; // Menggunakan 'dataTryout' sesuai contoh JSON

          if (tryoutData is Map<String, dynamic>) {
            _tryoutName = tryoutData['tryout_name'] ?? 'Tryout Detail';

            if (dataOverview is Map<String, dynamic>) {
              _totalQuestions =
                  dataOverview['total_minimal_questions']?.toString() ?? 'N/A';
              _totalTime =
                  dataOverview['total_time_limit']?.toString() ?? 'N/A';
            } else {
              _totalQuestions = 'N/A';
              _totalTime = 'N/A';
            }

            // Ekstrak dan parse daftar mata pelajaran
            if (tryoutData['subjects'] is List) {
              final List<dynamic> subjectsJson = tryoutData['subjects'];
              if (subjectsJson.isNotEmpty) {
                _fetchedAllSubjects = subjectsJson
                    .map((json) =>
                        Subject.fromJson(json as Map<String, dynamic>))
                    .toList();

                // Ambil ID mata pelajaran pertama dari daftar yang sudah diparsing
                _firstSubjectId = _fetchedAllSubjects.first.id;

                if (_firstSubjectId == null || _firstSubjectId!.isEmpty) {
                  print(
                      'DEBUG (tryout_detail.dart): subject_id is null or empty for the first subject object.');
                  _firstSubjectId = null; // Pastikan null jika tidak valid
                } else {
                  print(
                      'DEBUG (tryout_detail.dart): First subject ID found: $_firstSubjectId');
                }
              } else {
                _firstSubjectId = null;
                _fetchedAllSubjects =
                    []; // Pastikan list kosong jika tidak ada subjek
                print(
                    'DEBUG (tryout_detail.dart): "subjects" array is empty in tryoutData.');
              }
            } else {
              _firstSubjectId = null;
              _fetchedAllSubjects = [];
              print(
                  'DEBUG (tryout_detail.dart): "subjects" array is missing or not a list in tryoutData.');
            }
          } else {
            _tryoutName = 'Tryout Detail Not Found';
            _totalQuestions = 'N/A';
            _totalTime = 'N/A';
            _firstSubjectId = null;
            _fetchedAllSubjects = [];
            _tryoutErrorMessage =
                'Format respons API tidak sesuai: "getTryout" tidak ditemukan atau bukan objek.';
          }
          _isLoadingTryout = false;
        });
      } else if (response.statusCode == 401) {
        _showSnackBar('Sesi Anda telah berakhir. Silakan login kembali.');
        await prefs.remove('auth_token');
        Navigator.pushReplacementNamed(context, '/');
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _tryoutErrorMessage = responseData['message'] ??
              'Gagal memuat detail tryout. Status: ${response.statusCode}';
          _isLoadingTryout = false;
        });
        _showSnackBar(_tryoutErrorMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tryoutErrorMessage = 'Terjadi kesalahan jaringan: $e';
          _isLoadingTryout = false;
        });
        _showSnackBar(_tryoutErrorMessage);
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

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
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
                                    // Tambahkan pengecekan _fetchedAllSubjects
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SoalPage(
                                          tryoutId: widget.tryoutId,
                                          subjectId: _firstSubjectId!,
                                          // PERBAIKAN: Teruskan daftar mata pelajaran yang sudah di-fetch
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
}
