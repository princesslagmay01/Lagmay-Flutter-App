# Firebase Firestore Database Design

> Translated from the relational `database.md` schema into a Firestore NoSQL document model.

---

## Overview

Firestore stores data as **Collections → Documents → Fields (and sub-collections)**.
Since Firestore has no foreign keys, relationships are expressed via **document ID references** stored as strings.

---

## Collection: `students`

**Path:** `/students/{studentId}`

Each document represents one student.

```json
{
  "student_id": "auto-generated (doc ID)",
  "name": "string",
  "email": "string",
  "section": "string",        // e.g. '3A' or '3B'
  "created_at": "timestamp"
}
```

---

## Collection: `attendance`

**Path:** `/attendance/{attendanceId}`

```json
{
  "attendance_id": "auto-generated (doc ID)",
  "student_id": "string (ref → /students/{studentId})",
  "date": "timestamp",
  "status": "string"          // 'present' | 'absent' | 'late'
}
```

> **Optional sub-collection approach:**
> Store attendance under each student:
> `/students/{studentId}/attendance/{attendanceId}`

---

## Collection: `quizzes`

**Path:** `/quizzes/{quizId}`

```json
{
  "quiz_id": "auto-generated (doc ID)",
  "student_id": "string (ref → /students/{studentId})",
  "date": "timestamp",
  "type": "string",           // 'short' | 'long'
  "total_items": "number",
  "score": "number"
}
```

> **Optional sub-collection approach:**
> `/students/{studentId}/quizzes/{quizId}`

---

## Collection: `exams`

**Path:** `/exams/{examId}`

```json
{
  "exam_id": "auto-generated (doc ID)",
  "student_id": "string (ref → /students/{studentId})",
  "date": "timestamp",
  "type": "string",           // 'prelim' | 'midterm' | 'finals'
  "total_items": "number",
  "score": "number"
}
```

> **Optional sub-collection approach:**
> `/students/{studentId}/exams/{examId}`

---

## Collection: `activities`

**Path:** `/activities/{activityId}`

```json
{
  "activity_id": "auto-generated (doc ID)",
  "student_id": "string (ref → /students/{studentId})",
  "date": "timestamp",
  "total_points": "number",
  "score": "number"
}
```

> **Optional sub-collection approach:**
> `/students/{studentId}/activities/{activityId}`

---

## Collection: `oral_recitations`

**Path:** `/oral_recitations/{oralId}`

```json
{
  "oral_id": "auto-generated (doc ID)",
  "student_id": "string (ref → /students/{studentId})",
  "date": "timestamp",
  "points": "number"
}
```

> **Optional sub-collection approach:**
> `/students/{studentId}/oral_recitations/{oralId}`

---

## Collection: `projects`

**Path:** `/projects/{projectId}`

```json
{
  "project_id": "auto-generated (doc ID)",
  "student_id": "string (ref → /students/{studentId})",
  "date": "timestamp",
  "total_points": "number",
  "score": "number"
}
```

> **Optional sub-collection approach:**
> `/students/{studentId}/projects/{projectId}`

---

## Firestore Structure Summary

```
Firestore Root
│
├── students/
│   └── {studentId}
│       ├── name
│       ├── email
│       ├── section
│       └── created_at
│
├── attendance/
│   └── {attendanceId}
│       ├── student_id  ──────► students/{studentId}
│       ├── date
│       └── status
│
├── quizzes/
│   └── {quizId}
│       ├── student_id  ──────► students/{studentId}
│       ├── date
│       ├── type
│       ├── total_items
│       └── score
│
├── exams/
│   └── {examId}
│       ├── student_id  ──────► students/{studentId}
│       ├── date
│       ├── type
│       ├── total_items
│       └── score
│
├── activities/
│   └── {activityId}
│       ├── student_id  ──────► students/{studentId}
│       ├── date
│       ├── total_points
│       └── score
│
├── oral_recitations/
│   └── {oralId}
│       ├── student_id  ──────► students/{studentId}
│       ├── date
│       └── points
│
└── projects/
    └── {projectId}
        ├── student_id  ──────► students/{studentId}
        ├── date
        ├── total_points
        └── score
```

---

## Firestore Security Rules (basic)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Students - authenticated users can read/write
    match /students/{studentId} {
      allow read, write: if request.auth != null;
    }

    // All grade/record collections - authenticated users only
    match /attendance/{id} {
      allow read, write: if request.auth != null;
    }
    match /quizzes/{id} {
      allow read, write: if request.auth != null;
    }
    match /exams/{id} {
      allow read, write: if request.auth != null;
    }
    match /activities/{id} {
      allow read, write: if request.auth != null;
    }
    match /oral_recitations/{id} {
      allow read, write: if request.auth != null;
    }
    match /projects/{id} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Notes

| Relational Concept | Firestore Equivalent |
|---|---|
| `INT [pk, increment]` | Auto-generated Document ID (string) |
| `FOREIGN KEY (student_id)` | String field holding the referenced doc ID |
| `JOIN` | Multiple reads or sub-collections |
| `DATE / DATETIME` | Firestore `Timestamp` type |
| `VARCHAR` | Firestore `string` type |
| `INT` | Firestore `number` type |
