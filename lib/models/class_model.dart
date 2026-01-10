import 'package:cloud_firestore/cloud_firestore.dart';

class ClassCategory {
  final String id;
  final String name;

  ClassCategory({required this.id, required this.name});

  factory ClassCategory.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ClassCategory(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}

class ClassGroup {
  final String id;
  final String categoryId;
  final String name;
  final List<String> memberIds;

  ClassGroup({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.memberIds,
  });

  factory ClassGroup.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ClassGroup(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
    );
  }
}

class AttendanceRecord {
  final String id;
  final String groupId;
  final DateTime date;
  final Map<String, bool> status;

  AttendanceRecord(
      {required this.id,
      required this.groupId,
      required this.date,
      required this.status});

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: Map<String, bool>.from(data['status'] ?? {}),
    );
  }
}
