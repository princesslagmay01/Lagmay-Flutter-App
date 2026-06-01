import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';

/// Handles reading and writing user profile data to personal Firebase.
class ProfileService {
  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(app: Firebase.app());
  FirebaseAuth get _auth => FirebaseAuth.instanceFor(app: Firebase.app());

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users');

  // ── Create ───────────────────────────────────────────────────────────────

  /// Called right after registration to save the student's profile info.
  Future<void> createProfile({
    required String name,
    required String idNumber,
    required String section,
  }) async {
    if (_userId == null) return;
    await _collection.doc(_userId).set({
      'name': name.trim(),
      'id_number': idNumber.trim(),
      'section': section.trim(),
      'avatar_id': 'avatar_01',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Stream of the current user's profile.
  Stream<UserProfile?> getProfile() {
    if (_userId == null) return const Stream.empty();
    return _collection.doc(_userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  // ── Update ───────────────────────────────────────────────────────────────

  /// Update the avatar selection.
  Future<void> updateAvatar(String avatarId) async {
    if (_userId == null) return;
    await _collection.doc(_userId).update({'avatar_id': avatarId});
  }

  /// Update name, id number, section.
  Future<void> updateProfile({
    required String name,
    required String idNumber,
    required String section,
  }) async {
    if (_userId == null) return;
    await _collection.doc(_userId).update({
      'name': name.trim(),
      'id_number': idNumber.trim(),
      'section': section.trim(),
    });
  }
}
