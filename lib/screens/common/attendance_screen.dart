import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../services/message_service.dart'; // IMPORTU UNUTMAYIN
import '../../providers/auth_provider.dart';
import '../../models/member_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Set<String> _presentMemberIds = {};
  String? _selectedCategory;
  String? _selectedGroupId;
  List<dynamic> _currentGroupMemberIds = [];
  bool _isLoadingData = false;
  String? _existingDocId;

  Future<void> _checkExistingAttendance(String groupId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _presentMemberIds.clear();
      _existingDocId = null;
    });
    try {
      final query = await FirebaseFirestore.instance
          .collection('attendance_records')
          .where('groupId', isEqualTo: groupId)
          .get();
      final now = DateTime.now();
      QueryDocumentSnapshot? todayDoc;
      for (var doc in query.docs) {
        final Timestamp? ts = doc['date'];
        if (ts != null) {
          final date = ts.toDate();
          if (date.year == now.year &&
              date.month == now.month &&
              date.day == now.day) {
            todayDoc = doc;
            break;
          }
        }
      }
      if (todayDoc != null) {
        _existingDocId = todayDoc.id;
        final data = todayDoc.data() as Map<String, dynamic>;
        if (data['status'] != null) {
          Map<String, dynamic> statusMap = data['status'];
          statusMap.forEach((memberId, isPresent) {
            if (isPresent == true) _presentMemberIds.add(memberId);
          });
        }
      }
    } catch (e) {
      debugPrint("Hata: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveAttendance(
      List<MemberModel> displayedMembers, DatabaseService db) async {
    if (_selectedGroupId == null) return;
    Map<String, bool> statusMap = {};
    for (var member in displayedMembers) {
      statusMap[member.id] = _presentMemberIds.contains(member.id);
    }
    try {
      if (_existingDocId != null) {
        await FirebaseFirestore.instance
            .collection('attendance_records')
            .doc(_existingDocId)
            .update({
          'status': statusMap,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await db.saveAttendance(_selectedGroupId!, DateTime.now(), statusMap);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Yoklama kaydedildi! ✅"),
            backgroundColor: Colors.green));
        _checkExistingAttendance(_selectedGroupId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final db = DatabaseService(gymId: auth.gymId);
    final dateStr = DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("Yoklama Al",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Row(children: [
                  const Icon(LineIcons.calendar, size: 20),
                  const SizedBox(width: 8),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 15),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('class_categories')
                      .where('gymId', isEqualTo: auth.gymId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    var items = snapshot.data!.docs
                        .map((doc) => DropdownMenuItem(
                            value: doc['name'] as String,
                            child: Text(doc['name'])))
                        .toList();
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                          labelText: "Branş Seçiniz",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white),
                      key: ValueKey(_selectedCategory),
                      initialValue: _selectedCategory,
                      items: items,
                      onChanged: (val) => setState(() {
                        _selectedCategory = val;
                        _selectedGroupId = null;
                        _presentMemberIds.clear();
                      }),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (_selectedCategory != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('class_groups')
                        .where('gymId', isEqualTo: auth.gymId)
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      var items = snapshot.data!.docs
                          .map((doc) => DropdownMenuItem(
                              value: doc.id,
                              child: Text(doc['name'] ?? 'İsimsiz')))
                          .toList();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                            labelText: "Grup Seçiniz",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white),
                        key: ValueKey(_selectedGroupId),
                        initialValue: _selectedGroupId,
                        items: items,
                        onChanged: (val) {
                          var doc = snapshot.data!.docs
                              .firstWhere((d) => d.id == val);
                          setState(() {
                            _selectedGroupId = val;
                            _currentGroupMemberIds = doc['memberIds'] ?? [];
                          });
                          _checkExistingAttendance(val!);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _selectedGroupId == null
                ? const Center(
                    child: Text("Lütfen grup seçiniz.",
                        style: TextStyle(color: Colors.grey)))
                : _isLoadingData
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<MemberModel>>(
                        stream: db.getMembers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          var groupMembers = snapshot.data!
                              .where(
                                  (m) => _currentGroupMemberIds.contains(m.id))
                              .toList();

                          return Column(
                            children: [
                              Container(
                                  color: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: const Row(children: [
                                    SizedBox(
                                        width: 30,
                                        child: Text("No",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold))),
                                    Expanded(
                                        child: Text("Öğrenci Adı",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold))),
                                    SizedBox(
                                        width: 140,
                                        child: Center(
                                            child: Text("Yoklama / Mesaj",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)))),
                                  ])),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: groupMembers.length,
                                  separatorBuilder: (c, i) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final member = groupMembers[index];
                                    final isPresent =
                                        _presentMemberIds.contains(member.id);
                                    return Container(
                                      color: index % 2 == 0
                                          ? Colors.white
                                          : Colors.grey.shade50,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 16),
                                      child: Row(children: [
                                        SizedBox(
                                            width: 30,
                                            child: Text("${index + 1}",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            child: Text(member.name,
                                                style: const TextStyle(
                                                    fontSize: 15))),
                                        Row(children: [
                                          GestureDetector(
                                              onTap: () => setState(() =>
                                                  _presentMemberIds
                                                      .add(member.id)),
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                      color: isPresent
                                                          ? Colors.green
                                                          : Colors
                                                              .grey.shade200,
                                                      borderRadius: const BorderRadius.horizontal(
                                                          left: Radius.circular(
                                                              8))),
                                                  child: Icon(Icons.check,
                                                      size: 18,
                                                      color: isPresent
                                                          ? Colors.white
                                                          : Colors.grey))),
                                          GestureDetector(
                                              onTap: () => setState(() =>
                                                  _presentMemberIds
                                                      .remove(member.id)),
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                      color: !isPresent
                                                          ? Colors.red
                                                          : Colors
                                                              .grey.shade200,
                                                      borderRadius: const BorderRadius.horizontal(
                                                          right: Radius.circular(
                                                              8))),
                                                  child: Icon(Icons.close,
                                                      size: 18,
                                                      color: !isPresent
                                                          ? Colors.white
                                                          : Colors.grey))),
                                          const SizedBox(width: 10),
                                          // --- WHATSAPP BUTONU ---
                                          IconButton(
                                              icon: Icon(Icons.message,
                                                  color: !isPresent
                                                      ? Colors.green
                                                      : Colors.grey.shade300,
                                                  size: 24),
                                              onPressed: isPresent
                                                  ? null
                                                  : () {
                                                      String msg =
                                                          "Selam ${member.name}, bugün antrenmanda seni göremedik. 💪";
                                                      MessageService
                                                          .sendWhatsApp(
                                                              phone:
                                                                  member.phone,
                                                              message: msg);
                                                      db.logReminder(member.id,
                                                          'attendance');
                                                    })
                                        ])
                                      ]),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          onPressed: () =>
                                              _saveAttendance(groupMembers, db),
                                          child: Text(
                                              _existingDocId != null
                                                  ? "GÜNCELLE (${_presentMemberIds.length} Katılım)"
                                                  : "YOKLAMAYI KAYDET (${_presentMemberIds.length} Katılım)",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold))))),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
