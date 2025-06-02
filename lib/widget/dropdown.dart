// lib/widget/dropdown.dart
import 'package:flutter/material.dart';

class DropdownMenu extends StatelessWidget {
  final Function(String) onItemSelected;

  const DropdownMenu({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C3554),
      child: Column(
        children: [
          const Divider(color: Colors.white),
          _buildItem(context, 'Dashboard'),
          const Divider(color: Colors.white),
          _buildItem(context, 'Tryout'),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        // Panggil callback untuk menutup dropdown (jika diimplementasikan di parent)
        onItemSelected(title);

        // Lakukan navigasi berdasarkan item yang dipilih
        if (title == 'Dashboard') {
          Navigator.pushReplacementNamed(context, '/siswa/dashboard');
        } else if (title == 'Tryout') {
          Navigator.pushReplacementNamed(context, '/siswa/tryout');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
