import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/explanation_detail.dart';
import 'package:flutter_lulusin/widget/dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class NilaiTryout extends StatefulWidget {
  final String? tryoutId;
  const NilaiTryout({super.key, this.tryoutId});

  @override
  State<NilaiTryout> createState() => _NilaiTryoutState();
}

class _NilaiTryoutState extends State<NilaiTryout> {
  bool _isDropdownMenuOpen = false;
  final GlobalKey _menuKey = GlobalKey();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _error = '';
  Map<String, String> _subjectNameToId = {}; // mapping nama_subjek -> id_subjek

  @override
  void initState() {
    super.initState();
    _fetchNilaiTryout();
    _fetchSubjectMapping();
  }

  Future<void> _fetchNilaiTryout() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) {
        setState(() {
          _error = 'Tidak ada token. Silakan login ulang.';
          _isLoading = false;
        });
        return;
      }
      final tryoutId = widget.tryoutId ?? '1';
      final url =
          'https://cardinal-helpful-simply.ngrok-free.app/API/student/tryout/$tryoutId/result';
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSubjectMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) return;
      final tryoutId = widget.tryoutId ?? '1';
      final url =
          'https://cardinal-helpful-simply.ngrok-free.app/api/student/tryout/$tryoutId';
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final subjects = data['getTryout']?['subjects'] ?? [];
        final Map<String, String> mapping = {};
        for (final s in subjects) {
          if (s['subject_name'] != null && s['subject_id'] != null) {
            mapping[s['subject_name']] = s['subject_id'].toString();
          }
        }
        setState(() {
          _subjectNameToId = mapping;
        });
      }
    } catch (_) {}
  }

  void _toggleDropdownMenu() {
    setState(() {
      _isDropdownMenuOpen = !_isDropdownMenuOpen;
    });
  }

  void _handleDropdownItemSelected(String item) {
    // Tutup dropdown setelah item dipilih
    _toggleDropdownMenu();

    // Tambahkan logika navigasi atau aksi lain di sini
    if (item == 'Dashboard') {
      // Contoh navigasi ke halaman Dashboard
      // Navigator.pushReplacementNamed(context, '/dashboard');
      print('Navigating to Dashboard');
    } else if (item == 'Tryout') {
      // Contoh navigasi ke halaman Tryout
      // Navigator.pushReplacementNamed(context, '/tryout');
      print('Navigating to Tryout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: const Color(0xFF22395A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        key: _menuKey,
                        onTap: () {
                          setState(() {
                            _isDropdownMenuOpen = !_isDropdownMenuOpen;
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  width: 22,
                                  height: 3,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 4)),
                              Container(
                                  width: 22,
                                  height: 3,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 4)),
                              Container(
                                  width: 22, height: 3, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('LuLuSin',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  fontSize: 16)),
                          Text('Education Academi',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Poppins')),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => Dashboard()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A5C8D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
                if (_isDropdownMenuOpen)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF22395A),
                    child: Column(
                      children: [
                        _buildFullMenuItem('Dashboard', onTap: () {
                          setState(() => _isDropdownMenuOpen = false);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => Dashboard()),
                            (route) => false,
                          );
                        }),
                        Container(height: 1, color: Colors.white),
                        _buildFullMenuItem('Tryout', onTap: () {
                          setState(() => _isDropdownMenuOpen = false);
                        }),
                      ],
                    ),
                  ),
                // Judul

                // Garis
                Container(
                  width: double.infinity,
                  height: 2,
                  color: const Color(0xFF3A5C8D),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error.isNotEmpty
                          ? Center(
                              child: Text(_error,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontFamily: 'Poppins')))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 0),
                              child: Column(
                                children: [
                                  // Summary box
                                  if (_data != null &&
                                      _data!['summary'] != null &&
                                      (_data!['summary'] as List).isNotEmpty)
                                    _buildSummaryBox(_data!['summary'][0]),
                                  const SizedBox(height: 18),
                                  // Per kategori
                                  if (_data != null &&
                                      _data!['perCategorySubject'] != null)
                                    ...(_data!['perCategorySubject'] as List)
                                        .map((cat) => _buildCategorySection(
                                            cat['result']))
                                        .toList(),
                                  const SizedBox(height: 18),
                                  // Tombol https://cardinal-helpful-simply.ngrok-free.app
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF22395A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Keluar',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullMenuItem(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF22395A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatBox(
                label: 'Nilai Rata Rata',
                value: summary['average_score'].toString()),
            const SizedBox(width: 12),
            _StatBox(
                label: 'Total Jawaban Benar',
                value: summary['total_correct'].toString()),
            const SizedBox(width: 12),
            _StatBox(
                label: 'Total Jawaban Salah',
                value: summary['total_wrong'].toString()),
            const SizedBox(width: 12),
            _StatBox(
                label: 'Total Jawaban Kosong',
                value: summary['total_empty'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> cat) {
    final String namaKategori = cat['nama_kategori'] ?? '-';
    final List subjek = cat['subjek'] ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF22395A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF3A5C8D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Center(
              child: Text(
                namaKategori,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          ...subjek.map((sj) => _buildSubjectCard(sj)).toList(),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> sj) {
    return GestureDetector(
      onTap: () {
        // Mapping nama_subjek ke id_subjek
        final String? namaSubjek = sj['nama_subjek'];
        final String? subjectId = _subjectNameToId[namaSubjek];
        if (subjectId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'ID subjek tidak ditemukan! Nama subjek: $namaSubjek')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExplanationDetailPage(
              tryoutId: widget.tryoutId ?? '1',
              subjectId: subjectId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                sj['nama_subjek'] ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatBox(
                        label: 'Nilai',
                        value: sj['nilai_rata_rata'].toString(),
                        small: isMobile),
                    _StatBox(
                        label: 'Total Jawaban Benar',
                        value: sj['total_jawaban_benar'].toString(),
                        small: isMobile),
                    _StatBox(
                        label: 'Total Jawaban Salah',
                        value: sj['total_jawaban_salah'].toString(),
                        small: isMobile),
                    _StatBox(
                        label: 'Total Jawaban Kosong',
                        value: sj['total_jawaban_kosong'].toString(),
                        small: isMobile),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _StatBox(
      {required String label, required String value, bool small = false}) {
    return Container(
      constraints: BoxConstraints(
          minWidth: small ? 90 : 120, maxWidth: small ? 110 : 160),
      padding: EdgeInsets.symmetric(
          vertical: small ? 8 : 12, horizontal: small ? 6 : 10),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6583),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 4),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: small ? 11 : 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 15 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          )
        ],
      ),
    );
  }
}

// Navbar Widget digabungkan di bawah ini
class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;

  const Navbar({
    super.key,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1C3554),
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: onMenuPressed,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'LuLuSin',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Education Academi',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
