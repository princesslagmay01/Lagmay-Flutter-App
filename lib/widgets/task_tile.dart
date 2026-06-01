import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.todo,
    this.onEdit,
  });

  final Todo todo;
  final VoidCallback? onEdit;

  static const _cardBg = Colors.white;
  static const _accent = Color(0xFF00796B); // Teal
  static const _muted = Color(0xFF78909C);
  static const _textDark = Color(0xFF263238);

  Color get _priorityColor {
    switch (todo.priority) {
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
        return const Color(0xFFFDD835);
      case 'low':
      default:
        return const Color(0xFF43A047);
    }
  }

  bool get _isOverdue {
    if (todo.dueDate == null || todo.isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
    return due.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: todo.isDone ? _cardBg.withValues(alpha: 0.7) : _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: todo.isDone 
          ? [] 
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: todo.isDone ? _muted.withValues(alpha: 0.3) : _priorityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: todo.isDone ? _muted : _textDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                  decorationColor: _muted,
                                ),
                                child: Text(todo.title),
                              ),
                              
                              if (todo.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  todo.description,
                                  style: TextStyle(
                                    color: todo.isDone ? _muted.withValues(alpha: 0.6) : _muted.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              
                              const SizedBox(height: 12),
                              
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      todo.category.toUpperCase(),
                                      style: const TextStyle(
                                        color: _accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  
                                  if (todo.dueDate != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: _isOverdue ? const Color(0xFFE53935) : _muted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd').format(todo.dueDate!),
                                          style: TextStyle(
                                            color: _isOverdue ? const Color(0xFFE53935) : _muted,
                                            fontSize: 12,
                                            fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
