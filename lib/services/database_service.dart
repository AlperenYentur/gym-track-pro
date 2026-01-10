import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../models/session_model.dart';
import '../models/trainer_model.dart';
import '../models/class_model.dart';
import '../models/measurement_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? gymId;

  DatabaseService({this.gymId});

  // --- HATIRLATMA KAYDI (YENİ EKLENDİ) ---
  Future<void> logReminder(String memberId, String type) async {
    if (gymId == null) return;
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
    if (gymId == null) return const Stream.empty();
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
    if (gymId == null) return;
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
    if (gymId == null) return const Stream.empty();
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

  Future<void> updateMemberDetails(String memberId, String name, String phone,
      DateTime start, DateTime end) async {
    await _db.collection('members').doc(memberId).update({
      'name': name,
      'phone': phone,
      'lastPaymentDate': Timestamp.fromDate(start),
      'nextPaymentDate': Timestamp.fromDate(end),
    });
  }

  Future<void> assignWorkoutProgram(String memberId, String programJson) async {
    await _db
        .collection('members')
        .doc(memberId)
        .update({'workoutProgram': programJson});
  }

  Future<void> confirmPayment(
      String id, DateTime paymentDate, DateTime endDate) async {
    await _db.collection('members').doc(id).update({
      'isPaid': true,
      'lastPaymentDate': Timestamp.fromDate(paymentDate),
      'nextPaymentDate': Timestamp.fromDate(endDate),
    });
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
    if (gymId == null) return const Stream.empty();
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
    if (gymId == null) return;
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
        .orderBy('startTime')
        .snapshots()
        .map((s) => s.docs.map((d) => SessionModel.fromFirestore(d)).toList());
  }

  // --- SINIF & YOKLAMA ---
  Stream<List<ClassCategory>> getCategories() {
    if (gymId == null) return const Stream.empty();
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
    if (gymId == null) return const Stream.empty();
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
    if (gymId == null) return;
    await _db.collection('announcements').add({
      'gymId': gymId,
      'title': title,
      'text': text,
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Stream<QuerySnapshot> getAnnouncements() {
    if (gymId == null) return const Stream.empty();
    return _db
        .collection('announcements')
        .where('gymId', isEqualTo: gymId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
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
