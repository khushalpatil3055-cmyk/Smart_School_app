# School Management System

A production-grade mobile app that digitized school operations for 500+ students across 3 user roles (admin, teacher, parent).

## 🎯 Problem Solved
- Manual attendance tracking (error-prone, time-consuming)
- Fee management chaos (lost records, disputes)
- Poor parent-teacher communication (delayed updates)
- Result distribution delays (manual entry)

**Solution:** A single platform that eliminated 70% of manual workload through automation.

## 📱 Tech Stack
- **Frontend:** Flutter, Dart
- **Backend:** Firebase Firestore
- **State Management:** Riverpod
- **Authentication:** Firebase Auth
- **Notifications:** Firebase Cloud Messaging
- **Platforms:** iOS, Android (native performance)

## 📊 Key Metrics
- **Users:** 500+ (students, teachers, parents)
- **User Roles:** 3 (Admin, Teacher, Parent)
- **Features:** Attendance, Fees, Results, Notifications
- **Workload Reduction:** ~70% through automation
- **Uptime:** Offline-first architecture ensures 99%+ availability

## ✨ Key Features

### 1. Role-Based Access Control
- **Admin:** School setup, user management, report generation
- **Teacher:** Mark attendance, input marks, view student data
- **Parent:** View child's attendance, fees, results in real-time

### 2. Real-Time Notifications
- Automated notifications to parents about attendance, fees, results
- Significantly reduced parent-teacher communication delays
- Push notifications sent via Firebase Cloud Messaging

### 3. Offline-First Sync
- App works without internet connection
- Automatic sync when connection is restored
- Teachers can mark attendance offline, syncs when online

### 4. Attendance Management
- Daily attendance marking by teachers
- Real-time parent notifications
- Monthly reports for admin
- Exportable attendance records

### 5. Fee Management
- Fee structure setup by admin
- Track paid/unpaid fees for each student
- Automated reminders to parents
- Payment status dashboard

### 6. Result Management
- Teachers input marks/grades
- Automatic result generation
- Real-time notifications to parents
- Performance analytics for admin

## 🏗️ System Architecture
