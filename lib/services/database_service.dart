import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/member_model.dart';
import '../models/session_model.dart';
import '../models/trainer_model.dart';
import '../models/class_model.dart';
import '../models/measurement_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String gymId;

  DatabaseService({String? gymId})
      : gymId = (gymId != null && gymId.isNotEmpty) ? gymId : 'salon1';

  // --- HATIRLATMA KAYDI (YENİ EKLENDİ) ---
  Future<void> logReminder(String memberId, String type) async {
    await _db.collection('members').doc(memberId).collection('reminders').add({
      'type': type,
      'sentAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('members').doc(memberId).update({
      'lastReminderSent': FieldValue.serverTimestamp(),
    });
  }

  // --- TRAINER İŞLEMLERİ ---
  Stream<List<TrainerModel>> getTrainers() {
    return _db
        .collection('trainers')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((s) => s.docs.map((d) => TrainerModel.fromFirestore(d)).toList());
  }

  Stream<TrainerModel?> getTrainerProfile(String uid) {
    return _db
        .collection('trainers')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? TrainerModel.fromFirestore(doc) : null);
  }

  Future<void> addTrainer(String name, String phone, String specialty) async {
    await _db.collection('trainers').add({
      'gymId': gymId,
      'name': name,
      'phone': phone,
      'specialty': specialty,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTrainer(
      String trainerId, String name, String phone, String specialty) async {
    await _db
        .collection('trainers')
        .doc(trainerId)
        .update({'name': name, 'phone': phone, 'specialty': specialty});
  }

  Future<void> deleteTrainer(String trainerId) async {
    await _db.collection('trainers').doc(trainerId).delete();
  }

  // --- MEMBER İŞLEMLERİ ---
  Stream<List<MemberModel>> getMembers() {
    return _db
        .collection('members')
        .where('gymId', isEqualTo: gymId)
        .orderBy('lastPaymentDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MemberModel.fromFirestore(d)).toList());
  }

  Future<void> deleteMember(String memberId) async {
    await _db.collection('members').doc(memberId).delete();
    await _db.collection('users').doc(memberId).delete();
  }

  Future<void> updateMemberPhone(String myId, String newPhone) async {
    await _db.collection('members').doc(myId).update({'phone': newPhone});
  }

  // --- KASA & FİNANS ---
  Future<void> addTransaction(TransactionModel transaction) async {
    await _db.collection('transactions').add(transaction.toMap());
  }

  Stream<double> getTotalIncome({DateTime? fromDate}) {
    return _db
        .collection('transactions')
        .where('gymId', isEqualTo: gymId)
        .where('type', isEqualTo: 'income')
        .snapshots()
        .map((s) {
      double total = 0;
      for (var doc in s.docs) {
        final data = doc.data();
        // Tarih filtresi (Client-side to avoid index issues)
        if (fromDate != null && data['date'] != null) {
          final date = (data['date'] as Timestamp).toDate();
          if (date.isBefore(fromDate)) continue;
        }
        total += ((data['amount'] as num?)?.toDouble() ?? 0.0);
      }
      return total;
    });
  }

  // --- KASA SIFIRLAMA İŞLEMLERİ ---
  Future<DateTime?> getLastResetDate() async {
    final doc = await _db.collection('gym_settings').doc(gymId).get();
    if (doc.exists && doc.data()!.containsKey('lastKasaResetDate')) {
      return (doc['lastKasaResetDate'] as Timestamp).toDate();
    }
    return null;
  }

  Future<void> resetCashRegister() async {
    await _db.collection('gym_settings').doc(gymId).set({
      'lastKasaResetDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- MÜŞTERİ ÖDEME ---
  Future<void> updateMemberDetails(String memberId, String name, String phone,
      DateTime start, DateTime end, double debt) async {
    bool isPaid = debt <= 0;

    await _db.collection('members').doc(memberId).update({
      'name': name,
      'phone': phone,
      'lastPaymentDate': Timestamp.fromDate(start),
      'nextPaymentDate': Timestamp.fromDate(end),
      'debt': debt,
      'isPaid': isPaid
    });
  }

  Future<void> assignWorkoutProgram(String memberId, String programJson) async {
    await _db
        .collection('members')
        .doc(memberId)
        .update({'workoutProgram': programJson});
  }

  Future<void> confirmPayment(String id, DateTime paymentDate, DateTime endDate,
      double paidAmount, double remainingDebt) async {
    // 1. Üye Durumunu Güncelle (Borç > 0 ise ödenmedi olarak kalsın)
    bool isPaid = remainingDebt <= 0;

    await _db.collection('members').doc(id).update({
      'isPaid': isPaid,
      'lastPaymentDate': Timestamp.fromDate(paymentDate),
      'nextPaymentDate': Timestamp.fromDate(endDate),
      'debt': remainingDebt
    });

    // 2. Kasa Kaydı Oluştur (Gelir)
    if (paidAmount > 0) {
      await addTransaction(TransactionModel(
        id: '', // Firestore oluşturacak
        gymId: gymId,
        type: 'income',
        amount: paidAmount,
        description: 'Üyelik Yenileme',
        date: DateTime.now(),
        relatedMemberId: id,
      ));
    }
  }

  Future<void> cancelPayment(String id) async {
    await _db.collection('members').doc(id).update({'isPaid': false});
  }

  Stream<MemberModel?> getMyProfile(String myId) {
    return _db
        .collection('members')
        .doc(myId)
        .snapshots()
        .map((doc) => doc.exists ? MemberModel.fromFirestore(doc) : null);
  }

  // --- SESSION İŞLEMLERİ ---
  Stream<List<SessionModel>> getTrainerSessions(String trainerId) {
    return _db
        .collection('sessions')
        .where('gymId', isEqualTo: gymId)
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((s) => s.docs.map((d) => SessionModel.fromFirestore(d)).toList());
  }

  Future<void> addSession(
      String title,
      DateTime start,
      DateTime end,
      String type,
      List<String> participants,
      String notes,
      String trainerId) async {
    await _db.collection('sessions').add({
      'gymId': gymId,
      'trainerId': trainerId,
      'title': title,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'type': type,
      'participantIds': participants,
      'notes': notes,
      'isCompleted': false,
    });
  }

  Future<void> deleteSession(String id) async {
    await _db.collection('sessions').doc(id).delete();
  }

  Future<void> toggleSessionStatus(String sessionId, bool currentStatus) async {
    await _db
        .collection('sessions')
        .doc(sessionId)
        .update({'isCompleted': !currentStatus});
  }

  Future<void> updateSession(
      String id,
      String title,
      DateTime start,
      DateTime end,
      String type,
      List<String> participants,
      String notes) async {
    await _db.collection('sessions').doc(id).update({
      'title': title,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'type': type,
      'participantIds': participants,
      'notes': notes,
    });
  }

  Stream<List<SessionModel>> getMySessions(String myId) {
    return _db
        .collection('sessions')
        .where('participantIds', arrayContains: myId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => SessionModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  // --- SINIF & YOKLAMA ---
  Stream<List<ClassCategory>> getCategories() {
    return _db
        .collection('class_categories')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassCategory.fromFirestore(d)).toList());
  }

  Future<void> addCategory(String name) async {
    await _db
        .collection('class_categories')
        .add({'gymId': gymId, 'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('class_categories').doc(id).delete();
  }

  Stream<List<ClassGroup>> getGroups(String categoryId) {
    return _db
        .collection('class_groups')
        .where('gymId', isEqualTo: gymId)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassGroup.fromFirestore(d)).toList());
  }

  Future<void> addGroup(String categoryId, String categoryName, String name,
      List<String> memberIds) async {
    await _db.collection('class_groups').add({
      'gymId': gymId,
      'categoryId': categoryId,
      'category': categoryName,
      'name': name,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('class_groups').doc(groupId).delete();
  }

  Future<void> updateGroup(
      String groupId, String newName, List<String> newMemberIds) async {
    await _db
        .collection('class_groups')
        .doc(groupId)
        .update({'name': newName, 'memberIds': newMemberIds});
  }

  Future<void> saveAttendance(
      String groupId, DateTime date, Map<String, bool> statuses) async {
    await _db.collection('attendance_records').add({
      'gymId': gymId,
      'groupId': groupId,
      'date': Timestamp.fromDate(date),
      'status': statuses
    });
  }

  Future<void> updateCategory(String categoryId, String newName) async {
    await _db
        .collection('class_categories')
        .doc(categoryId)
        .update({'name': newName});
  }

  // --- DUYURU SİSTEMİ ---
  Future<void> addAnnouncement(String text, {String title = "Duyuru"}) async {
    await _db.collection('announcements').add({
      'gymId': gymId,
      'title': title,
      'text': text,
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Stream<QuerySnapshot> getAnnouncements() {
    return _db
        .collection('announcements')
        .where('gymId', isEqualTo: gymId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  // --- DUYURU OTOMATİK TEMİZLEME (24 SAAT) ---
  Future<void> cleanupExpiredAnnouncements() async {
    // 24 saat öncesini hesapla
    final threshold = DateTime.now().subtract(const Duration(hours: 24));

    final snapshot = await _db
        .collection('announcements')
        .where('gymId', isEqualTo: gymId)
        .get();

    for (var doc in snapshot.docs) {
      try {
        final Timestamp? createdAt = doc.data().containsKey('createdAt')
            ? doc['createdAt'] as Timestamp?
            : null;

        if (createdAt != null) {
          final createdDate = createdAt.toDate();
          if (createdDate.isBefore(threshold)) {
            await doc.reference.delete();
          }
        }
      } catch (e) {
        debugPrint("Duyuru silinirken hata: $e");
      }
    }
  }

  // --- MEASUREMENTS ---
  Future<void> addMeasurement(MeasurementModel measurement) async {
    await _db.collection('measurements').add(measurement.toMap());
  }

  Stream<List<MeasurementModel>> getMeasurements(String memberId) {
    return _db
        .collection('measurements')
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => MeasurementModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Future<void> deleteMeasurement(String id) async {
    await _db.collection('measurements').doc(id).delete();
  }
}
