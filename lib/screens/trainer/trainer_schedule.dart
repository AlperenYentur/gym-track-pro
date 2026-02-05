import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/database_service.dart';
import '../../models/session_model.dart';
import '../../models/member_model.dart';
import '../../providers/auth_provider.dart';

class TrainerScheduleScreen extends StatefulWidget {
  const TrainerScheduleScreen({super.key});

  @override
  State<TrainerScheduleScreen> createState() => _TrainerScheduleScreenState();
}

class _TrainerScheduleScreenState extends State<TrainerScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<SessionModel> _getEventsForDay(
      DateTime day, List<SessionModel> allSessions) {
    return allSessions
        .where((session) => isSameDay(session.startTime, day))
        .toList();
  }

  String _getParticipantNames(List<String> ids, List<MemberModel> allMembers) {
    if (ids.isEmpty) return "Katılımcı Yok";
    List<String> names = [];
    for (var id in ids) {
      try {
        final member = allMembers.firstWhere((m) => m.id == id);
        names.add(member.name);
      } catch (e) {
        names.add("Bilinmeyen");
      }
    }
    return names.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dbService = DatabaseService(gymId: authProvider.gymId);
    final myUid = authProvider.currentUser!.uid;

    return StreamBuilder<List<MemberModel>>(
      stream: dbService.getMembers(),
      builder: (context, memberSnapshot) {
        if (!memberSnapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final allMembers = memberSnapshot.data!;

        return StreamBuilder<List<SessionModel>>(
          stream: dbService.getTrainerSessions(myUid),
          builder: (context, sessionSnapshot) {
            if (!sessionSnapshot.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final allSessions = sessionSnapshot.data!;

            final selectedDaySessions =
                _getEventsForDay(_selectedDay!, allSessions);

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: const Text("Ders Programı",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black),
              ),
              body: Column(
                children: [
                  TableCalendar<SessionModel>(
                    locale: 'tr_TR',
                    firstDay: DateTime.utc(2020, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => _getEventsForDay(day, allSessions),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) =>
                        setState(() => _calendarFormat = format),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: Colors.grey, shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: selectedDaySessions.isEmpty
                        ? Center(
                            child: Text(
                              "${DateFormat('d MMMM', 'tr_TR').format(_selectedDay!)}\nPlanlanmış ders yok.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: selectedDaySessions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final session = selectedDaySessions[index];
                              final participantNames = _getParticipantNames(
                                  session.participantIds, allMembers);

                              return _buildSessionCard(
                                  session,
                                  participantNames,
                                  dbService,
                                  allMembers,
                                  allSessions,
                                  myUid);
                            },
                          ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showSessionDialog(
                    context, dbService, allMembers, allSessions, null, myUid),
                backgroundColor: Colors.black,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Ders Planla",
                    style: TextStyle(color: Colors.white)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSessionCard(
      SessionModel session,
      String names,
      DatabaseService db,
      List<MemberModel> allMembers,
      List<SessionModel> allSessions,
      String myUid) {
    bool isGroup = session.type == 'group';
    bool hasNotes = session.notes.isNotEmpty;
    bool isCompleted = session.isCompleted; // Modelden durumu al

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Eğer tamamlandıysa yeşilimsi, değilse normal renk
        color: isCompleted
            ? Colors.green.shade50
            : (isGroup ? Colors.purple.shade50 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            // Kenarlık rengi de duruma göre değişsin
            color: isCompleted
                ? Colors.green
                : (isGroup ? Colors.purple.shade100 : Colors.blue.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // SAAT KISMI
              Column(
                children: [
                  Text(DateFormat('HH:mm').format(session.startTime),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(DateFormat('HH:mm').format(session.endTime),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 15),

              // DİKEY ÇİZGİ
              Container(
                  height: 40,
                  width: 4,
                  color: isCompleted
                      ? Colors.green
                      : (isGroup ? Colors.purple : Colors.blue),
                  margin: const EdgeInsets.only(right: 15)),

              // DETAYLAR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title + (isCompleted ? " (Yapıldı) ✅" : ""),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          // Tamamlandıysa üzerini çiz
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted ? Colors.grey : Colors.black),
                    ),
                    Text(
                      isGroup ? "Grup: $names" : "Üye: $names",
                      style:
                          TextStyle(color: Colors.grey.shade800, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // --- İŞLEM BUTONLARI ---

              // 1. TAMAMLANDI BUTONU (Toggle)
              IconButton(
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                tooltip:
                    isCompleted ? "Yapılmadı Olarak İşaretle" : "Dersi Tamamla",
                onPressed: () {
                  // Durumu tersine çevir
                  db.toggleSessionStatus(session.id, isCompleted);
                },
              ),

              // 2. DÜZENLEME (Sadece tamamlanmadıysa aktif olsun opsiyonel)
              if (!isCompleted)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showSessionDialog(
                      context, db, allMembers, allSessions, session, myUid),
                ),

              // 3. SİLME
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, db, session.id),
              )
            ],
          ),

          // NOTLAR KISMI
          if (hasNotes)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 60),
              child: Row(
                children: [
                  const Icon(LineIcons.stickyNote,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      session.notes,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService db, String id) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Dersi Sil"),
              content: const Text("Bu dersi silmek istediğinize emin misiniz?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("İptal")),
                TextButton(
                    onPressed: () {
                      db.deleteSession(id);
                      Navigator.pop(ctx);
                    },
                    child:
                        const Text("Sil", style: TextStyle(color: Colors.red))),
              ],
            ));
  }

  void _showSessionDialog(
      BuildContext context,
      DatabaseService db,
      List<MemberModel> allMembers,
      List<SessionModel> allSessions,
      SessionModel? existingSession,
      String myUid) {
    final bool isEdit = existingSession != null;

    final titleCtrl =
        TextEditingController(text: isEdit ? existingSession.title : "");
    final notesCtrl =
        TextEditingController(text: isEdit ? existingSession.notes : "");

    TimeOfDay startTime = isEdit
        ? TimeOfDay.fromDateTime(existingSession.startTime)
        : TimeOfDay.now();

    TimeOfDay endTime = isEdit
        ? TimeOfDay.fromDateTime(existingSession.endTime)
        : TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

    String sessionType = isEdit ? existingSession.type : 'pt';
    List<String> selectedMemberIds =
        isEdit ? List.from(existingSession.participantIds) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? "Dersi Düzenle" : "Yeni Ders Planla",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: "Ders Başlığı (Örn: Pilates)",
                    prefixIcon: const Icon(LineIcons.edit),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    hintText: "Notlar (Opsiyonel)",
                    prefixIcon: const Icon(LineIcons.stickyNote),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                        child: _timePickerButton(
                            context,
                            "Başlangıç",
                            startTime,
                            (t) => setModalState(() => startTime = t))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _timePickerButton(context, "Bitiş", endTime,
                            (t) => setModalState(() => endTime = t))),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                        child: _typeRadio("Birebir (PT)", 'pt', sessionType,
                            (val) => setModalState(() => sessionType = val!))),
                    Expanded(
                        child: _typeRadio("Grup Dersi", 'group', sessionType,
                            (val) => setModalState(() => sessionType = val!))),
                  ],
                ),
                const Divider(height: 20),
                const Text("Öğrenci Seç:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: allMembers.length,
                    itemBuilder: (context, index) {
                      final member = allMembers[index];
                      final isDateExpired =
                          member.nextPaymentDate.isBefore(DateTime.now());
                      final bool isRisky = !member.isPaid || isDateExpired;
                      final daysLeft = member.nextPaymentDate
                          .difference(DateTime.now())
                          .inDays;

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Text(member.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (isRisky)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.error,
                                    color: Colors.red, size: 20),
                              ),
                          ],
                        ),
                        subtitle: isRisky
                            ? const Text("Ödeme Sorunu / Borçlu",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))
                            : Text(
                                daysLeft < 0
                                    ? "Süre doldu"
                                    : "$daysLeft gün kaldı",
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 12)),
                        value: selectedMemberIds.contains(member.id),
                        activeColor: Colors.black,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              if (sessionType == 'pt' &&
                                  selectedMemberIds.isNotEmpty) {
                                selectedMemberIds.clear();
                              }
                              selectedMemberIds.add(member.id);
                            } else {
                              selectedMemberIds.remove(member.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () async {
                      // 1. BAŞLIK KONTROLÜ
                      if (titleCtrl.text.isEmpty) {
                        _showErrorDialog(
                            context, "Uyarı", "Lütfen ders başlığı giriniz.");
                        return;
                      }

                      // 2. ÖĞRENCİ KONTROLÜ
                      if (selectedMemberIds.isEmpty) {
                        _showErrorDialog(context, "Uyarı",
                            "Lütfen en az bir öğrenci seçiniz.");
                        return;
                      }

                      final baseDate = _selectedDay!;
                      final startDateTime = DateTime(
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                          startTime.hour,
                          startTime.minute);
                      final endDateTime = DateTime(
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                          endTime.hour,
                          endTime.minute);

                      if (!endDateTime.isAfter(startDateTime)) {
                        _showErrorDialog(context, "Saat Hatası",
                            "Bitiş saati, başlangıç saatinden sonra olmalıdır.");
                        return;
                      }

                      // Basit çakışma kontrolü
                      bool isTrainerBusy = allSessions.any((s) {
                        if (isEdit && s.id == existingSession.id) return false;
                        return startDateTime.isBefore(s.endTime) &&
                            endDateTime.isAfter(s.startTime);
                      });

                      if (isTrainerBusy) {
                        _showErrorDialog(context, "Zaman Çakışması!",
                            "Bu saat aralığında zaten başka bir dersiniz var.");
                        return;
                      }

                      if (isEdit) {
                        await db.updateSession(
                            existingSession.id,
                            titleCtrl.text,
                            startDateTime,
                            endDateTime,
                            sessionType,
                            selectedMemberIds,
                            notesCtrl.text);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Ders güncellendi!"),
                                backgroundColor: Colors.blue));
                      } else {
                        await db.addSession(
                            titleCtrl.text,
                            startDateTime,
                            endDateTime,
                            sessionType,
                            selectedMemberIds,
                            notesCtrl.text,
                            myUid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Ders planlandı!"),
                                backgroundColor: Colors.green));
                      }

                      Navigator.pop(ctx);
                    },
                    child: Text(isEdit ? "GÜNCELLE" : "PLANLA",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Row(children: [
                const Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 10),
                Text(title)
              ]),
              content: Text(content),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Tamam"))
              ],
            ));
  }

  Widget _timePickerButton(BuildContext context, String label, TimeOfDay time,
      Function(TimeOfDay) onSelected) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onSelected(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text("${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _typeRadio(String label, String val, String currentVal,
      Function(String?) onChanged) {
    return Row(
      children: [
        Radio<String>(
            value: val,
            groupValue: currentVal,
            activeColor: Colors.black,
            onChanged: onChanged),
        Text(label),
      ],
    );
  }
}
