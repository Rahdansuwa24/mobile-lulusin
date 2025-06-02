// lib/dashboard.dart
import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/widget/navbar.dart';
import 'package:flutter_lulusin/widget/dropdown.dart';
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // Import convert
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class DashboardPage extends StatefulWidget {
  // Menggunakan DashboardPage
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState(); // Menggunakan _DashboardPageState
}

class _DashboardPageState extends State<DashboardPage> {
  // Menggunakan _DashboardPageState
  bool _isDropdownMenuOpen = false;
  final String _baseUrl = 'http://localhost:3000'; // Base URL backend Anda

  void _toggleDropdownMenu() {
    setState(() {
      _isDropdownMenuOpen = !_isDropdownMenuOpen;
    });
  }

  void _handleDropdownItemSelected(String item) {
    _toggleDropdownMenu(); // Tutup dropdown setelah item dipilih

    if (item == 'Dashboard') {
      print('Navigating to Dashboard');
      // Anda bisa menambahkan Navigator.pushReplacementNamed(context, '/siswa/dashboard');
    } else if (item == 'Tryout') {
      print('Navigating to Tryout');
      // Anda bisa menambahkan Navigator.pushReplacementNamed(context, '/siswa/tryout');
    }
  }

  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token =
          prefs.getString('auth_token'); // Ambil token dari penyimpanan

      if (token == null) {
        _showSnackBar('Tidak ada token ditemukan. Anda sudah logout.');
        Navigator.pushReplacementNamed(context, '/'); // Kembali ke login
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/logout'), // Endpoint logout Anda
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'Bearer $token', // Kirim token di header Authorization
        },
      );

      if (response.statusCode == 200) {
        // Logout berhasil di backend
        await prefs.remove('auth_token'); // Hapus token dari penyimpanan lokal
        _showSnackBar('Logout berhasil!');
        Navigator.pushReplacementNamed(
            context, '/'); // Redirect ke halaman login
      } else {
        // Gagal logout di backend, mungkin token tidak valid atau kadaluarsa
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _showSnackBar(
            'Logout gagal: ${responseData['message'] ?? 'Terjadi kesalahan.'}');
        // Jika token tidak valid, mungkin lebih baik tetap hapus dari sisi klien
        await prefs.remove('auth_token');
        Navigator.pushReplacementNamed(context, '/'); // Tetap redirect ke login
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan jaringan saat logout: $e');
      print('Logout Error: $e');
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
      backgroundColor: const Color(0xff22395a),
      appBar: Navbar(
        onMenuPressed: _toggleDropdownMenu,
        onLogoutPressed: _logoutUser, // Teruskan fungsi logout ke Navbar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isDropdownMenuOpen)
              DropdownMenu(
                onItemSelected: _handleDropdownItemSelected,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSectionTitle('Belum Dikerjakan'),
                  _buildTryoutCard('tryout utbk snbt 2025 ep.6'),
                  _buildTryoutCard('tryout utbk snbt 2025 ep.7'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Telah Dikerjakan'),
                  _buildTryoutCard('tryout utbk snbt 2025 ep.5'),
                  _buildTryoutCard('tryout utbk snbt 2025 ep.4'),
                  const SizedBox(height: 30),
                  // _buildFooter(), // Baris ini telah dihapus
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isSelected
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 1.5),
              ),
            )
          : null,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
            color: Color(0xff1e2e47), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTryoutCard(String title) {
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
              style: const TextStyle(color: Colors.white),
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
              // TODO: Aksi ketika tombol "Lihat" ditekan
            },
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }
}
