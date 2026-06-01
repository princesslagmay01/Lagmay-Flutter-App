import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final String section;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.section,
    required this.createdAt,
  });

  factory Student.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      section: d['section'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'section': section,
        'created_at': Timestamp.fromDate(createdAt),
      };
}
