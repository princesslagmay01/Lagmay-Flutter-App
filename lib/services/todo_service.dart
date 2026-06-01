import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'local_db_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';

class TodoService {
  static final TodoService _instance = TodoService._internal();
  factory TodoService() => _instance;
  
  final LocalDbService _localDb = LocalDbService();
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();

  TodoService._internal() {
    if (kIsWeb) {
      _listenToFirestore();
    } else {
      _fetchAndBroadcast();
    }
  }

  void _listenToFirestore() {
    if (_userId == null) return;
    FirebaseFirestore.instance
        .collection('todos')
        .where('user_id', isEqualTo: _userId)
        .where('is_deleted', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      final todos = snapshot.docs.map((doc) {
        final data = doc.data();
        return Todo(
          id: doc.id,
          userId: data['user_id'],
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          isDone: data['is_done'] == true,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          priority: data['priority'] ?? 'low',
          dueDate: (data['due_date'] as Timestamp?)?.toDate(),
          category: data['category'] ?? 'personal',
          isDeleted: data['is_deleted'] == true,
        );
      }).toList();
      
      todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cachedTodos = todos;
      _tasksController.add(todos);
    });
  }

  String? get _userId => _authService.offlineUser?['id'] ?? _authService.currentUser?.uid;

  List<Todo>? _cachedTodos;

  // Stream controller to broadcast task updates
  final StreamController<List<Todo>> _tasksController = StreamController<List<Todo>>.broadcast();

  // Initial fetch is now in _internal constructor

  void _fetchAndBroadcast() async {
    if (_userId == null) {
      _tasksController.add([]);
      return;
    }
    final maps = await _localDb.getTasksForUser(_userId!);
    final todos = maps.map((map) {
      return Todo(
        id: map['id'],
        userId: map['user_id'],
        title: map['title'],
        description: map['description'],
        isDone: map['is_done'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
        priority: map['priority'],
        dueDate: map['due_date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['due_date']) : null,
        category: map['category'],
        isDeleted: map['is_deleted'] == 1,
      );
    }).toList();
    
    // Sort by created at descending
    todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _cachedTodos = todos;
    _tasksController.add(todos);
  }

  Stream<List<Todo>> get todosStream => _tasksController.stream;
  List<Todo> get cachedTodos => _cachedTodos ?? [];

  void refresh() {
    if (kIsWeb) {
      // Stream is automatically listening, no manual fetch needed
    } else {
      _fetchAndBroadcast();
    }
  }

  Future<void> addTodo({
    required String title,
    String description = '',
    String priority = 'low',
    DateTime? dueDate,
    String category = 'personal',
  }) async {
    if (_userId == null) return;
    final id = const Uuid().v4();
    
    if (kIsWeb) {
      await FirebaseFirestore.instance.collection('todos').doc(id).set({
        'user_id': _userId,
        'title': title.trim(),
        'description': description.trim(),
        'is_done': false,
        'created_at': FieldValue.serverTimestamp(),
        'priority': priority,
        'due_date': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'category': category,
        'is_deleted': false,
      });
      return;
    }
    final taskMap = {
      'id': id,
      'user_id': _userId,
      'title': title.trim(),
      'description': description.trim(),
      'is_done': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'priority': priority,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'category': category,
      'is_deleted': 0,
      'sync_status': 'pending_create'
    };
    
    await _localDb.insertTask(taskMap);
    _fetchAndBroadcast();
    _syncService.syncPendingData();
  }

  Future<void> markDone(String todoId) async {
    await _updateTaskField(todoId, {'is_done': 1, 'is_deleted': 0});
  }

  Future<void> markUndone(String todoId) async {
    await _updateTaskField(todoId, {'is_done': 0, 'is_deleted': 0});
  }

  Future<void> softDelete(String todoId) async {
    await _updateTaskField(todoId, {'is_deleted': 1, 'sync_status': 'pending_delete'});
  }

  Future<void> restore(String todoId) async {
    await _updateTaskField(todoId, {'is_deleted': 0, 'is_done': 0});
  }

  Future<void> updateTodo(
    String todoId, {
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
    required String category,
  }) async {
    await _updateTaskField(todoId, {
      'title': title.trim(),
      'description': description.trim(),
      'priority': priority,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'category': category,
    });
  }

  Future<void> _updateTaskField(String taskId, Map<String, dynamic> updates) async {
    if (_userId == null) return;

    if (kIsWeb) {
      // Map SQLite fields to Firestore fields where necessary
      final firestoreUpdates = Map<String, dynamic>.from(updates);
      if (firestoreUpdates.containsKey('is_done')) {
        firestoreUpdates['is_done'] = firestoreUpdates['is_done'] == 1;
      }
      if (firestoreUpdates.containsKey('is_deleted')) {
        firestoreUpdates['is_deleted'] = firestoreUpdates['is_deleted'] == 1;
      }
      if (firestoreUpdates.containsKey('due_date') && firestoreUpdates['due_date'] != null) {
        firestoreUpdates['due_date'] = Timestamp.fromMillisecondsSinceEpoch(firestoreUpdates['due_date']);
      }
      await FirebaseFirestore.instance.collection('todos').doc(taskId).update(firestoreUpdates);
      return;
    }

    final db = await _localDb.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);
    if (maps.isEmpty) return;
    
    final map = Map<String, dynamic>.from(maps.first);
    updates.forEach((key, value) {
      map[key] = value;
    });
    
    if (map['sync_status'] != 'pending_create' && map['sync_status'] != 'pending_delete') {
       map['sync_status'] = 'pending_update';
    }
    
    await _localDb.updateTask(map);
    _fetchAndBroadcast();
    _syncService.syncPendingData();
  }

  Future<void> permanentDelete(String todoId) async {
    if (kIsWeb) {
      await FirebaseFirestore.instance.collection('todos').doc(todoId).delete();
      return;
    }
    final db = await _localDb.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [todoId]);
    _fetchAndBroadcast();
    // For permanent delete, we should ideally delete from firestore too, but sync_service pending_delete handles the firestore side.
  }

  Future<void> clearTrash() async {
    if (_userId == null) return;
    if (kIsWeb) {
      final snapshot = await FirebaseFirestore.instance
          .collection('todos')
          .where('user_id', isEqualTo: _userId)
          .where('is_deleted', isEqualTo: true)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return;
    }
    final db = await _localDb.database;
    await db.delete('tasks', where: 'user_id = ? AND is_deleted = 1', whereArgs: [_userId]);
    _fetchAndBroadcast();
  }
}
