// lib/dashboard.dart
import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/widget/navbar.dart';
import 'package:flutter_lulusin/widget/dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lulusin/tryout_detail.dart'; // Import the TryoutPage
import 'package:flutter_lulusin/pembahasan_page.dart'; // Import SoalPembahasanPage

// Model data untuk Tryout yang Belum Dikerjakan (tidak ada perubahan di sini, sudah bagus)
class NotDoneTryout {
  final String id;
  final String title;

  NotDoneTryout({required this.id, required this.title});

  factory NotDoneTryout.fromJson(Map<String, dynamic> json) {
    final String id = json['tryout_id']?.toString() ?? '';
    final String title =
        (json['tryout_name'] as String?) ?? 'Nama Tryout Tidak Tersedia';
    return NotDoneTryout(id: id, title: title);
  }
}

// Model data untuk Top Scores
class TopTryoutScore {
  final String id; // <-- TAMBAHKAN ID DI SINI
  final String subject;
  final double score;

  TopTryoutScore(
      {required this.id,
      required this.subject,
      required this.score}); // <-- PERBARUI CONSTRUCTOR

  factory TopTryoutScore.fromJson(Map<String, dynamic> json) {
    // Pastikan 'id_tryout' adalah kunci yang benar dari API untuk ID tryout
    final String id =
        json['id_tryout']?.toString() ?? ''; // <-- AMBIL ID DARI API

    // Menggunakan 'tryout_name' dari JSON respons API, dan menangani null
    final String subject =
        (json['tryout_name'] as String?) ?? 'Mata Pelajaran Tidak Tersedia';

    // Menggunakan 'average_score' dari JSON respons API, dan menangani null/non-numeric
    final double score = (json['average_score'] as num?)?.toDouble() ?? 0.0;

    return TopTryoutScore(
      id: id, // <-- SERAHKAN ID KE CONSTRUCTOR
      subject: subject,
      score: score,
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isDropdownMenuOpen = false;
  final String _baseUrl = 'http://localhost:3000'; // Base URL backend Anda

  List<NotDoneTryout> _notDoneTryouts = [];
  List<TopTryoutScore> _topTryoutScores = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  void _toggleDropdownMenu() {
    setState(() {
      _isDropdownMenuOpen = !_isDropdownMenuOpen;
    });
  }

  void _handleDropdownItemSelected(String item) {
    _toggleDropdownMenu(); // Tutup dropdown setelah item dipilih

    if (item == 'Dashboard') {
      print('Navigating to Dashboard');
      // Already on dashboard, could refresh or do nothing
    } else if (item == 'Tryout') {
      print('Navigating to Tryout List');
      // Anda bisa menambahkan Navigator.pushReplacementNamed(context, '/siswa/tryout');
    }
  }

  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        _showSnackBar(
            'Tidak ada token ditemukan. Anda sudah logout atau sesi berakhir.');
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('auth_token');
        _showSnackBar('Logout berhasil!');
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _showSnackBar(
            'Logout gagal: ${responseData['message'] ?? 'Terjadi kesalahan tidak dikenal.'}');
        await prefs.remove('auth_token');
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Gagal terhubung ke server saat logout: ${e.message}');
      print('Logout ClientException: ${e.message}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat logout: $e');
      print('Logout Error: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      print('DEBUG: Token retrieved from SharedPreferences: $token');

      if (token == null) {
        _showSnackBar('Anda tidak terautentikasi. Silakan login kembali.');
        print('DEBUG: Token is null, redirecting to login.');
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/dashboard'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          'DEBUG: Dashboard API Response Status Code: ${response.statusCode}');
      print('DEBUG: Dashboard API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('DEBUG: Dashboard data loaded successfully.');

        try {
          setState(() {
            _notDoneTryouts = (responseData['notDoneTryouts'] as List? ?? [])
                .map((json) => NotDoneTryout.fromJson(json))
                .toList();
            _topTryoutScores = (responseData['topTryoutScores'] as List? ?? [])
                .map((json) => TopTryoutScore.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } catch (parseError) {
          setState(() {
            _errorMessage = 'Gagal memproses data dashboard: $parseError';
            _isLoading = false;
          });
          _showSnackBar(_errorMessage);
          print('DEBUG: Data Parsing Error: $parseError');
        }
      } else if (response.statusCode == 401) {
        _showSnackBar('Sesi Anda telah berakhir. Silakan login kembali.');
        print('DEBUG: Received 401, session expired. Redirecting to login.');
        await prefs.remove('auth_token');
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
      } else {
        String apiErrorMessage =
            'Terjadi kesalahan saat memuat data dashboard.';
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          apiErrorMessage = responseData['message'] ?? apiErrorMessage;
        } catch (_) {
          apiErrorMessage =
              'Server merespons dengan status ${response.statusCode}, namun pesan tidak tersedia.';
        }
        setState(() {
          _errorMessage = apiErrorMessage;
          _isLoading = false;
        });
        _showSnackBar(_errorMessage);
        print(
            'DEBUG: API Error (Status ${response.statusCode}): $_errorMessage');
      }
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan jaringan: ${e.message}. Pastikan Anda terhubung ke internet.';
        _isLoading = false;
      });
      _showSnackBar(_errorMessage);
      print('DEBUG: Fetch Dashboard Data ClientException: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
        _isLoading = false;
      });
      _showSnackBar(_errorMessage);
      print('DEBUG: Fetch Dashboard Data General Exception: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: Navbar(
        onMenuPressed: _toggleDropdownMenu,
        onLogoutPressed: _logoutUser,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchDashboardData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isDropdownMenuOpen)
                        DropdownMenu(
                          onItemSelected: _handleDropdownItemSelected,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Color(0xFF1C3554),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDailyQuoteCard(),
                            const SizedBox(height: 20),
                            _buildDreamCampusSection(),
                            const SizedBox(height: 20),
                            _buildSectionTitle('Belum Dikerjakan'),
                            const SizedBox(height: 10),
                            if (_notDoneTryouts.isEmpty)
                              const Text(
                                'Tidak ada tryout yang belum dikerjakan.',
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontFamily: 'Poppins'),
                              )
                            else
                              ..._notDoneTryouts.map((tryout) =>
                                  _buildTryoutCard(tryout.title, tryout.id)),
                            const SizedBox(height: 20),
                            _buildSectionTitle('Telah Dikerjakan (Top Scores)'),
                            const SizedBox(height: 10),
                            if (_topTryoutScores.isEmpty)
                              const Text(
                                'Tidak ada top score tryout.',
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontFamily: 'Poppins'),
                              )
                            else
                              // Meneruskan seluruh objek score ke _buildScoreCard
                              ..._topTryoutScores.map((score) =>
                                  _buildScoreCard(
                                      score)) // <-- Kirim seluruh objek score
                            ,
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDailyQuoteCard() {
    final DateTime now = DateTime.now();
    final String dayOfMonth = now.day.toString();
    final String dayOfWeek = _getDayOfWeek(now.weekday);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3554),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E4B6E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  dayOfWeek,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
                Text(
                  dayOfMonth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Usaha hari ini, kampus impian esok hari',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }

  Widget _buildDreamCampusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3554),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'High Scores (Top 3)',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 15),
          if (_topTryoutScores.isEmpty)
            const Text(
              'Tidak ada data skor tertinggi.',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            )
          else
            Column(
              children: _topTryoutScores.take(3).map((score) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          score.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Text(
                        score.score.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Color(0xFF8CC152),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3554),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTryoutCard(String title, String tryoutId) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff3a5c8d),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffe2d5cd),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TryoutPage(tryoutId: tryoutId),
                ),
              );
            },
            child: const Text(
              'Lihat',
              style: TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget baru untuk menampilkan skor
  // Sekarang menerima objek TopTryoutScore penuh
  Widget _buildScoreCard(TopTryoutScore score) {
    // <-- Menerima objek TopTryoutScore
    return GestureDetector(
      // Membuat card bisa diklik
      onTap: () {
        // Redirect ke halaman pembahasan menggunakan ID tryout dari score
        Navigator.pushNamed(
          context,
          '/siswa/tryout/pembahasan',
          arguments: score.id, // Meneruskan ID tryout sebagai argumen
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff3a5c8d),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                score.subject, // Menggunakan subject dari objek score
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Text(
              score.score
                  .toStringAsFixed(2), // Menggunakan score dari objek score
              style: const TextStyle(
                color: Color(0xffe2d5cd),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10), // Memberikan sedikit jarak
            const Icon(
              Icons.arrow_forward_ios, // Tambahkan ikon panah
              color: Color(0xffe2d5cd),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
