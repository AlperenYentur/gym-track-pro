import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String gymId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String description;
  final DateTime date;
  final String? relatedMemberId;

  TransactionModel({
    required this.id,
    required this.gymId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.relatedMemberId,
  });

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'relatedMemberId': relatedMemberId,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      gymId: data['gymId'] ?? '',
      type: data['type'] ?? 'income',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      relatedMemberId: data['relatedMemberId'],
    );
  }
}
