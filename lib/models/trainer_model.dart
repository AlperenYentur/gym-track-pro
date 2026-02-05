import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerModel {
  final String id;
  final String gymId;
  final String email;
  final String name;
  final String phone; // Yeni
  final String specialty; // Yeni (Uzmanlık alanı)

  TrainerModel({
    required this.id,
    required this.gymId,
    required this.email,
    required this.name,
    required this.phone,
    required this.specialty,
  });

  factory TrainerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TrainerModel(
      id: doc.id,
      gymId: data['gymId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      specialty: data['specialty'] ?? '',
    );
  }
}
