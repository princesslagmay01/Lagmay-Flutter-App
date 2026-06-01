import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String studentId;
  final DateTime date;
  final int totalPoints;
  final int score;

  const Project({
    required this.id,
    required this.studentId,
    required this.date,
    required this.totalPoints,
    required this.score,
  });

  factory Project.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      studentId: d['student_id'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPoints: (d['total_points'] as num?)?.toInt() ?? 0,
      score: (d['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'date': Timestamp.fromDate(date),
        'total_points': totalPoints,
        'score': score,
      };

  double get percentage => totalPoints == 0 ? 0 : (score / totalPoints) * 100;
}
