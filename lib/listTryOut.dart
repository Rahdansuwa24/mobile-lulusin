import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/nilai_tryout.dart' hide Navbar;
import 'package:flutter_lulusin/pembahasan_page.dart';
import 'package:flutter_lulusin/widget/navbar.dart';
import 'package:flutter_lulusin/widget/dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lulusin/tryout_detail.dart';
import 'dashboard.dart';

class TryoutItem {
  final int id;
  final String name;
  TryoutItem({required this.id, required this.name});
  factory TryoutItem.fromJson(Map<String, dynamic> json) {
    return TryoutItem(
      id: json['tryout_id'] as int,
      name: json['tryout_name'] as String,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isDropdownMenuOpen = false;
  final String _baseUrl = 'https://cardinal-helpful-simply.ngrok-free.app';

  List<TryoutItem> _doneTryouts = [];
  List<TryoutItem> _notDoneTryouts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    _fetchTryoutList();
  }

  Future<void> _fetchTryoutList() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) _navigateToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/tryout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _doneTryouts = (data['done'] as List? ?? [])
              .map((e) => TryoutItem.fromJson(e))
              .toList();
          _notDoneTryouts = (data['not_done'] as List? ?? [])
              .map((e) => TryoutItem.fromJson(e))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
          _isLoading = false;
        });
      }
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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Dashboard()));
    } else if (item == 'Tryout') {
      // Tetap di halaman ini
    }
  }

  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token == null) {
        _showSnackBar('Anda sudah logout.');
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final response =
          await http.post(Uri.parse('$_baseUrl/api/logout'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      });

      await prefs.remove('auth_token');
      if (mounted) {
        if (response.statusCode == 200) {
          _showSnackBar('Logout berhasil!');
        } else {
          _showSnackBar('Sesi Anda telah berakhir.');
        }
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Terjadi kesalahan jaringan saat logout: $e');
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
      backgroundColor: const Color(0xFFF5EFE7),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: const Color(0xFFF5EFE7),
            child: const Text(
              'Daftar Tryout',
              style: TextStyle(
                color: Color(0xFF1C3554),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
          Container(
            color: const Color(0xFFF5EFE7),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTabItem(title: 'Sudah Dikerjakan', index: 0),
                  const SizedBox(width: 8),
                  _buildTabItem(title: 'Belum Dikerjakan', index: 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(_errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF22395A),
                                fontFamily: 'Poppins',
                                fontSize: 16)),
                      ))
                    : (_selectedTab == 1 ? _notDoneTryouts : _doneTryouts)
                            .isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.only(top: 8),
                            children: [
                              ...(_selectedTab == 1
                                      ? _notDoneTryouts
                                      : _doneTryouts)
                                  .asMap()
                                  .entries
                                  .map((entry) => _buildTryoutCard(
                                        entry.value,
                                        isDone: _selectedTab == 0,
                                        index: entry.key,
                                      ))
                                  .toList(),
                              const SizedBox(height: 18),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22395A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF22395A),
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                color: const Color(0xFF22395A).withOpacity(0.3), size: 54),
            const SizedBox(height: 10),
            Text(
              _selectedTab == 1
                  ? 'Tidak ada tryout yang harus dikerjakan. Hebat!'
                  : 'Belum ada riwayat tryout yang selesai.',
              style: const TextStyle(
                color: Color(0xFF22395A),
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryoutCard(TryoutItem tryout,
      {required bool isDone, int index = 0}) {
    String? badge = RegExp(r'(\d+)').firstMatch(tryout.name)?.group(1);
    badge = badge != null ? 'ep.$badge' : 'ep.${index + 1}';
    String buttonText = isDone ? 'Lihat Hasil' : 'Kerjakan';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tryout.name,
                      style: const TextStyle(
                        color: Color(0xFF22395A),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22395A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () {
                      if (isDone) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TryoutResultPage(
                                tryoutId: tryout.id.toString()),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TryoutPage(tryoutId: tryout.id.toString()),
                          ),
                        );
                      }
                    },
                    child: Text(buttonText),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3A5C8D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
