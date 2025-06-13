// lib/dashboard.dart
import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/widget/navbar.dart';
import 'package:flutter_lulusin/widget/dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lulusin/tryout_detail.dart'; // Import the TryoutPage
import 'package:flutter_lulusin/pembahasan_page.dart'; // Import SoalPembahasanPage

// Model data untuk Tryout yang Belum Dikerjakan
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
  final String id;
  final String subject;
  final double score;

  TopTryoutScore(
      {required this.id, required this.subject, required this.score});

  factory TopTryoutScore.fromJson(Map<String, dynamic> json) {
    final String id = json['id_tryout']?.toString() ?? '';

    final String subject =
        (json['tryout_name'] as String?) ?? 'Mata Pelajaran Tidak Tersedia';

    final double score = (json['average_score'] as num?)?.toDouble() ?? 0.0;

    return TopTryoutScore(
      id: id,
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
  final String _baseUrl =
      'https://cardinal-helpful-simply.ngrok-free.app'; // Base URL backend Anda

  // State untuk menyimpan data dari API
  Map<String, dynamic> _countdownData = {};
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
    _toggleDropdownMenu();
    if (item == 'Dashboard') {
      print('Navigating to Dashboard');
    } else if (item == 'Tryout') {
      print('Navigating to Tryout List');
      // Navigator.pushReplacementNamed(context, '/siswa/tryout');
    }
  }

  Future<void> _logoutUser() async {
    // ... (Fungsi logout Anda tetap sama)
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
        'ngrok-skip-browser-warning': 'true',
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

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) {
        _showSnackBar('Anda tidak terautentikasi. Silakan login kembali.');
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        setState(() {
          // Parsing data countdown
          _countdownData =
              responseData['countdownSNBT'] as Map<String, dynamic>? ?? {};

          // Parsing data tryout yang belum dikerjakan
          _notDoneTryouts = (responseData['notDoneTryouts'] as List? ?? [])
              .map((json) => NotDoneTryout.fromJson(json))
              .toList();

          // Parsing data top scores
          _topTryoutScores = (responseData['topTryoutScores'] as List? ?? [])
              .map((json) => TopTryoutScore.fromJson(json))
              .toList();

          _isLoading = false;
        });
      } else {
        // Handle error status code dari server
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              errorData['message'] ?? 'Gagal memuat data dashboard.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan jaringan: ${e.toString()}';
          _isLoading = false;
        });
      }
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
                            // PERUBAHAN: Memanggil _buildCountdownCard
                            _buildCountdownCard(),
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
                              ..._topTryoutScores
                                  .map((score) => _buildScoreCard(score)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // PERUBAHAN: Widget ini sekarang membangun kartu countdown
  Widget _buildCountdownCard() {
    final String title =
        _countdownData['title'] as String? ?? 'Pengumuman Hasil Seleksi';
    final int days = _countdownData['days'] as int? ?? 0;

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
                  days.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const Text(
                  'HARI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14, // Ukuran font disesuaikan agar pas
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Sisa widget helper seperti _buildDreamCampusSection, _buildSectionTitle, dll. tetap sama)
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

  Widget _buildScoreCard(TopTryoutScore score) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/siswa/tryout/hasil',
          arguments: score.id,
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
                color: Color(0xffe2d5cd),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xffe2d5cd),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
