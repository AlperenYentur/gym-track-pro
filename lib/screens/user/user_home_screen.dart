import 'package:flutter/material.dart';
import 'dart:ui'; // Mouse desteği için gerekli
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/member_model.dart';
import '../../models/session_model.dart';
import '../../models/trainer_model.dart';

import 'workout_view_screen.dart';
import 'profile_screen.dart';
import '../common/measurement_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final db = DatabaseService(gymId: auth.gymId);
    final myUid = auth.currentUser?.uid ?? '';

    if (myUid.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<MemberModel?>(
      stream: db.getMyProfile(myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("Kayıt bulunamadı.")));
        }

        final member = snapshot.data!;

        final List<Widget> pages = [
          _UserDashboardTab(member: member, db: db), // 0: Anasayfa
          WorkoutViewScreen(
              workoutProgramJson: member.workoutProgram ?? "",
              memberName: member.name), // 1: Program
          _UserScheduleTab(myUid: myUid, db: db), // 2: Dersler
          MeasurementScreen(memberId: myUid, memberName: "Vücut"), // 3: Gelişim
          ProfileScreen(member: member), // 4: Profil
        ];

        return Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue.shade700, // Menü rengi mavi yapıldı
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(LineIcons.home), label: "Anasayfa"),
              BottomNavigationBarItem(
                  icon: Icon(LineIcons.dumbbell), label: "Program"),
              BottomNavigationBarItem(
                  icon: Icon(LineIcons.calendar), label: "Dersler"),
              BottomNavigationBarItem(
                  icon: Icon(LineIcons.lineChart), label: "Gelişim"),
              BottomNavigationBarItem(
                  icon: Icon(LineIcons.user), label: "Profil"),
            ],
          ),
        );
      },
    );
  }
}

class _UserDashboardTab extends StatelessWidget {
  final MemberModel member;
  final DatabaseService db;

  const _UserDashboardTab({required this.member, required this.db});

  void _showAllAnnouncements(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Tüm Duyurular 📢",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: db.getAnnouncements(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("Henüz duyuru yok."));
                        }

                        return ListView.separated(
                          controller: controller,
                          itemCount: snapshot.data!.docs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            var data = snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                            DateTime date = data['createdAt'] != null
                                ? (data['createdAt'] as Timestamp).toDate()
                                : DateTime.now();

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(LineIcons.bullhorn,
                                    color: Colors.blue),
                              ),
                              title: Text(data['title'] ?? 'Duyuru',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(data['text'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.black87)),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
                                        .format(date),
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11),
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
          },
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> data, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Tema tamamen Mavi tonlarına çekildi
        gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM').format(date),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(data['title'] ?? 'Duyuru',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Expanded(
            child: Text(data['text'] ?? '',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(member.name[0].toUpperCase(),
                  style: TextStyle(color: Colors.blue.shade800)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hoş geldin,",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(member.name,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Duyurular",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _showAllAnnouncements(context),
                  child: Text("Tümünü Gör",
                      style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: db.getAnnouncements(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: const Text("Henüz aktif bir duyuru yok.",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final docs = snapshot.data!.docs.take(5).toList();

                return SizedBox(
                  height: 125,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse, // Fare ile kaydırma desteği
                      },
                    ),
                    child: PageView.builder(
                      controller: PageController(
                          viewportFraction: 0.7), // Genişlik daraltıldı
                      padEnds: false,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        DateTime date = data['createdAt'] != null
                            ? (data['createdAt'] as Timestamp).toDate()
                            : DateTime.now();

                        return GestureDetector(
                          onTap: () => _showAllAnnouncements(context),
                          child: _buildAnnouncementCard(data, date),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            const Text("Bu Ay Performansın 🔥",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<SessionModel>>(
              stream: db.getMySessions(member.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                final now = DateTime.now();
                final thisMonth = (snapshot.data ?? [])
                    .where((s) =>
                        s.startTime.month == now.month &&
                        s.startTime.year == now.year)
                    .toList();

                final completedCount =
                    thisMonth.where((s) => s.isCompleted).length;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Toplam Ders",
                        value: "${thisMonth.length}",
                        subtext: "Bu ay tanımlanan",
                        color: Colors.blue.shade700,
                        icon: LineIcons.calendarCheck,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: "Katılım Sağlanan",
                        value: "$completedCount",
                        subtext: "Tamamlanan ders",
                        color: Colors.cyan.shade600,
                        icon: LineIcons.userCheck,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 25),
            const Text("Üyelik Durumu 💳",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPaymentCard(member),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(MemberModel member) {
    bool isPaid = member.isPaid;
    int daysLeft = member.nextPaymentDate.difference(DateTime.now()).inDays;

    Color bgColor;
    Color textColor;
    String title;
    String desc;
    IconData icon;

    if (!isPaid) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      title = "Ödeme Yapılmadı";
      desc = "Lütfen ödemenizi yapınız.";
      icon = Icons.error_outline;
    } else if (daysLeft < 0) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      title = "Süre Doldu";
      desc = "${daysLeft.abs()} gün önce bitti.";
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
      title = "Aktif Üyelik";
      desc =
          "Bitiş: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(member.nextPaymentDate)}\n($daysLeft gün kaldı)";
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: textColor.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.subtext,
      required this.color,
      required this.icon});

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 15),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Text(subtext,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _UserScheduleTab extends StatelessWidget {
  final String myUid;
  final DatabaseService db;
  const _UserScheduleTab({required this.myUid, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("Derslerim",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0),
      body: StreamBuilder<List<SessionModel>>(
        stream: db.getMySessions(myUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final upcoming = (snapshot.data ?? [])
              .where((s) => s.startTime.isAfter(DateTime.now()))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          if (upcoming.isEmpty) {
            return const Center(child: Text("Yaklaşan dersin yok."));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: upcoming.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildSessionCard(upcoming[index], db),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session, DatabaseService db) {
    String dateStr = DateFormat('dd MMM', 'tr_TR').format(session.startTime);
    String timeStr =
        "${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)}";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100)),
      child: Row(
        children: [
          Icon(session.type == 'group' ? LineIcons.users : LineIcons.user,
              color: Colors.blue),
          const SizedBox(width: 15),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(session.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<TrainerModel?>(
                stream: db.getTrainerProfile(session.trainerId),
                builder: (context, snapshot) => Text(
                    "Hoca: ${snapshot.data?.name ?? '...'}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Text("$dateStr • $timeStr",
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          )
        ],
      ),
    );
  }
}
