import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _firestoreService = FirestoreService();
  final _profileService = ProfileService();
  final _authService = AuthService();

  Student? _student;
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  List<Attendance> _attendance = [];
  List<Quiz> _quizzes = [];
  List<Exam> _exams = [];
  List<Activity> _activities = [];
  List<OralRecitation> _oral = [];
  List<Project> _projects = [];

  final Map<String, List<Map<String, dynamic>>> _simulated = {
    'quizzes': [],
    'exams': [],
    'activities': [],
    'oral': [],
    'projects': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final email = _authService.currentUser?.email ?? _authService.offlineUser?['email'];
    if (email == null) {
      setState(() {
        _error = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      // Simulate loading local data for offline, but Grades usually need Firestore
      // For now, if offline, this might throw if no cache exists.
      final results = await Future.wait([
        _firestoreService.getStudentByEmail(email).catchError((_) => null),
        _profileService.getProfile().first.catchError((_) => null),
      ]);

      _student = results[0] as Student?;
      _profile = results[1] as UserProfile?;

      if (_student == null) {
        setState(() {
          _error = 'No student record found for $email. (Check connection)';
          _isLoading = false;
        });
        return;
      }

      final sid = _student!.id;
      final collections = await Future.wait([
        _firestoreService.getAttendance(sid).first.catchError((_) => <Attendance>[]),
        _firestoreService.getQuizzes(sid).first.catchError((_) => <Quiz>[]),
        _firestoreService.getExams(sid).first.catchError((_) => <Exam>[]),
        _firestoreService.getActivities(sid).first.catchError((_) => <Activity>[]),
        _firestoreService.getOralRecitations(sid).first.catchError((_) => <OralRecitation>[]),
        _firestoreService.getProjects(sid).first.catchError((_) => <Project>[]),
      ]);

      setState(() {
        _attendance = collections[0] as List<Attendance>;
        _quizzes = collections[1] as List<Quiz>;
        _exams = collections[2] as List<Exam>;
        _activities = collections[3] as List<Activity>;
        _oral = collections[4] as List<OralRecitation>;
        _projects = collections[5] as List<Project>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load student data. Ensure you have internet.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showSimulateDialog(
    BuildContext context,
    String section,
    String label, {
    bool isPoints = false,
  }) async {
    final scoreCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    const surfaceColor = Colors.white;
    const textPrimary = Color(0xFF263238);
    const textMuted = Color(0xFF78909C);
    const primary = Color(0xFF00796B);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science_rounded, color: primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What-If Simulator',
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Add a simulated score',
                            style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: isPoints ? 'Points earned' : 'Your score',
                  labelStyle: const TextStyle(color: textMuted),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              if (!isPoints) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Total items / points',
                    labelStyle: const TextStyle(color: textMuted),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final score = int.tryParse(scoreCtrl.text.trim());
                      if (score == null || score < 0) return;
                      if (!isPoints) {
                        final total = int.tryParse(totalCtrl.text.trim());
                        if (total == null || total <= 0) return;
                        setState(() {
                          _simulated[section]!.add({
                            'score': score,
                            'total': total,
                            'label': label,
                          });
                        });
                      } else {
                        setState(() {
                          _simulated[section]!.add({
                            'score': score,
                            'total': 0,
                            'label': label,
                          });
                        });
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Simulate', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsModal(BuildContext context, String title, Widget content, String sectionKey, {bool showSim = false, bool isPoints = false, String simLabel = ''}) {
    const primary = Color(0xFF00796B);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final hasSim = _simulated[sectionKey]?.isNotEmpty ?? false;
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    height: 5,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (showSim)
                        Row(
                          children: [
                            if (hasSim)
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() => _simulated[sectionKey]!.clear());
                                  setModalState(() {});
                                },
                              ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _showSimulateDialog(context, sectionKey, simLabel, isPoints: isPoints);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Simulate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: const BorderSide(color: primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        if (hasSim) ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _simulated[sectionKey]!.map((sim) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    isPoints ? 'Simulated: +${sim['score']} pts' : 'Simulated: ${sim['score']} / ${sim['total']}',
                                    style: const TextStyle(color: primary, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(),
                        ],
                        content,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F4F8);
    const primary = Color(0xFF00796B);
    const primaryDark = Color(0xFF004D40);

    if (_isLoading) {
      return const Scaffold(backgroundColor: bgColor, body: Center(child: CircularProgressIndicator(color: primary)));
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.black87))),
      );
    }

    final displayName = _profile != null && _profile!.name.isNotEmpty ? _profile!.name : _student!.name;
    final displaySection = _profile != null && _profile!.section.isNotEmpty ? _profile!.section : _student!.section;

    // Calculations based on fetched lists
    int attTotal = _attendance.length;
    int attPresent = _attendance.where((a) => a.status.toLowerCase() == 'present').length;
    double attGrade = attTotal > 0 ? (attPresent / attTotal) * 100 : 100;

    int qScore = 0; int qTotal = 0;
    for (var q in _quizzes) { qScore += q.score; qTotal += q.totalItems; }
    for (var s in _simulated['quizzes']!) { qScore += s['score'] as int; qTotal += s['total'] as int; }
    double qGrade = qTotal > 0 ? (qScore / qTotal) * 100 : 100;

    int eScore = 0; int eTotal = 0;
    for (var e in _exams) { eScore += e.score; eTotal += e.totalItems; }
    for (var s in _simulated['exams']!) { eScore += s['score'] as int; eTotal += s['total'] as int; }
    double eGrade = eTotal > 0 ? (eScore / eTotal) * 100 : 100;

    int aScore = 0; int aTotal = 0;
    for (var a in _activities) { aScore += a.score; aTotal += a.totalPoints; }
    for (var s in _simulated['activities']!) { aScore += s['score'] as int; aTotal += s['total'] as int; }
    double aGrade = aTotal > 0 ? (aScore / aTotal) * 100 : 100;

    int oScore = 0; int oTotal = 0;
    for (var o in _oral) { oScore += o.points; oTotal += 20; /* mock assumed total */ }
    for (var s in _simulated['oral']!) { oScore += s['score'] as int; oTotal += s['total'] as int; }
    double oGrade = oTotal > 0 ? (oScore / oTotal) * 100 : 100;

    int pScore = 0;
    for (var p in _projects) { pScore += p.score; }
    for (var s in _simulated['projects']!) { pScore += s['score'] as int; }

    double prelim = (attGrade * 0.1) + (oGrade * 0.1) + (qGrade * 0.2) + (aGrade * 0.2) + (eGrade * 0.4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Dashboard Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, primaryDark]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Section: $displaySection', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Grade', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('${prelim.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildGridCard(
                    title: 'Attendance',
                    icon: Icons.how_to_reg,
                    color: Colors.green,
                    value: '${attGrade.toStringAsFixed(0)}%',
                    onTap: () => _showDetailsModal(context, 'Attendance', Column(
                      children: _attendance.map((a) => ListTile(
                        leading: Icon(Icons.event, color: a.status.toLowerCase() == 'present' ? Colors.green : Colors.red),
                        title: Text(DateFormat('MMM dd, yyyy').format(a.date)),
                        trailing: Text(a.status, style: TextStyle(fontWeight: FontWeight.bold, color: a.status.toLowerCase() == 'present' ? Colors.green : Colors.red)),
                      )).toList(),
                    ), 'attendance'),
                  ),
                  _buildGridCard(
                    title: 'Quizzes',
                    icon: Icons.quiz,
                    color: Colors.orange,
                    value: '${qGrade.toStringAsFixed(0)}%',
                    onTap: () => _showDetailsModal(context, 'Quizzes', Column(
                      children: _quizzes.map((q) => ListTile(
                        leading: const Icon(Icons.article, color: Colors.orange),
                        title: Text(DateFormat('MMM dd').format(q.date)),
                        trailing: Text('${q.score}/${q.totalItems}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )).toList(),
                    ), 'quizzes', showSim: true, simLabel: 'Quiz'),
                  ),
                  _buildGridCard(
                    title: 'Exams',
                    icon: Icons.assignment_turned_in,
                    color: Colors.redAccent,
                    value: '${eGrade.toStringAsFixed(0)}%',
                    onTap: () => _showDetailsModal(context, 'Exams', Column(
                      children: _exams.map((e) => ListTile(
                        leading: const Icon(Icons.assignment_turned_in, color: Colors.redAccent),
                        title: Text(e.type.toUpperCase()),
                        trailing: Text('${e.score}/${e.totalItems}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )).toList(),
                    ), 'exams', showSim: true, simLabel: 'Exam'),
                  ),
                  _buildGridCard(
                    title: 'Activities',
                    icon: Icons.local_activity,
                    color: Colors.blueAccent,
                    value: '${aGrade.toStringAsFixed(0)}%',
                    onTap: () => _showDetailsModal(context, 'Activities', Column(
                      children: _activities.map((a) => ListTile(
                        leading: const Icon(Icons.local_activity, color: Colors.blueAccent),
                        title: Text(DateFormat('MMM dd').format(a.date)),
                        trailing: Text('${a.score}/${a.totalPoints}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )).toList(),
                    ), 'activities', showSim: true, simLabel: 'Activity'),
                  ),
                  _buildGridCard(
                    title: 'Oral Recitation',
                    icon: Icons.record_voice_over,
                    color: Colors.deepPurpleAccent,
                    value: '${oGrade.toStringAsFixed(0)}%',
                    onTap: () => _showDetailsModal(context, 'Oral Recitation', Column(
                      children: _oral.map((o) => ListTile(
                        leading: const Icon(Icons.record_voice_over, color: Colors.deepPurpleAccent),
                        title: Text(DateFormat('MMM dd').format(o.date)),
                        trailing: Text('${o.points} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )).toList(),
                    ), 'oral', showSim: true, simLabel: 'Recitation'),
                  ),
                  _buildGridCard(
                    title: 'Projects',
                    icon: Icons.build_circle,
                    color: primary,
                    value: '$pScore pts',
                    onTap: () => _showDetailsModal(context, 'Projects', Column(
                      children: _projects.map((p) => ListTile(
                        leading: const Icon(Icons.build_circle, color: primary),
                        title: Text(DateFormat('MMM dd').format(p.date)),
                        trailing: Text('+${p.score} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary)),
                      )).toList(),
                    ), 'projects', showSim: true, isPoints: true, simLabel: 'Project'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
