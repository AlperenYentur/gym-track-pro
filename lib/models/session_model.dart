import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String gymId;
  final String trainerId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // 'personal' veya 'group'
  final List<String> participantIds;
  final String notes;
  final bool isCompleted; // <-- YENİ EKLENEN ALAN

  SessionModel({
    required this.id,
    required this.gymId,
    required this.trainerId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.participantIds,
    this.notes = '',
    this.isCompleted = false, // Varsayılan olarak yapılmadı
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    return SessionModel(
      id: doc.id,
      gymId: data['gymId'] ?? '',
      trainerId: data['trainerId'] ?? '',
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: data['type'] ?? 'personal',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      notes: data['notes'] ?? '',
      isCompleted: data['isCompleted'] ?? false, // <-- Veriden okuma
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'trainerId': trainerId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type,
      'participantIds': participantIds,
      'notes': notes,
      'isCompleted': isCompleted, // <-- Veriye yazma
    };
  }
}
