import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  final String id;
  final String studentId;
  final DateTime date;
  final String type; // 'prelim' | 'midterm' | 'finals'
  final int totalItems;
  final int score;

  const Exam({
    required this.id,
    required this.studentId,
    required this.date,
    required this.type,
    required this.totalItems,
    required this.score,
  });

  factory Exam.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Exam(
      id: doc.id,
      studentId: d['student_id'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: d['type'] ?? 'prelim',
      totalItems: (d['total_items'] as num?)?.toInt() ?? 0,
      score: (d['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'date': Timestamp.fromDate(date),
        'type': type,
        'total_items': totalItems,
        'score': score,
      };

  double get percentage => totalItems == 0 ? 0 : (score / totalItems) * 100;
}
