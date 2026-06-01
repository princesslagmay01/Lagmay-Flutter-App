import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String studentId;
  final DateTime date;
  final String type; // 'short' | 'long'
  final int totalItems;
  final int score;

  const Quiz({
    required this.id,
    required this.studentId,
    required this.date,
    required this.type,
    required this.totalItems,
    required this.score,
  });

  factory Quiz.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      studentId: d['student_id'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: d['type'] ?? 'short',
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
