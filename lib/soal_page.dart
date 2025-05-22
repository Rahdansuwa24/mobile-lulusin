import 'package:flutter/material.dart';

class SoalPage extends StatefulWidget {
  const SoalPage({super.key});

  @override
  _SoalPageState createState() => _SoalPageState();
}

class _SoalPageState extends State<SoalPage> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // Tambahkan ini agar scrollable
          child: Center(
            child: Container(
              width: 350,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Informasi pengguna
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3557),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text("Selamat Mengerjakan",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        infoBox("Waktu Tersisa : 32:56"),
                        infoBox("Aqil Yogi Pramanto"),
                        infoBox("006527262899"),
                        infoBox(
                            "Tes Potensi Skolastik\nLiterasi dalam bahasa Indonesia tahun 2025"),
                        const SizedBox(height: 12),

                        // Tombol expand/collapse
                        GestureDetector(
                          onTap: () => setState(() => isExpanded = !isExpanded),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              Text(
                                isExpanded
                                    ? "Sembunyikan Nomor Soal"
                                    : "Tampilkan Nomor Soal",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Nomor Soal
                        if (isExpanded)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(30, (index) {
                              return Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      index == 0 ? Colors.green : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                      color: index == 0
                                          ? Colors.white
                                          : const Color(0xFF1D3557),
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pertanyaan dan opsi jawaban
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3557),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Lorem Ipsum is simply dummy text of the printing and typesetting industry...",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            answerButton("Lorem Ipsum A"),
                            answerButton("Lorem Ipsum B"),
                            answerButton("Lorem Ipsum C"),
                            answerButton("Lorem Ipsum D"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            navigationButton("Sebelumnya"),
                            navigationButton("Next"),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget infoBox(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF457B9D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget answerButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget navigationButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label),
    );
  }
}
