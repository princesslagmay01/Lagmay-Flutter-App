import 'package:cloud_firestore/cloud_firestore.dart';

class OralRecitation {
  final String id;
  final String studentId;
  final DateTime date;
  final int points;

  const OralRecitation({
    required this.id,
    required this.studentId,
    required this.date,
    required this.points,
  });

  factory OralRecitation.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OralRecitation(
      id: doc.id,
      studentId: d['student_id'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      points: (d['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'date': Timestamp.fromDate(date),
        'points': points,
      };
}
