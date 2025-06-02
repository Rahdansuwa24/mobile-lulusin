// lib/soal_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For Timer
import 'package:shared_preferences/shared_preferences.dart';
// Ganti dengan path model Subject Anda yang sebenarnya
import 'package:flutter_lulusin/model/subject.dart';

// Definisikan kelas AppColors Anda di sini atau impor dari file lain
class AppColors {
  static const Color primary = Color(0xFF1D3557); // Biru Tua
  static const Color secondary = Color(0xFF457B9D); // Biru Lebih Muda
  static const Color accent = Color(0xFFA8DADC); // Biru Muda/Sian
  static const Color background =
      Color(0xFFF1FAEE); // Putih Kebiruan/Putih Pucat
  static const Color textDark = Color(0xFF1D3557); // Teks Gelap
  static const Color textLight = Colors.white; // Teks Terang
  static const Color success = Colors.green; // Untuk jawaban benar/elemen aktif
  static const Color danger = Colors.red; // Untuk error/peringatan
  static const Color answeredQuestion =
      Colors.lightBlue; // Warna untuk soal terjawab di grid
}

class SoalPage extends StatefulWidget {
  final String tryoutId;
  final String subjectId; // ID mata pelajaran yang sedang dikerjakan
  final List<Subject>
      allSubjects; // Daftar semua mata pelajaran, WAJIB diisi oleh pemanggil

  const SoalPage({
    super.key,
    required this.tryoutId,
    required this.subjectId,
    required this.allSubjects,
  });

  @override
  _SoalPageState createState() => _SoalPageState();
}

class _SoalPageState extends State<SoalPage> {
  // Variabel State
  bool _isLoading = true;
  String _errorMessage = '';
  final String _baseUrl = 'http://localhost:3000'; // Sesuaikan jika perlu

  late List<Subject>
      _allSubjectsState; // Akan diinisialisasi dari widget.allSubjects

  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _subjectData; // Data untuk mata pelajaran saat ini
  List<dynamic> _questions = []; // Soal-soal untuk mata pelajaran saat ini
  int _currentQuestionIndex = 0;
  Map<String, String?> _selectedAnswers =
      {}; // Maps questionId to answerOptionId (bisa null)

  Timer? _timer;
  int _timeRemainingInSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Inisialisasi _allSubjectsState dari parameter widget
    _allSubjectsState = List<Subject>.from(widget.allSubjects);
    _initializeTryout();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTryout() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Pastikan _allSubjectsState (dari widget.allSubjects) tidak kosong.
      if (_allSubjectsState.isEmpty) {
        throw Exception(
            'Daftar mata pelajaran (allSubjects) tidak boleh kosong saat memanggil SoalPage. Pastikan widget pemanggil menyediakan daftar ini.');
      }

      // Validasi apakah subjectId saat ini ada di _allSubjectsState
      if (!_allSubjectsState.any((subject) => subject.id == widget.subjectId)) {
        _showSnackBar(
            "Mata pelajaran dengan ID ${widget.subjectId} tidak ditemukan dalam daftar. Mengarahkan ke mata pelajaran pertama.");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SoalPage(
                tryoutId: widget.tryoutId,
                subjectId: _allSubjectsState.first.id,
                allSubjects: _allSubjectsState, // Teruskan list yang sudah ada
              ),
            ),
          );
        }
        return;
      }

      await _fetchCurrentSubjectData(); // Ambil data mata pelajaran saat ini
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memulai tryout: ${e.toString()}';
        });
        _showSnackBar(_errorMessage);
      }
      print('[InitializeTryout] Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi _loadAllSubjectsData() atau _fetchAllSubjectsInternally() DIHAPUS
  // karena SoalPage sekarang bergantung pada widget.allSubjects yang diteruskan.

  Future<void> _fetchCurrentSubjectData() async {
    // Endpoint ini (untuk mengambil data spesifik satu mata pelajaran) tetap sama.
    // URL: /api/student/tryout/:idTryout/:idSubject/taking
    final uri = Uri.parse(
        '$_baseUrl/api/student/tryout/${widget.tryoutId}/${widget.subjectId}/taking');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (mounted) _navigateToLogin();
      return;
    }

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    });
    print('[fetchCurrentSubjectData] URL: $uri');
    print(
        '[fetchCurrentSubjectData] Status: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _loadAnswersFromPrefs();

      if (mounted) {
        setState(() {
          _studentData = data['studentData'];
          _subjectData = data['subjectData'];
          _questions = data['questionData'] ?? [];
          _currentQuestionIndex = 0;

          if (_selectedAnswers.isEmpty && _questions.isNotEmpty) {
            (_questions).forEach((q) {
              final questionId = q['question_id']?.toString();
              final studentAnswerId = q['student_answer_id']?.toString();
              if (questionId != null &&
                  studentAnswerId != null &&
                  studentAnswerId.isNotEmpty) {
                _selectedAnswers[questionId] = studentAnswerId;
              }
            });
          }

          final duration = _subjectData?['total_waktu'] ?? 0;
          _timeRemainingInSeconds = (duration * 60).toInt();
          _startTimer();
        });
      }
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Gagal memuat data mata pelajaran. Status: ${response.statusCode}');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeRemainingInSeconds > 0) {
        setState(() {
          _timeRemainingInSeconds--;
        });
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() async {
    if (!mounted) return;

    final currentSbjIndex =
        _allSubjectsState.indexWhere((s) => s.id == widget.subjectId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tryout_${widget.tryoutId}_${widget.subjectId}_answers');

    if (currentSbjIndex != -1 &&
        currentSbjIndex < _allSubjectsState.length - 1) {
      final nextSubject = _allSubjectsState[currentSbjIndex + 1];
      _showSnackBar('Waktu habis! Memuat mata pelajaran berikutnya...');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SoalPage(
              tryoutId: widget.tryoutId,
              subjectId: nextSubject.id,
              allSubjects: _allSubjectsState, // Teruskan list yang sudah ada
            ),
          ),
        );
      }
    } else {
      _showSnackBar(
          'Semua mata pelajaran telah selesai! Menyelesaikan tryout...');
      await _finalizeTryout();
    }
  }

  Future<void> _handleAnswerSelect(
      String questionId, String? answerOptionIdToSelect) async {
    if (!mounted) return;

    String? newSelectedOptionId;
    if (_selectedAnswers[questionId] == answerOptionIdToSelect) {
      newSelectedOptionId = null;
    } else {
      newSelectedOptionId = answerOptionIdToSelect;
    }

    setState(() {
      if (newSelectedOptionId == null) {
        _selectedAnswers.remove(questionId);
      } else {
        _selectedAnswers[questionId] = newSelectedOptionId;
      }
    });
    await _saveAnswersToPrefs();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) _navigateToLogin();
        return;
      }

      final uri = Uri.parse(
          '$_baseUrl/api/student/tryout/${widget.tryoutId}/${widget.subjectId}/$questionId/taking');

      final body = jsonEncode({'answerOptionId': newSelectedOptionId});
      http.Response response;

      response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
        body: body,
      );
      print(
          '[handleAnswerSelect - PATCH attempt] Status: ${response.statusCode}');

      if (response.statusCode == 404) {
        print('[handleAnswerSelect] PATCH failed with 404, attempting POST.');
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token'
          },
          body: body,
        );
        print(
            '[handleAnswerSelect - POST attempt] Status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (newSelectedOptionId != null) {
          _showSnackBar("Jawaban disimpan!");
        } else {
          _showSnackBar("Jawaban dihapus!");
        }
      } else {
        _showSnackBar(
            'Gagal menyimpan/menghapus jawaban. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted)
        _showSnackBar('Terjadi galat jaringan saat menyimpan jawaban.');
      print('[handleAnswerSelect] Error: $e');
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      if (mounted)
        setState(() {
          _currentQuestionIndex++;
        });
    } else {
      _showSnackBar(
          'Ini adalah soal terakhir. Silakan periksa kembali jawaban Anda atau tunggu waktu habis.');
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      if (mounted)
        setState(() {
          _currentQuestionIndex--;
        });
    }
  }

  void _goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      if (mounted)
        setState(() {
          _currentQuestionIndex = index;
        });
    }
  }

  Future<void> _saveAnswersToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tryout_${widget.tryoutId}_${widget.subjectId}_answers';
    Map<String, String> answersToSave = {};
    _selectedAnswers.forEach((key, value) {
      if (value != null) {
        answersToSave[key] = value;
      }
    });
    await prefs.setString(key, jsonEncode(answersToSave));
  }

  Future<void> _loadAnswersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tryout_${widget.tryoutId}_${widget.subjectId}_answers';
    final savedAnswersJson = prefs.getString(key);
    if (mounted) {
      if (savedAnswersJson != null && savedAnswersJson.isNotEmpty) {
        try {
          final decodedAnswers =
              Map<String, dynamic>.from(jsonDecode(savedAnswersJson));
          setState(() {
            _selectedAnswers = decodedAnswers
                .map((key, value) => MapEntry(key, value?.toString()));
          });
        } catch (e) {
          print("Error decoding saved answers: $e");
          setState(() {
            _selectedAnswers = {};
          });
          await prefs.remove(key);
        }
      } else {
        setState(() {
          _selectedAnswers = {};
        });
      }
    }
  }

  Future<void> _finalizeTryout() async {
    if (!mounted) return;
    final uri =
        Uri.parse('$_baseUrl/api/student/tryout/${widget.tryoutId}/finalize');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      if (mounted) _navigateToLogin();
      return;
    }

    try {
      _showSnackBar("Sedang menyelesaikan tryout...");
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      });
      print('[finalizeTryout] URL: $uri');
      print(
          '[finalizeTryout] Status: ${response.statusCode}, Body: ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          _showSnackBar('Tryout berhasil diselesaikan!');
          for (var subject in _allSubjectsState) {
            await prefs
                .remove('tryout_${widget.tryoutId}_${subject.id}_answers');
          }
          Navigator.popUntil(context, ModalRoute.withName('/siswa/dashboard'));
        } else {
          _showSnackBar(
              'Gagal menyelesaikan tryout: ${jsonDecode(response.body)['message']}');
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Terjadi galat jaringan saat finalisasi.');
      print('[finalizeTryout] Error: $e');
    }
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), duration: const Duration(seconds: 3)));
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastSubject = _allSubjectsState.isNotEmpty &&
        _allSubjectsState.last.id == widget.subjectId;
    final bool isLastQuestion =
        _questions.isNotEmpty && _currentQuestionIndex == _questions.length - 1;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar Tryout?'),
            content: const Text(
                'Apakah Anda yakin ingin keluar? Jawaban yang sudah dipilih pada mata pelajaran ini akan tersimpan secara lokal dan bisa dilanjutkan nanti.'),
            actions: [
              TextButton(
                  child: const Text('Tidak'),
                  onPressed: () => Navigator.pop(context, false)),
              TextButton(
                  child: const Text('Ya, Keluar'),
                  onPressed: () => Navigator.pop(context, true)),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (mounted) {
            _timer?.cancel();
            Navigator.popUntil(
                context, ModalRoute.withName('/siswa/dashboard'));
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            _subjectData?['subjek'] ?? 'Memuat Tryout...',
            style: const TextStyle(
                color: AppColors.textLight, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 16)),
                    ))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoSection(),
                          const SizedBox(height: 20),
                          _questions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 40.0),
                                  child: Center(
                                      child: Text(
                                          "Tidak ada soal untuk mata pelajaran ini.",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: AppColors.textDark
                                                  .withOpacity(0.7)))),
                                )
                              : _buildQuestionSection(),
                          const SizedBox(height: 20),
                          if (_questions.isNotEmpty) _buildNavigationButtons(),
                          if (_questions.isNotEmpty &&
                              isLastSubject &&
                              isLastQuestion)
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: ElevatedButton.icon(
                                onPressed: _finalizeTryout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.textLight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text("Selesaikan Tryout",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _infoBox("Sisa Waktu : ${_formatTime(_timeRemainingInSeconds)}",
              icon: Icons.timer_outlined),
          _infoBox(_studentData?['nama'] ?? 'Siswa',
              icon: Icons.person_outline),
          _infoBox("NISN: ${_studentData?['nisn'] ?? '-'}",
              icon: Icons.badge_outlined),
          const SizedBox(height: 12),
          if (_questions.isNotEmpty)
            Text("Navigasi Soal:",
                style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 8),
          if (_questions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(_questions.length, (index) {
                final String questionId =
                    _questions[index]['question_id']?.toString() ?? '';
                final bool hasAnswered =
                    _selectedAnswers.containsKey(questionId) &&
                        _selectedAnswers[questionId] != null;
                return GestureDetector(
                  onTap: () => _goToQuestion(index),
                  child: _questionNumberBox(
                    index + 1,
                    index == _currentQuestionIndex,
                    hasAnswered,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const Center(
          child: Text("Soal tidak tersedia atau indeks di luar batas."));
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final String questionText =
        currentQuestion['question'] ?? 'Teks Soal Tidak Tersedia';
    final List<dynamic> answerOptionsData =
        currentQuestion['answer_options'] ?? [];
    final String currentQuestionId =
        currentQuestion['question_id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Soal ${_currentQuestionIndex + 1} dari ${_questions.length}:",
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(questionText,
              style: const TextStyle(
                  color: AppColors.textDark, fontSize: 16, height: 1.5)),
          const SizedBox(height: 20),
          if (answerOptionsData.isEmpty)
            const Text("Pilihan jawaban tidak tersedia.",
                style: TextStyle(color: AppColors.textDark)),
          ...answerOptionsData.map<Widget>((option) {
            final String optionId =
                option['id']?.toString() ?? UniqueKey().toString();
            final String optionTextAPI =
                option['text']?.toString() ?? 'Opsi tidak valid';
            int optionIndex = answerOptionsData.indexOf(option);
            String optionLabel =
                "${String.fromCharCode(65 + optionIndex)}. $optionTextAPI";

            final bool isSelected =
                _selectedAnswers[currentQuestionId] == optionId;
            return _answerButton(
              label: optionLabel,
              optionId: optionId,
              isSelected: isSelected,
              onPressed: (id) => _handleAnswerSelect(currentQuestionId, id),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textLight,
              disabledBackgroundColor: AppColors.secondary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Sebelumnya", style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _goToNextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
                _currentQuestionIndex < _questions.length - 1
                    ? "Berikutnya"
                    : "Soal Terakhir",
                style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(String text, {IconData? icon}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon, color: AppColors.textLight.withOpacity(0.9), size: 20),
          if (icon != null) const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              textAlign: icon != null ? TextAlign.left : TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionNumberBox(int number, bool isActive, bool hasAnswered) {
    Color boxColor;
    Color textColor;
    Border? border;

    if (isActive) {
      boxColor = AppColors.success;
      textColor = AppColors.textLight;
      border =
          Border.all(color: AppColors.textLight.withOpacity(0.8), width: 2);
    } else if (hasAnswered) {
      boxColor = AppColors.answeredQuestion;
      textColor = AppColors.textLight;
    } else {
      boxColor = AppColors.background.withOpacity(0.8);
      textColor = AppColors.textDark;
      border = Border.all(color: AppColors.secondary.withOpacity(0.4));
    }
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: isActive ? 4 : 2,
                offset: isActive ? const Offset(0, 2) : const Offset(0, 1))
          ]),
      child: Text(
        "$number",
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _answerButton({
    required String label,
    required String? optionId,
    required bool isSelected,
    required ValueChanged<String?> onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: () => onPressed(optionId),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.accent : AppColors.background,
          foregroundColor: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.secondary.withOpacity(0.7),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          elevation: isSelected ? 3 : 1,
          shadowColor: AppColors.secondary.withOpacity(0.5),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
          ),
        ),
      ),
    );
  }
}
