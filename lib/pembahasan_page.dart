import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color primary = Color(0xFF1D3557); // Dark blue
  static const Color secondary = Color(0xFF457B9D); // Lighter blue
  static const Color accent = Color(0xFFA8DADC); // Light blue/cyan
  static const Color background =
      Color(0xFFF1FAEE); // Very light blue/off-white
  static const Color textDark = Color(0xFF1D3557); // Dark text
  static const Color textLight = Colors.white; // Light text
  static const Color success =
      Colors.green; // For correct answers/active elements
  static const Color correctGreen =
      Color(0xFF4CAF50); // A distinct green for correct answers
  static const Color wrongRed =
      Color(0xFFF44336); // A distinct red for wrong answers
}

// --- Model Data Tambahan (Opsional tapi direkomendasikan untuk struktur data yang jelas) ---

class SummaryData {
  final double averageScore;
  final int totalCorrect;
  final int totalWrong;
  final int totalEmpty;

  SummaryData({
    required this.averageScore,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalEmpty,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      totalCorrect: (json['total_correct'] as int?) ?? 0,
      totalWrong: (json['total_wrong'] as int?) ?? 0,
      totalEmpty: (json['total_empty'] as int?) ?? 0,
    );
  }
}

class SubjectResult {
  final String namaSubjek;
  final double nilaiRataRata;
  final int totalJawabanBenar;
  final int totalJawabanSalah;
  final int totalJawabanKosong;

  SubjectResult({
    required this.namaSubjek,
    required this.nilaiRataRata,
    required this.totalJawabanBenar,
    required this.totalJawabanSalah,
    required this.totalJawabanKosong,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      namaSubjek: json['nama_subjek'] as String? ?? 'Tidak Dikenal',
      nilaiRataRata: (json['nilai_rata_rata'] as num?)?.toDouble() ?? 0.0,
      totalJawabanBenar: (json['total_jawaban_benar'] as int?) ?? 0,
      totalJawabanSalah: (json['total_jawaban_salah'] as int?) ?? 0,
      totalJawabanKosong: (json['total_jawaban_kosong'] as int?) ?? 0,
    );
  }
}

class CategorySubjectResult {
  final List<SubjectResult> subjek;
  final String namaKategori;

  CategorySubjectResult({
    required this.subjek,
    required this.namaKategori,
  });

  factory CategorySubjectResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? subjekList = json['subjek'];
    List<SubjectResult> parsedSubjek = [];
    if (subjekList != null) {
      parsedSubjek = subjekList
          .map((s) => SubjectResult.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return CategorySubjectResult(
      subjek: parsedSubjek,
      namaKategori: json['nama_kategori'] as String? ?? 'Tidak Dikenal',
    );
  }
}

// --- Akhir Model Data Tambahan ---

class SoalPembahasanPage extends StatefulWidget {
  final String tryoutId;

  const SoalPembahasanPage({super.key, required this.tryoutId});

  @override
  _SoalPembahasanPageState createState() => _SoalPembahasanPageState();
}

class _SoalPembahasanPageState extends State<SoalPembahasanPage> {
  bool isExpanded = true;

  // Data yang akan diambil dari API, menggunakan model yang baru
  SummaryData? _summaryData; // Sekarang nullable karena mungkin belum terisi
  List<CategorySubjectResult> _perCategorySubjectData = [];

  bool _isLoading = true;
  String _errorMessage = '';

  final String _baseUrl = 'http://localhost:3000'; // Base URL backend Anda

  @override
  void initState() {
    super.initState();
    _fetchTryoutResultData(widget.tryoutId);
  }

  Future<void> _fetchTryoutResultData(String tryoutId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Autentikasi diperlukan. Silakan login kembali.';
          _isLoading = false;
        });
        // Future.microtask(() => Navigator.pushReplacementNamed(context, '/')); // uncomment if you want to redirect
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/tryout/$tryoutId/result'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          'DEBUG (PembahasanPage): API Response Status Code: ${response.statusCode}');
      print('DEBUG (PembahasanPage): API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);

        if (decodedBody is Map<String, dynamic>) {
          // Memastikan root adalah Map
          // Parsing summary (yang merupakan List berisi satu Map)
          final List<dynamic>? summaryList = decodedBody['summary'];
          if (summaryList != null && summaryList.isNotEmpty) {
            _summaryData =
                SummaryData.fromJson(summaryList[0] as Map<String, dynamic>);
          } else {
            _summaryData = null; // Atau inisialisasi dengan default kosong
          }

          // Parsing perCategorySubject (List of Maps)
          final List<dynamic>? perCategorySubjectRaw =
              decodedBody['perCategorySubject'];
          if (perCategorySubjectRaw != null) {
            _perCategorySubjectData = perCategorySubjectRaw.map((item) {
              // Periksa apakah item adalah Map dan memiliki kunci 'result'
              if (item is Map<String, dynamic> && item.containsKey('result')) {
                // Pastikan item['result'] juga Map
                if (item['result'] is Map<String, dynamic>) {
                  return CategorySubjectResult.fromJson(
                      item['result'] as Map<String, dynamic>);
                }
              }
              // Jika format tidak sesuai, berikan objek kosong atau tangani error
              return CategorySubjectResult(
                  subjek: [], namaKategori: 'Data Tidak Valid');
            }).toList();
          } else {
            _perCategorySubjectData = [];
          }

          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Format respons API tidak sesuai. Diharapkan objek JSON sebagai root, tetapi menerima tipe lain.';
            print(
                'DEBUG (PembahasanPage): Received unexpected root type: ${decodedBody.runtimeType}');
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat hasil tryout: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan jaringan: ${e.message}. Pastikan Anda terhubung ke internet dan server aktif.';
        _isLoading = false;
      });
      print('DEBUG (PembahasanPage): ClientException: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan tidak terduga saat parsing atau memproses data: $e';
        _isLoading = false;
      });
      print('DEBUG (PembahasanPage): General Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Hasil Tryout: ${widget.tryoutId}',
          style: const TextStyle(
              color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
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
                            style: const TextStyle(
                                color: AppColors.wrongRed, fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () =>
                                _fetchTryoutResultData(widget.tryoutId),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          // Section: User Information & Timer
                          _buildInfoSection(),
                          const SizedBox(height: 20),

                          // Section: Per Category Subject Results
                          _buildCategorySubjectSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoSection() {
    // Pastikan _summaryData tidak null sebelum mengakses propertinya
    final String averageScore =
        (_summaryData?.averageScore ?? 0.0).toStringAsFixed(2);
    final String totalCorrect = (_summaryData?.totalCorrect ?? 0).toString();
    final String totalWrong = (_summaryData?.totalWrong ?? 0).toString();
    final String totalEmpty = (_summaryData?.totalEmpty ?? 0).toString();

    // Data username, time_taken, major_prediction tidak ada di JSON summary yang diberikan.
    // Jika data ini ada di tempat lain di API Anda, Anda harus mengambilnya secara terpisah
    // atau meminta backend untuk menyertakannya di respons ini.
    final String userName = 'Nama Pengguna Tidak Tersedia'; // Placeholder
    final String timeTaken = 'Tidak Tersedia'; // Placeholder
    final String majorPrediction = 'Tidak Tersedia'; // Placeholder

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Ringkasan Hasil Tryout",
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _infoBox("Nama Pengguna: $userName"),
          _infoBox("ID Tryout: ${widget.tryoutId}"),
          _infoBox("Skor Rata-rata: $averageScore"),
          _infoBox("Total Benar: $totalCorrect"),
          _infoBox("Total Salah: $totalWrong"),
          _infoBox("Total Kosong: $totalEmpty"),
          const SizedBox(height: 16),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCategorySubjectSection() {
    if (_perCategorySubjectData.isEmpty) {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Skor per Kategori & Subjek", // Ubah judul
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ..._perCategorySubjectData.map((categoryResult) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    categoryResult.namaKategori,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...categoryResult.subjek.map((subject) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, top: 4.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subject.namaSubjek,
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 15),
                          ),
                        ),
                        Text(
                          subject.nilaiRataRata.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8), // Spasi kecil
                        Text(
                          'B: ${subject.totalJawabanBenar}',
                          style: const TextStyle(
                              color: AppColors.correctGreen, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'S: ${subject.totalJawabanSalah}',
                          style: const TextStyle(
                              color: AppColors.wrongRed, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'K: ${subject.totalJawabanKosong}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- Helper widgets (dihilangkan dari build utama, tapi tetap ada jika Anda ingin memanggilnya) ---
  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textLight, fontSize: 15),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _questionNumberBox(int number,
      {bool isActive = false, bool isCorrect = false, bool isWrong = false}) {
    Color bgColor = AppColors.textLight;
    Color textColor = AppColors.textDark;

    if (isActive) {
      bgColor = AppColors.success;
      textColor = AppColors.textLight;
    } else if (isCorrect) {
      bgColor = AppColors.correctGreen;
      textColor = AppColors.textLight;
    } else if (isWrong) {
      bgColor = AppColors.wrongRed;
      textColor = AppColors.textLight;
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Text(
        "$number",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Dummies, removed from main build method
  final List<String> answerOptions = []; // Dikosongkan karena dari API
  final String correctAnswer = ''; // Dikosongkan karena dari API
  String? selectedAnswer; // Dikosongkan karena dari API

  Widget _answerButton(String label,
      {bool isSelected = false,
      bool isCorrectAnswer = false,
      bool userAnswered = false}) {
    Color buttonColor = AppColors.background;
    Color textColor = AppColors.textDark;
    Color borderColor = AppColors.secondary;

    if (userAnswered) {
      if (isCorrectAnswer) {
        buttonColor = AppColors.correctGreen;
        textColor = AppColors.textLight;
        borderColor = AppColors.correctGreen;
      } else if (isSelected && !isCorrectAnswer) {
        buttonColor = AppColors.wrongRed;
        textColor = AppColors.textLight;
        borderColor = AppColors.wrongRed;
      } else if (isSelected && isCorrectAnswer) {
        buttonColor = AppColors.correctGreen;
        textColor = AppColors.textLight;
        borderColor = AppColors.correctGreen;
      }
    } else if (isSelected) {
      buttonColor = AppColors.accent;
      borderColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: null, // Disabled in this context
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
          elevation: 2,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 15, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _navigationButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: null, // Disabled in this context
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
