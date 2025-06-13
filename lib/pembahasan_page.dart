import 'package:flutter/material.dart';
import 'package:flutter_lulusin/explanation_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Impor halaman detail pembahasan yang baru/ Pastikan nama file ini benar

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
  final String idSubjek; // ID untuk subjek, diharapkan dari API
  final String namaSubjek;
  final double nilaiRataRata;
  final int totalJawabanBenar;
  final int totalJawabanSalah;
  final int totalJawabanKosong;

  SubjectResult({
    required this.idSubjek,
    required this.namaSubjek,
    required this.nilaiRataRata,
    required this.totalJawabanBenar,
    required this.totalJawabanSalah,
    required this.totalJawabanKosong,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      // PENTING: Backend harus mengirimkan field 'id_subjek' dengan nilai yang valid.
      // Jika tidak ada atau null, idSubjek akan menjadi string kosong.
      idSubjek: json['id_subjek'] as String? ?? '',
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

class TryoutResultPage extends StatefulWidget {
  final String tryoutId;

  const TryoutResultPage({super.key, required this.tryoutId});

  @override
  // ignore: library_private_types_in_public_api
  _TryoutResultPageState createState() => _TryoutResultPageState();
}

class _TryoutResultPageState extends State<TryoutResultPage> {
  SummaryData? _summaryData;
  List<CategorySubjectResult> _perCategorySubjectData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final String _baseUrl =
      'https://cardinal-helpful-simply.ngrok-free.app'; // URL dasar backend Anda

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
        return;
      }

      final url = '$_baseUrl/API/student/tryout/$tryoutId/result';
      print('DEBUG (TryoutResultPage): Calling URL for result: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print(
          'DEBUG (TryoutResultPage): API Response Status Code: ${response.statusCode}');
      // print('DEBUG (TryoutResultPage): API Response Body: ${response.body}'); // Hati-hati jika body besar

      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);

        if (decodedBody is Map<String, dynamic>) {
          final List<dynamic>? summaryList = decodedBody['summary'];
          if (summaryList != null && summaryList.isNotEmpty) {
            _summaryData =
                SummaryData.fromJson(summaryList[0] as Map<String, dynamic>);
          } else {
            _summaryData = null;
          }

          final List<dynamic>? perCategorySubjectRaw =
              decodedBody['perCategorySubject'];
          if (perCategorySubjectRaw != null) {
            _perCategorySubjectData = perCategorySubjectRaw.map((item) {
              if (item is Map<String, dynamic> &&
                  item.containsKey('result') &&
                  item['result'] is Map<String, dynamic>) {
                return CategorySubjectResult.fromJson(
                    item['result'] as Map<String, dynamic>);
              }
              print(
                  'DEBUG (TryoutResultPage): Invalid item format in perCategorySubjectRaw: $item');
              return CategorySubjectResult(
                  subjek: [], namaKategori: 'Data Kategori Tidak Valid');
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
                'Format respons API tidak sesuai: Diharapkan objek JSON sebagai root.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat hasil tryout: ${response.statusCode} - ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
          _isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan: ${e.message}.';
        _isLoading = false;
      });
      print('DEBUG (TryoutResultPage): ClientException: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
        _isLoading = false;
      });
      print('DEBUG (TryoutResultPage): General Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Hasil Tryout',
          style: TextStyle(
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
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textLight),
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
                          _buildInfoSection(),
                          const SizedBox(height: 20),
                          _buildCategorySubjectSection(),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Kembali ke Daftar Tryout'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.textLight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                textStyle: const TextStyle(fontSize: 16)),
                          )
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final String averageScore =
        (_summaryData?.averageScore ?? 0.0).toStringAsFixed(2);
    final String totalCorrect = (_summaryData?.totalCorrect ?? 0).toString();
    final String totalWrong = (_summaryData?.totalWrong ?? 0).toString();
    final String totalEmpty = (_summaryData?.totalEmpty ?? 0).toString();

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
          _infoRow("ID Tryout:", widget.tryoutId),
          _infoRow("Skor Rata-rata:", averageScore,
              valueColor: AppColors.accent),
          _infoRow("Total Benar:", totalCorrect,
              valueColor: AppColors.correctGreen),
          _infoRow("Total Salah:", totalWrong, valueColor: AppColors.wrongRed),
          _infoRow("Total Kosong:", totalEmpty,
              valueColor: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 15)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? AppColors.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategorySubjectSection() {
    if (_perCategorySubjectData.isEmpty) {
      return const Center(child: Text("Data skor per subjek tidak tersedia."));
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
            "Skor per Subjek",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          ..._perCategorySubjectData.expand((categoryResult) {
            return [
              if (_perCategorySubjectData.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    categoryResult.namaKategori,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ...categoryResult.subjek.map((subject) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () {
                      // PENTING: Logika ini akan menampilkan error jika subject.idSubjek kosong.
                      // Pastikan backend mengirimkan 'id_subjek' yang valid untuk setiap subjek.
                      if (subject.idSubjek.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'ID Subjek tidak valid untuk melihat pembahasan.')),
                        );
                        print(
                            "ID Subjek kosong untuk ${subject.namaSubjek}. Backend perlu mengirim 'id_subjek'.");
                        return;
                      }
                      print(
                          "Navigasi ke pembahasan: Tryout ID: ${widget.tryoutId}, Subject ID: ${subject.idSubjek}, Nama Subjek: ${subject.namaSubjek}");

                      Navigator.pushNamed(
                        context,
                        '/siswa/explanation',
                        arguments: {
                          'tryoutId': widget.tryoutId,
                          'subjectId': subject.idSubjek,
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              subject.namaSubjek,
                              style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  subject.nilaiRataRata.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Tooltip(
                                  message:
                                      "Benar: ${subject.totalJawabanBenar}\nSalah: ${subject.totalJawabanSalah}\nKosong: ${subject.totalJawabanKosong}",
                                  child: const Icon(Icons.info_outline,
                                      color: AppColors.secondary, size: 18),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.secondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_perCategorySubjectData.length > 1 &&
                  categoryResult != _perCategorySubjectData.last)
                const SizedBox(height: 10),
            ];
          }),
        ],
      ),
    );
  }
}
