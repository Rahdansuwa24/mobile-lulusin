import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppColorsExplanation {
  static const Color primary = Color(0xFF22395A);
  static const Color background = Color(0xFFF5EFE7);
  static const Color accent = Color(0xFFA8DADC);
  static const Color textDark = Color(0xFF1D3557);
  static const Color textLight = Colors.white;
  static const Color correctGreen =
      Color(0xFFD4F5DD); // Warna untuk jawaban benar
  static const Color studentChoiceBlue =
      Color(0xFFD6E6F2); // Warna untuk pilihan siswa
  static const Color correctTextGreen = Color(0xFF006400); // Dark Green
  static const Color explanationBackground = Color(0xFFF9F9F9);
  static const Color explanationBorder = Color(0xFFBFD7ED);
}

class ExplanationDetailPage extends StatefulWidget {
  final String tryoutId;
  final String subjectId; // Ini adalah ID subjek, bukan nama subjek
  const ExplanationDetailPage(
      {super.key, required this.tryoutId, required this.subjectId});

  @override
  State<ExplanationDetailPage> createState() => _ExplanationDetailPageState();
}

class _ExplanationDetailPageState extends State<ExplanationDetailPage> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _data;
  int _currentQuestionIndex = 0;
  final String _baseUrl =
      'https://cardinal-helpful-simply.ngrok-free.app'; // Definisikan baseUrl

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    print(
        "Fetching explanation for Tryout ID: ${widget.tryoutId}, Subject ID: ${widget.subjectId}");
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
      // PERBAIKAN URL: Hapus '/API/'
      final url =
          '$_baseUrl/api/student/tryout/${widget.tryoutId}/${widget.subjectId}/explanation';
      print("Calling URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      print("Response status: ${response.statusCode}");
      // print("Response body: ${response.body}"); // Hati-hati jika body besar

      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              'Gagal memuat data pembahasan. Status: ${response.statusCode}. Pesan: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching explanation: $e");
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsExplanation.background,
      appBar: AppBar(
        backgroundColor: AppColorsExplanation.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pembahasan',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColorsExplanation.primary))
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.red,
                              fontFamily: 'Poppins',
                              fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchExplanation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsExplanation.primary,
                          foregroundColor: AppColorsExplanation.textLight,
                        ),
                        child: const Text('Coba Lagi'),
                      )
                    ],
                  ),
                ))
              : _data == null ||
                      (_data!['detail'] as List?) == null ||
                      (_data!['detail'] as List).isEmpty
                  ? const Center(
                      child: Text('Tidak ada data pembahasan.',
                          style:
                              TextStyle(fontFamily: 'Poppins', fontSize: 16)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoBox(_data!),
                          const SizedBox(height: 18),
                          _buildQuestionGrid(_data!),
                          const SizedBox(height: 18),
                          _buildSoalCard(_data!, _currentQuestionIndex),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: _currentQuestionIndex > 0
                                    ? () =>
                                        setState(() => _currentQuestionIndex--)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColorsExplanation.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                    'Sebelumnya', // Diubah dari 'previous'
                                    style: TextStyle(fontFamily: 'Poppins')),
                              ),
                              ElevatedButton(
                                onPressed: _currentQuestionIndex <
                                        (_data!['detail'] as List).length - 1
                                    ? () =>
                                        setState(() => _currentQuestionIndex++)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColorsExplanation.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                    'Berikutnya', // Diubah dari 'next'
                                    style: TextStyle(fontFamily: 'Poppins')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoBox(Map<String, dynamic> data) {
    // Pastikan key 'studentData' dan 'subjectExpData' ada di respons API Anda
    final student = data['studentData'] as Map<String, dynamic>? ?? {};
    final subject = data['subjectExpData'] as Map<String, dynamic>? ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColorsExplanation.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 350;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child:
                          _infoRow('Nama', student['nama']?.toString() ?? '-')),
                  const SizedBox(width: 10),
                  Flexible(
                      child:
                          _infoRow('NISN', student['nisn']?.toString() ?? '-')),
                ],
              ),
              const SizedBox(height: 8),
              isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Kategori',
                            subject['kategori_subjek']?.toString() ?? '-'),
                        const SizedBox(height: 4),
                        _infoRow(
                            'Subjek', subject['subjek']?.toString() ?? '-'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            child: _infoRow('Kategori',
                                subject['kategori_subjek']?.toString() ?? '-')),
                        const SizedBox(width: 10),
                        Flexible(
                            child: _infoRow('Subjek',
                                subject['subjek']?.toString() ?? '-')),
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String left, String right) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(left,
            style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          right,
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildQuestionGrid(Map<String, dynamic> data) {
    final List detail = (data['detail'] as List?) ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColorsExplanation.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(detail.length, (i) {
          final isActive = i == _currentQuestionIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentQuestionIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColorsExplanation.accent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isActive
                        ? AppColorsExplanation.accent.withOpacity(0.7)
                        : AppColorsExplanation.primary.withOpacity(0.5),
                    width: 2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: isActive
                      ? AppColorsExplanation.textDark
                      : AppColorsExplanation.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSoalCard(Map<String, dynamic> data, int idx) {
    final List detail = (data['detail'] as List?) ?? [];
    if (detail.isEmpty || idx >= detail.length)
      return const SizedBox(child: Text("Soal tidak ditemukan"));

    final soal = detail[idx] as Map<String, dynamic>? ?? {};
    final String questionText =
        soal['question']?.toString() ?? 'Pertanyaan tidak tersedia.';
    final List<dynamic> answerOptions =
        (soal['answer_options'] as List<dynamic>?) ?? [];
    final String correctAnswer = soal['correct_answer']?.toString() ?? '';
    final String studentAnswer = soal['jawaban_siswa']?.toString() ??
        ''; // Pastikan backend mengirim 'jawaban_siswa'
    final String explanationText =
        soal['explanation']?.toString() ?? 'Penjelasan tidak tersedia.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsExplanation.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Soal Nomor ${idx + 1}:",
              style: const TextStyle(
                  color: AppColorsExplanation.accent,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(questionText,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          if (answerOptions.isNotEmpty)
            Text("Pilihan Jawaban:",
                style: const TextStyle(
                    color: AppColorsExplanation.accent,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Column(
            // Menggunakan Column agar setiap pilihan mengambil lebar penuh
            children: List<Widget>.from(
              answerOptions.map((optDynamic) {
                final opt = optDynamic.toString();
                final bool isThisCorrectAnswer = opt == correctAnswer;
                final bool isThisStudentChoice = opt == studentAnswer;

                Color tileColor;
                Color textColor;
                FontWeight fontWeight = FontWeight.normal;
                IconData? leadingIcon;
                Color iconColor = AppColorsExplanation.textDark;

                if (isThisCorrectAnswer) {
                  tileColor = AppColorsExplanation.correctGreen;
                  textColor = AppColorsExplanation
                      .correctTextGreen; // Warna teks lebih gelap untuk kontras
                  fontWeight = FontWeight.bold;
                  if (isThisStudentChoice) {
                    // Siswa menjawab benar
                    leadingIcon = Icons.check_circle;
                    iconColor = AppColorsExplanation.correctTextGreen;
                  } else {
                    // Ini jawaban benar, tapi bukan pilihan siswa
                    leadingIcon = Icons
                        .check_box_outlined; // Menandakan ini kunci jawaban
                    iconColor = AppColorsExplanation.correctTextGreen;
                  }
                } else if (isThisStudentChoice && !isThisCorrectAnswer) {
                  // Siswa menjawab salah
                  tileColor = AppColorsExplanation.studentChoiceBlue
                      .withOpacity(
                          0.7); // Warna berbeda untuk jawaban salah siswa
                  textColor = AppColorsExplanation.textDark;
                  fontWeight = FontWeight.bold;
                  leadingIcon = Icons.cancel;
                  iconColor = Colors.red.shade700;
                } else {
                  // Pilihan biasa, bukan jawaban benar, bukan pilihan siswa
                  tileColor = Colors.white;
                  textColor = AppColorsExplanation.textDark;
                }

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: tileColor.withOpacity(0.5), // Border lebih subtle
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (leadingIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(leadingIcon, color: iconColor, size: 20),
                        ),
                      Expanded(
                        child: Text(opt,
                            style: TextStyle(
                                color: textColor,
                                fontFamily: 'Poppins',
                                fontWeight: fontWeight,
                                fontSize: 15)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text("Pembahasan:",
              style: const TextStyle(
                  color: AppColorsExplanation.accent,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColorsExplanation.explanationBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColorsExplanation.explanationBorder, width: 1),
            ),
            child: Text(
              explanationText,
              style: const TextStyle(
                  color: AppColorsExplanation.textDark,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  height: 1.5, // Line height
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
