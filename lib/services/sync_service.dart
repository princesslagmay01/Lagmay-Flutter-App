import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_db_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalDbService _localDb = LocalDbService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void startListening() {
    if (kIsWeb) return;
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncPendingData();
      }
    });
  }

  Future<bool> hasInternet() async {
    if (kIsWeb) return true;
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
  }

  Future<void> syncPendingData() async {
    if (kIsWeb) return;
    // Sync Users First
    final pendingUsers = await _localDb.getPendingUsers();
    for (var u in pendingUsers) {
      try {
        final email = u['email'] as String;
        final password = u['password'] as String;
        
        // Create in Firebase Auth
        UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        String firebaseUid = cred.user!.uid;

        // Create profile in Firestore
        await _firestore.collection('users').doc(firebaseUid).set({
          'name': u['name'],
          'id_number': u['id_number'],
          'section': u['section'],
          'avatar_id': u['avatar_id'],
          'created_at': Timestamp.fromMillisecondsSinceEpoch(u['created_at'] as int),
        });

        // Mark as synced locally
        await _localDb.updateSyncStatus('offline_users', u['id'] as String, 'synced');
        
        // Update user ID in tasks if they were created offline
        final db = await _localDb.database;
        await db.update('tasks', {'user_id': firebaseUid}, where: 'user_id = ?', whereArgs: [u['id']]);

      } catch (e) {
        debugPrint("Failed to sync user: $e");
      }
    }

    // Sync Tasks
    final pendingTasks = await _localDb.getPendingTasks();
    for (var t in pendingTasks) {
      try {
        final status = t['sync_status'] as String;
        final taskId = t['id'] as String;
        
        Map<String, dynamic> firestoreMap = {
          'user_id': t['user_id'],
          'title': t['title'],
          'description': t['description'],
          'is_done': t['is_done'] == 1,
          'created_at': Timestamp.fromMillisecondsSinceEpoch(t['created_at'] as int),
          'priority': t['priority'],
          'category': t['category'],
          'is_deleted': t['is_deleted'] == 1,
        };
        
        if (t['due_date'] != null) {
           firestoreMap['due_date'] = Timestamp.fromMillisecondsSinceEpoch(t['due_date'] as int);
        }

        if (status == 'pending_create' || status == 'pending_update') {
          await _firestore.collection('todos').doc(taskId).set(firestoreMap, SetOptions(merge: true));
          await _localDb.updateSyncStatus('tasks', taskId, 'synced');
        } else if (status == 'pending_delete') {
          await _firestore.collection('todos').doc(taskId).update({'is_deleted': true});
          await _localDb.updateSyncStatus('tasks', taskId, 'synced');
        }
      } catch (e) {
        debugPrint("Failed to sync task: $e");
      }
    }
  }
}
