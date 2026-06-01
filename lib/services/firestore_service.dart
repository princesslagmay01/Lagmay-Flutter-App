
import '../models/models.dart';

/// MOCK Firestore Service that returns hardcoded temporary data.
/// 
/// Replace this file with the real FirestoreService once your instructor
/// provides their Firebase API keys.
class FirestoreService {
  
  // ── Student ────────────────────────────────────────────────────────────────

  Future<Student?> getStudentByEmail(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return a mock student regardless of the email used to login
    return Student(
      id: 'mock_student_123',
      name: 'John Doe',
      email: email,
      section: '3A',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );
  }

  // ── Attendance ─────────────────────────────────────────────────────────────

  Stream<List<Attendance>> getAttendance(String studentId) {
    return Stream.value([
      Attendance(id: 'a1', studentId: studentId, date: DateTime.now(), status: 'present'),
      Attendance(id: 'a2', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 1)), status: 'present'),
      Attendance(id: 'a3', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 2)), status: 'late'),
      Attendance(id: 'a4', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 3)), status: 'absent'),
    ]);
  }

  // ── Quizzes ────────────────────────────────────────────────────────────────

  Stream<List<Quiz>> getQuizzes(String studentId) {
    return Stream.value([
      Quiz(id: 'q1', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 5)), type: 'short', totalItems: 20, score: 18),
      Quiz(id: 'q2', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 15)), type: 'long', totalItems: 50, score: 45),
      Quiz(id: 'q3', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 30)), type: 'short', totalItems: 20, score: 15),
    ]);
  }

  // ── Exams ──────────────────────────────────────────────────────────────────

  Stream<List<Exam>> getExams(String studentId) {
    return Stream.value([
      Exam(id: 'e1', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 20)), type: 'prelim', totalItems: 100, score: 88),
      Exam(id: 'e2', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 2)), type: 'midterm', totalItems: 100, score: 92),
    ]);
  }

  // ── Activities ─────────────────────────────────────────────────────────────

  Stream<List<Activity>> getActivities(String studentId) {
    return Stream.value([
      Activity(id: 'act1', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 10)), totalPoints: 30, score: 28),
      Activity(id: 'act2', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 25)), totalPoints: 50, score: 40),
    ]);
  }

  // ── Oral Recitations ───────────────────────────────────────────────────────

  Stream<List<OralRecitation>> getOralRecitations(String studentId) {
    return Stream.value([
      OralRecitation(id: 'o1', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 8)), points: 15),
      OralRecitation(id: 'o2', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 22)), points: 20),
    ]);
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Stream<List<Project>> getProjects(String studentId) {
    return Stream.value([
      Project(id: 'p1', studentId: studentId, date: DateTime.now().subtract(const Duration(days: 40)), totalPoints: 100, score: 95),
    ]);
  }
}
