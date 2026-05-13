import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modeller ve Servisler
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/trainer_model.dart';
import '../../models/session_model.dart';
import '../../models/member_model.dart';

// Sayfalar
import 'trainer_member_list.dart';
import 'trainer_schedule.dart';
import 'workout_editor.dart';
import 'trainer_profile_screen.dart';
import '../common/class_manager.dart';
import '../common/attendance_screen.dart';

class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  int _currentIndex = 0;

  // Sayfa değiştirme fonksiyonu (Dashboard'dan tetiklenecek)
  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sayfaları burada tanımlıyoruz ki _switchTab fonksiyonuna erişebilsinler
    final List<Widget> pages = [
      _TrainerDashboardTab(
          onSwitchTab: _switchTab), // 0: Anasayfa (Callback eklendi)
      const TrainerScheduleScreen(), // 1: Program
      const TrainerMemberListScreen(), // 2: Üyeler
      const _TrainerAttendanceTab(), // 3: Yoklama
      const TrainerProfileScreen(), // 4: Profil
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(LineIcons.home), label: "Anasayfa"),
          BottomNavigationBarItem(
              icon: Icon(LineIcons.calendar), label: "Program"),
          BottomNavigationBarItem(icon: Icon(LineIcons.users), label: "Üyeler"),
          BottomNavigationBarItem(
              icon: Icon(LineIcons.clipboardList), label: "Yoklama"),
          BottomNavigationBarItem(icon: Icon(LineIcons.user), label: "Profil"),
        ],
      ),
    );
  }
}

// --- 1. DASHBOARD (ANASAYFA) SEKME ---
class _TrainerDashboardTab extends StatelessWidget {
  final Function(int) onSwitchTab; // Tab değiştirmek için callback

  const _TrainerDashboardTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final db = DatabaseService(gymId: auth.gymId);
    final myUid = auth.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Eğitmen Paneli",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İsim Kartı
            StreamBuilder<TrainerModel?>(
              stream: db.getTrainerProfile(myUid),
              builder: (context, snapshot) {
                String name = snapshot.data?.name ?? "Eğitmen";
                return Text("Merhaba, $name 👋",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold));
              },
            ),
            const SizedBox(height: 20),

            // --- YENİ EKLENEN: HIZLI İŞLEMLER ---
            const Text("Hızlı İşlemler ⚡",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _QuickActions(onSwitchTab: onSwitchTab),

            const SizedBox(height: 25),

            // --- DUYURU YÖNETİMİ ---
            const Text("📢 Duyuru Yönetimi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _AnnouncementBoard(db: db),

            const SizedBox(height: 25),

            // --- SIRADAKİ DERS ---
            const Text("Sıradaki Dersin",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<SessionModel>>(
              stream: db.getTrainerSessions(myUid),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _infoBox("Planlanmış bir ders bulunmuyor.");
                }

                final now = DateTime.now();
                final upcoming = snapshot.data!
                    .where((s) => s.startTime.isAfter(now) && !s.isCompleted)
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

                if (upcoming.isEmpty) {
                  return _infoBox("Bugün için başka ders görünmüyor. 🎉");
                }

                final nextSession = upcoming.first;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1e3c72), Color(0xFF2a5298)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(nextSession.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const Icon(Icons.notifications_active,
                              color: Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${DateFormat('HH:mm').format(nextSession.startTime)} - ${DateFormat('HH:mm').format(nextSession.endTime)}",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nextSession.type == 'group'
                            ? "Grup Dersi"
                            : "Birebir Ders",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // --- PROGRAMI EKSİK OLANLAR ---
            const Text("⚠️ Program Bekleyenler",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberModel>>(
              stream: db.getMembers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final missingProgram = snapshot.data!
                    .where((m) =>
                        m.workoutProgram == null ||
                        m.workoutProgram!.isEmpty ||
                        m.workoutProgram == "[]")
                    .toList();

                if (missingProgram.isEmpty) {
                  return _infoBox("Harika! Tüm üyelerin programı var. ✅");
                }

                return SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: missingProgram.length,
                    itemBuilder: (context, index) {
                      final member = missingProgram[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    WorkoutEditorScreen(member: member)),
                          );
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.orange.shade100,
                                child: Text(member.name[0].toUpperCase(),
                                    style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Text(member.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text("Program Yaz",
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // --- İSTATİSTİKLER ---
            const Text("Haftalık İstatistikler",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            StreamBuilder<List<SessionModel>>(
              stream: db.getTrainerSessions(myUid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data!;
                final now = DateTime.now();

                final startOfWeek =
                    now.subtract(Duration(days: now.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 6));

                final thisWeekSessions = sessions.where((s) {
                  return s.startTime.isAfter(
                          startOfWeek.subtract(const Duration(days: 1))) &&
                      s.startTime
                          .isBefore(endOfWeek.add(const Duration(days: 1)));
                }).toList();

                final completedSessions =
                    thisWeekSessions.where((s) => s.isCompleted).length;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Bu Haftaki Dersler",
                        count: "${thisWeekSessions.length}",
                        color: Colors.blue,
                        icon: LineIcons.calendarCheck,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: "Tamamlanan Dersler",
                        count: "$completedSessions",
                        color: Colors.green,
                        icon: LineIcons.checkCircle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200)),
      child:
          Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
    );
  }
}

// --- 4. YOKLAMA MERKEZİ SEKME ---
class _TrainerAttendanceTab extends StatelessWidget {
  const _TrainerAttendanceTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Yoklama Merkezi",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolTile(
            icon: LineIcons.clipboardList,
            color: Colors.redAccent,
            title: "Yoklama Al",
            subtitle: "Ders yoklamalarını sisteme gir",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen())),
          ),
          const SizedBox(height: 15),
          _ToolTile(
            icon: LineIcons.sitemap,
            color: Colors.teal,
            title: "Sınıf & Grup Yönetimi",
            subtitle: "Yeni gruplar oluştur ve düzenle",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ClassManagerScreen())),
          ),
        ],
      ),
    );
  }
}

// --- YARDIMCI WIDGETLAR ---

// HIZLI İŞLEMLER WIDGET'I
class _QuickActions extends StatelessWidget {
  final Function(int) onSwitchTab;
  const _QuickActions({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionBtn(context, "Ders Planla", LineIcons.calendarPlus,
              Colors.blue, () => onSwitchTab(1)), // Tab 1: Program

          // DÜZELTME BURADA: LineIcons.addUser -> LineIcons.userPlus
          _actionBtn(context, "Üye Ekle", LineIcons.userPlus, Colors.orange,
              () => onSwitchTab(2)), // Tab 2: Üyeler

          _actionBtn(
              context,
              "Yoklama Al",
              LineIcons.checkSquare,
              Colors.redAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()))),

          _actionBtn(
              context,
              "Sınıflar",
              LineIcons.users,
              Colors.teal,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClassManagerScreen()))),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.title,
      required this.count,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(count,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}

class _AnnouncementBoard extends StatefulWidget {
  final DatabaseService db;
  const _AnnouncementBoard({required this.db});

  @override
  State<_AnnouncementBoard> createState() => _AnnouncementBoardState();
}

class _AnnouncementBoardState extends State<_AnnouncementBoard> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isWriting = false;

  void _postAnnouncement() async {
    if (_textController.text.isEmpty) return;
    String title =
        _titleController.text.isEmpty ? "Duyuru" : _titleController.text.trim();

    await widget.db.addAnnouncement(_textController.text.trim(), title: title);

    _textController.clear();
    _titleController.clear();
    setState(() => _isWriting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Duyuru yayınlandı!"), backgroundColor: Colors.green));
      FocusScope.of(context).unfocus();
    }
  }

  void _deleteAnnouncement(String id) {
    widget.db.deleteAnnouncement(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Duyuru silindi."), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isWriting)
            Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Başlık",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Duyuru metni...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => setState(() => _isWriting = false),
                        child: const Text("İptal")),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white),
                        onPressed: _postAnnouncement,
                        child: const Text("Yayınla")),
                  ],
                ),
                const Divider(),
              ],
            ),
          if (!_isWriting)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Son Duyurular",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _isWriting = true),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Ekle"),
                )
              ],
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.db.getAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Henüz duyuru yok.",
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String title = data['title'] ?? 'Duyuru';
                    String text = data['text'] ?? '';
                    Timestamp? ts = data['createdAt'];
                    String dateStr = ts != null
                        ? DateFormat('dd MMM', 'tr_TR').format(ts.toDate())
                        : "";

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(LineIcons.bullhorn,
                            size: 18, color: Colors.orange),
                      ),
                      title: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(text,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dateStr,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => _deleteAnnouncement(doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
