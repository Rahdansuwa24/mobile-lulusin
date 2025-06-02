// lib/models/subject.dart (create this new file)
class Subject {
  final String id;
  final String name;
  final String category;

  Subject({required this.id, required this.name, required this.category});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['subject_id'].toString(), // Ensure it's a String
      name: json['subject_name'] as String,
      category: json['subject_category'] as String,
    );
  }
}
