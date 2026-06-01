import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String studentId;
  final DateTime date;
  final String status; // 'present' | 'absent' | 'late'

  const Attendance({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });

  factory Attendance.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Attendance(
      id: doc.id,
      studentId: d['student_id'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] ?? 'present',
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'date': Timestamp.fromDate(date),
        'status': status,
      };

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';
}
