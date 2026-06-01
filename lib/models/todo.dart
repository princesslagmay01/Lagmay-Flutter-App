import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isDone;
  final DateTime createdAt;
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;
  final String category;
  final bool isDeleted; // soft-delete flag

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isDone,
    required this.createdAt,
    this.priority = 'low',
    this.dueDate,
    this.category = 'personal',
    this.isDeleted = false,
  });

  factory Todo.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      userId: d['user_id'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      isDone: d['is_done'] ?? false,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: d['priority'] ?? 'low',
      dueDate: (d['due_date'] as Timestamp?)?.toDate(),
      category: d['category'] ?? 'personal',
      isDeleted: d['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'is_done': isDone,
        'created_at': Timestamp.fromDate(createdAt),
        'priority': priority,
        'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'category': category,
        'is_deleted': isDeleted,
      };

  Todo copyWith({
    bool? isDone,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    String? category,
    bool? isDeleted,
  }) =>
      Todo(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        category: category ?? this.category,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
