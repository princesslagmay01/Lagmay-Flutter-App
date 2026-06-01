import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String idNumber;
  final String section;
  final String avatarId; // references one of the 15 built-in avatar icons
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.idNumber,
    required this.section,
    this.avatarId = 'avatar_01',
    required this.createdAt,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: d['name'] ?? '',
      idNumber: d['id_number'] ?? '',
      section: d['section'] ?? '',
      avatarId: d['avatar_id'] ?? 'avatar_01',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'id_number': idNumber,
        'section': section,
        'avatar_id': avatarId,
        'created_at': Timestamp.fromDate(createdAt),
      };

  UserProfile copyWith({String? name, String? idNumber, String? section, String? avatarId}) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        idNumber: idNumber ?? this.idNumber,
        section: section ?? this.section,
        avatarId: avatarId ?? this.avatarId,
        createdAt: createdAt,
      );
}
