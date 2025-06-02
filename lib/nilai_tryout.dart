import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_lulusin/widget/dropdown.dart';

class NilaiTryout extends StatefulWidget {
  const NilaiTryout({super.key});

  @override
  State<NilaiTryout> createState() => _NilaiTryoutState();
}

class _NilaiTryoutState extends State<NilaiTryout> {
  bool _isDropdownMenuOpen = false;

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
      backgroundColor: Colors.grey[200],
      appBar: Navbar(
        onMenuPressed: _toggleDropdownMenu, // Kirim callback ke Navbar
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isDropdownMenuOpen)
                DropdownMenu(
                  onItemSelected: _handleDropdownItemSelected,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTestSection(
                        title: 'Tes Potensi Skolastik',
                        tests: [
                          'Penalaran Umum',
                          'Pengetahuan dan Pemahaman Umum',
                          'Pemahaman Bacaan dan Menulis',
                          'Pengetahuan Kuantitatif',
                        ],
                      ),
                      _buildTestSection(
                        title: 'Tes Literasi',
                        tests: [
                          'Literasi Bahasa Indonesia',
                          'Literasi Bahasa Inggris',
                        ],
                      ),
                      _buildTestSection(
                        title: 'Tes Penalaran Matematika',
                        tests: ['Penalaran Matematika'],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A3B5F),
                elevation: 6,
                shadowColor: Colors.black45,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                // TODO: Tambahkan logika logout
              },
              child: const Text(
                "Keluar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildTestSection({
    required String title,
    required List<String> tests,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF4A6583),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Column(
            children: tests.map((test) => _buildTestCard(test)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(String cardTitle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatBox(label: "Nilai"),
              _StatBox(label: "Total Jawaban Benar"),
              _StatBox(label: "Total Jawaban Salah"),
              _StatBox(label: "Total Jawaban Kosong"),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _StatBox({required String label}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "768", // Ubah menjadi dinamis sesuai kebutuhan
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
