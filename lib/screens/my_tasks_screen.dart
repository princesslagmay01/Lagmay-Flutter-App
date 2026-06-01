import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _PendingAction {
  final bool expectedDone;
  final bool expectedDeleted;
  final bool isPermanentDelete;

  const _PendingAction({
    required this.expectedDone,
    required this.expectedDeleted,
    this.isPermanentDelete = false,
  });
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final _todoService = TodoService();

  static const _primary = Color(0xFF00796B); // Teal
  static const _background = Color(0xFFF0F4F8); // Light grey-blue
  static const _surface = Colors.white;
  static const _textDark = Color(0xFF263238);
  static const _textLight = Color(0xFF78909C);

  String _filter = 'Active'; // 'Active', 'Completed', 'Deleted'
  final Map<String, _PendingAction> _pendingActions = {};

  @override
  void initState() {
    super.initState();
    _todoService.refresh();
  }

  void _showAddTaskDialog([Todo? existingTodo]) {
    showDialog(
      context: context,
      builder: (context) => _TaskDialog(
        existingTodo: existingTodo,
        onSave: (title, desc, priority, dueDate, category) {
          if (existingTodo == null) {
            _todoService.addTodo(
              title: title,
              description: desc,
              priority: priority,
              dueDate: dueDate,
              category: category,
            ).catchError((e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
              }
            });
          } else {
            _todoService.updateTodo(
              existingTodo.id,
              title: title,
              description: desc,
              priority: priority,
              dueDate: dueDate,
              category: category,
            ).catchError((e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e')));
              }
            });
          }
        },
      ),
    );
  }

  void _confirmClearTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Empty Trash', style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
        content: const Text('Permanently delete all tasks in the trash?', style: TextStyle(color: _textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _todoService.clearTrash();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Trash cleared'),
                  backgroundColor: const Color(0xFFE53935),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: ['Active', 'Completed', 'Deleted'].map((f) {
          final isSelected = _filter == f;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) setState(() => _filter = f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<List<Todo>>(
          stream: _todoService.todosStream,
          initialData: _todoService.cachedTodos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: _primary));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final allTodos = snapshot.data ?? [];
            _pendingActions.removeWhere((id, action) {
              if (action.isPermanentDelete) return !allTodos.any((t) => t.id == id);
              final matches = allTodos.where((t) => t.id == id);
              if (matches.isEmpty) return true;
              final todo = matches.first;
              return todo.isDone == action.expectedDone && todo.isDeleted == action.expectedDeleted;
            });

            final mappedTodos = allTodos.map((t) {
              final pending = _pendingActions[t.id];
              if (pending != null) {
                if (pending.isPermanentDelete) return null;
                return t.copyWith(isDone: pending.expectedDone, isDeleted: pending.expectedDeleted);
              }
              return t;
            }).whereType<Todo>().toList();

            final nonDeletedTodos = mappedTodos.where((t) => !t.isDeleted).toList();
            final completedCount = nonDeletedTodos.where((t) => t.isDone).length;
            final progress = nonDeletedTodos.isEmpty ? 0.0 : completedCount / nonDeletedTodos.length;

            final todos = mappedTodos.where((t) {
              if (_filter == 'Active') return !t.isDone && !t.isDeleted;
              if (_filter == 'Completed') return t.isDone && !t.isDeleted;
              if (_filter == 'Deleted') return t.isDeleted;
              return true;
            }).toList();

            return Column(
              children: [
                // Circular Progress Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.black.withValues(alpha: 0.05),
                              color: _primary,
                            ),
                            Center(
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Tasks', style: TextStyle(color: _textDark, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text(
                              nonDeletedTodos.isEmpty ? 'No tasks yet' : '$completedCount of ${nonDeletedTodos.length} tasks completed',
                              style: const TextStyle(color: _textLight, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Segmented Controls
                _buildSegmentedControl(),
                
                if (_filter == 'Deleted')
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextButton.icon(
                        onPressed: () => _confirmClearTrash(context),
                        icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFE53935)),
                        label: const Text('Clear All', style: TextStyle(color: Color(0xFFE53935))),
                      ),
                    ),
                  ),

                // Tasks List
                Expanded(
                  child: todos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _filter == 'Deleted' ? Icons.delete_outline : _filter == 'Completed' ? Icons.check_circle_outline : Icons.assignment_outlined,
                                size: 80, color: Colors.black.withValues(alpha: 0.05),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filter == 'Deleted' ? 'Trash is empty' : _filter == 'Completed' ? 'No completed tasks' : 'All caught up!',
                                style: const TextStyle(color: _textLight, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: todos.length,
                          itemBuilder: (context, i) {
                            final todo = todos[i];
                            Widget? backgroundWidget;
                            Widget? secondaryBackgroundWidget;

                            if (_filter == 'Active') {
                              backgroundWidget = Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: const Color(0xFF43A047), borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 24),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                              );
                              secondaryBackgroundWidget = Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                              );
                            } else if (_filter == 'Completed') {
                              backgroundWidget = Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: const Color(0xFFFDD835), borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 24),
                                child: const Icon(Icons.undo_rounded, color: Colors.white, size: 32),
                              );
                              secondaryBackgroundWidget = Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                              );
                            } else if (_filter == 'Deleted') {
                              backgroundWidget = Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 24),
                                child: const Icon(Icons.restore_rounded, color: Colors.white, size: 32),
                              );
                              secondaryBackgroundWidget = Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: const Color(0xFFB71C1C), borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 32),
                              );
                            }

                            return Dismissible(
                              key: Key(todo.id),
                              direction: DismissDirection.horizontal,
                              background: backgroundWidget!,
                              secondaryBackground: secondaryBackgroundWidget!,
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  if (_filter == 'Deleted') {
                                    setState(() => _pendingActions[todo.id] = const _PendingAction(expectedDone: false, expectedDeleted: false, isPermanentDelete: true));
                                    _todoService.permanentDelete(todo.id);
                                  } else {
                                    setState(() => _pendingActions[todo.id] = _PendingAction(expectedDone: todo.isDone, expectedDeleted: true));
                                    _todoService.softDelete(todo.id);
                                  }
                                } else {
                                  if (_filter == 'Active') {
                                    setState(() => _pendingActions[todo.id] = const _PendingAction(expectedDone: true, expectedDeleted: false));
                                    _todoService.markDone(todo.id);
                                  } else if (_filter == 'Completed') {
                                    setState(() => _pendingActions[todo.id] = const _PendingAction(expectedDone: false, expectedDeleted: false));
                                    _todoService.markUndone(todo.id);
                                  } else if (_filter == 'Deleted') {
                                    setState(() => _pendingActions[todo.id] = const _PendingAction(expectedDone: false, expectedDeleted: false));
                                    _todoService.restore(todo.id);
                                  }
                                }
                              },
                              child: TaskTile(todo: todo, onEdit: _filter == 'Deleted' ? null : () => _showAddTaskDialog(todo)),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _filter == 'Deleted'
          ? null
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: FloatingActionButton(
                onPressed: () => _showAddTaskDialog(),
                backgroundColor: _primary,
                elevation: 0,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            ),
    );
  }
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({this.existingTodo, required this.onSave});

  final Todo? existingTodo;
  final void Function(String title, String description, String priority, DateTime? dueDate, String category) onSave;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  String _priority = 'low';
  String _category = 'personal';
  DateTime? _dueDate;

  static const _primary = Color(0xFF00796B); // Teal
  static const _surface = Colors.white;
  static const _textDark = Color(0xFF263238);
  static const _textLight = Color(0xFF78909C);
  final _categories = ['personal', 'school', 'work', 'project', 'other'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingTodo?.title);
    _descCtrl = TextEditingController(text: widget.existingTodo?.description);
    if (widget.existingTodo != null) {
      _priority = widget.existingTodo!.priority;
      _category = widget.existingTodo!.category;
      _dueDate = widget.existingTodo!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: _primary, onPrimary: Colors.white, surface: _surface)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existingTodo == null ? 'Create Task' : 'Edit Task',
                  style: const TextStyle(color: _textDark, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 24),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: _textDark),
                decoration: InputDecoration(
                  labelText: 'Task Title', labelStyle: const TextStyle(color: _textLight),
                  filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                style: const TextStyle(color: _textDark, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)', labelStyle: const TextStyle(color: _textLight),
                  filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority, dropdownColor: _surface,
                      style: const TextStyle(color: _textDark, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Priority', labelStyle: const TextStyle(color: _textLight),
                        filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category, dropdownColor: _surface,
                      style: const TextStyle(color: _textDark, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Category', labelStyle: const TextStyle(color: _textLight),
                        filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: _dueDate == null ? _textLight : _primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate == null ? 'Set a deadline...' : DateFormat('EEE, MMM d, yyyy').format(_dueDate!),
                          style: TextStyle(color: _dueDate == null ? _textLight : _textDark, fontSize: 14),
                        ),
                      ),
                      if (_dueDate != null)
                        InkWell(onTap: () => setState(() => _dueDate = null), child: const Icon(Icons.close_rounded, size: 18, color: _textLight)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _textLight))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_titleCtrl.text.trim().isEmpty) return;
                      widget.onSave(_titleCtrl.text, _descCtrl.text, _priority, _dueDate, _category);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                    ),
                    child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
