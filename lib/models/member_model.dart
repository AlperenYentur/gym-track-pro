import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String gymId;
  final String name;
  final String phone;
  final DateTime lastPaymentDate; // Firebase ismine göre güncellendi
  final DateTime nextPaymentDate;
  final bool isPaid;
  final String? workoutProgram;

  MemberModel({
    required this.id,
    required this.gymId,
    required this.name,
    required this.phone,
    required this.lastPaymentDate,
    required this.nextPaymentDate,
    required this.isPaid,
    this.workoutProgram,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      id: doc.id,
      gymId: data['gymId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      // Timestamp dönüşümü yapılıyor
      lastPaymentDate: (data['lastPaymentDate'] as Timestamp).toDate(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp).toDate(),
      isPaid: data['isPaid'] ?? false,
      workoutProgram: data['workoutProgram'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'name': name,
      'phone': phone,
      'lastPaymentDate': lastPaymentDate,
      'nextPaymentDate': nextPaymentDate,
      'isPaid': isPaid,
      'workoutProgram': workoutProgram,
    };
  }
}
