import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import package http
import 'dart:convert'; // Untuk mengonversi JSON

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Base URL untuk backend Anda
  // Sesuaikan dengan IP lokal Anda atau alamat server jika di-deploy
  // Untuk Android Emulator: gunakan http://10.0.2.2:3000
  // Untuk iOS Simulator/Web/Perangkat Fisik: gunakan https://cardinal-helpful-simply.ngrok-free.app atau IP lokal Anda
  final String _baseUrl =
      'https://cardinal-helpful-simply.ngrok-free.app/API'; // Ganti dengan URL backend Anda

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    nisnController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final String nisn = nisnController.text;
    final String studentName = nameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;
    final String confirmationPassword = confirmPasswordController.text;

    // Validasi sisi klien (opsional, tapi disarankan)
    if (nisn.isEmpty ||
        studentName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmationPassword.isEmpty) {
      _showSnackBar('Semua field harus diisi.');
      return;
    }
    if (password != confirmationPassword) {
      _showSnackBar('Password dan konfirmasi password tidak cocok.');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password minimal 6 karakter.');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _showSnackBar('Password harus mengandung setidaknya satu huruf kapital.');
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      _showSnackBar('Password harus mengandung setidaknya satu huruf kecil.');
      return;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      _showSnackBar('Password harus mengandung setidaknya satu angka.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'), // Endpoint register Anda
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'ngrok-skip-browser-warning': 'true'
        },
        body: jsonEncode(<String, String>{
          'NISN': nisn,
          'student_name': studentName,
          'email': email,
          'password': password,
          'confirmation_password': confirmationPassword,
        }),
      );

      if (response.statusCode == 201) {
        // Berhasil mendaftar
        _showSnackBar('Registrasi berhasil!');
        // Navigasi ke halaman login atau dashboard setelah berhasil
        Navigator.pop(context); // Kembali ke halaman sebelumnya (misal: login)
      } else {
        // Gagal mendaftar, tampilkan pesan error dari backend
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _showSnackBar(
            'Registrasi gagal: ${responseData['message'] ?? 'Terjadi kesalahan.'}');
      }
    } catch (e) {
      // Tangani error jaringan atau lainnya
      _showSnackBar('Terjadi kesalahan jaringan: $e');
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
      backgroundColor: const Color(0xFF1C3554),
      body: Center(
        child: SingleChildScrollView(
          // Tambahkan SingleChildScrollView agar keyboard tidak menutupi input
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Register',
                  style: TextStyle(
                    color: Color(0xFF1C3554),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress, // Tipe keyboard email
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nama',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nisnController,
                  keyboardType: TextInputType.number, // Tipe keyboard angka
                  decoration: InputDecoration(
                    hintText: 'NISN',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Konfirmasi Password',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1C3554)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _registerUser,
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color(0xFF1C3554),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ), // Panggil fungsi registrasi
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Kembali ke Login
                  },
                  child: const Text(
                    'Sudah punya akun? Login',
                    style: TextStyle(
                      color: Color(0xFF1C3554),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
