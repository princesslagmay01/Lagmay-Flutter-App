import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'local_db_service.dart';
import 'sync_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalDbService _localDb = LocalDbService();
  final SyncService _syncService = SyncService();

  FirebaseAuth get _auth => FirebaseAuth.instanceFor(
        app: Firebase.app(),
      );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Offline user state management (if currentUser is null but we logged in offline)
  Map<String, dynamic>? _offlineUser;
  Map<String, dynamic>? get offlineUser => _offlineUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    bool hasInternet = await _syncService.hasInternet();
    if (hasInternet || kIsWeb) {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } else {
      // Check offline db (Android only)
      final user = await _localDb.getUser(email.trim(), password);
      if (user != null) {
        _offlineUser = user;
      } else {
        throw Exception("No internet connection and no local account found.");
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String idNumber,
    required String section,
  }) async {
    bool hasInternet = await _syncService.hasInternet();
    if (hasInternet || kIsWeb) {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Profile creation is handled in ProfileService usually, but we need it here for offline consistency or we can update ProfileService.
    } else {
      // Create offline (Android only)
      String localId = const Uuid().v4();
      Map<String, dynamic> offlineUserMap = {
        'id': localId,
        'email': email.trim(),
        'password': password,
        'name': name,
        'id_number': idNumber,
        'section': section,
        'avatar_id': 'avatar_01',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 'pending_create'
      };
      await _localDb.insertUser(offlineUserMap);
      _offlineUser = offlineUserMap;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    bool hasInternet = await _syncService.hasInternet();
    if (hasInternet || kIsWeb) {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } else {
      throw Exception("Cannot reset password offline.");
    }
  }

  Future<void> signOut() async {
    _offlineUser = null;
    await _auth.signOut();
  }

  static String friendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        default:
          return e.message ?? 'An unexpected error occurred.';
      }
    }
    return e.toString();
  }
}
