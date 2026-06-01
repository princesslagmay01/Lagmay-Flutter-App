Table students {
  student_id int [pk, increment]
  name varchar
  email varchar
  section varchar [note: '3A or 3B']
  created_at datetime
}

Table attendance {
  attendance_id int [pk, increment]
  student_id int [ref: > students.student_id]
  date date
  status varchar [note: 'present | absent | late']
}

Table quizzes {
  quiz_id int [pk, increment]
  student_id int [ref: > students.student_id]
  date date
  type varchar [note: 'short | long']
  total_items int
  score int
}

Table exams {
  exam_id int [pk, increment]
  student_id int [ref: > students.student_id]
  date date
  type varchar [note: 'prelim | midterm | finals']
  total_items int
  score int
}

Table activities {
  activity_id int [pk, increment]
  student_id int [ref: > students.student_id]
  date date
  total_points int
  score int 
}

Table oral_recitations {
  oral_id int [pk, increment]
  student_id int [ref: > students.student_id]
  date date
  points int
}

Table projects {
  project_id int [pk, increment]
  student_id int [ref: > students.student_id]
  date date
  total_points int
  score int
}