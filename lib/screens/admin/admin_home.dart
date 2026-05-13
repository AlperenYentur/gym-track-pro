import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/member_model.dart';

// Sayfa importları
import 'member_list.dart';
import 'trainer_list.dart';
import '../common/class_manager.dart';
import '../common/attendance_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardTab(), // 0
    const MemberListScreen(), // 1
    const TrainerListScreen(), // 2
    const _AttendanceHubTab(), // 3
    const _SettingsTab(), // 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          // DEĞİŞİKLİK: Label "Özet" yerine "Anasayfa" yapıldı
          BottomNavigationBarItem(
              icon: Icon(LineIcons.home), label: "Anasayfa"),
          BottomNavigationBarItem(icon: Icon(LineIcons.users), label: "Üyeler"),
          BottomNavigationBarItem(
              icon: Icon(LineIcons.userTie), label: "Eğitmen"),
          BottomNavigationBarItem(
              icon: Icon(LineIcons.clipboardList), label: "Yoklama"),
          BottomNavigationBarItem(icon: Icon(LineIcons.cog), label: "Ayarlar"),
        ],
      ),
    );
  }
}

// --- 1. DASHBOARD (ANASAYFA EKRANI) ---
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  DateTime? _lastResetDate;
  bool _isLoadingDate = true;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında eski duyuruları temizle ve kasa tarihini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final db = DatabaseService(gymId: auth.gymId);
      db.cleanupExpiredAnnouncements();
      _checkKasaReset(db);
    });
  }

  Future<void> _checkKasaReset(DatabaseService db) async {
    final lastReset = await db.getLastResetDate();
    final now = DateTime.now();

    if (lastReset != null) {
      // Eğer ay değişmişse otomatik sıfırla
      if (lastReset.month != now.month || lastReset.year != now.year) {
        await db.resetCashRegister();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Yeni ay başladı! Kasa otomatik sıfırlandı. 🗓️")));
          setState(() {
            _lastResetDate = DateTime.now();
            _isLoadingDate = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lastResetDate = lastReset;
            _isLoadingDate = false;
          });
        }
      }
    } else {
      // Hiç sıfırlanmamışsa varsayılan olarak null (Tüm zamanlar)
      if (mounted) setState(() => _isLoadingDate = false);
    }
  }

  Future<void> _manualReset(DatabaseService db) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Kasa Sıfırlama"),
              content: const Text(
                  "Kasayı sıfırlamak istediğinize emin misiniz?\n\nBu işlem kasayı silmez, sadece 'Bu Ay' görünümünü sıfırlar."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("İptal")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Evet, Sıfırla",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      await db.resetCashRegister();
      if (mounted) {
        setState(() => _lastResetDate = DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kasa başarıyla sıfırlandı! ✅")));
      }
    }
  }

  Future<void> _showHistoryDialog(DatabaseService db) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kasa Geçmişi"),
        content: StreamBuilder<double>(
          stream: db.getTotalIncome(fromDate: null), // Tüm zamanlar
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            double total = snapshot.data ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Tüm Zamanlar Toplam Gelir",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
                      .format(total),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 20),
                const Text(
                    "Not: Sıfırlamalar bu tutarı etkilemez.\nBurası işletmenin başından beri kazandığı toplam tutardır.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Kapat"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final db = DatabaseService(gymId: auth.gymId);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("YÖNETİCİ PANELİ",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DUYURU PANOSU (YÖNETİCİ İÇİN EKLE/SİL AÇIK) ---
            const Text("📢 Duyuru Yönetimi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _AnnouncementBoard(db: db),
            const SizedBox(height: 25),

            // --- İSTATİSTİKLER ---
            const Text("Genel Durum",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // KASA KARTI (RESTORED & IMPROVED)
            if (_isLoadingDate)
              const Center(child: CircularProgressIndicator())
            else
              StreamBuilder<double>(
                stream: db.getTotalIncome(fromDate: _lastResetDate),
                builder: (context, snapshot) {
                  double total = snapshot.data ?? 0;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.green.shade700,
                        Colors.green.shade400
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle),
                              child: const Icon(LineIcons.wallet,
                                  color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("KASA (Bu Ay)",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  Text(
                                      NumberFormat.currency(
                                              locale: 'tr_TR', symbol: '₺')
                                          .format(total),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // GEÇMİŞ (HISTORY) BUTONU
                            IconButton(
                              onPressed: () => _showHistoryDialog(db),
                              icon: const Icon(Icons.history,
                                  color: Colors.white),
                              tooltip: "Tüm Geçmiş",
                            ),
                            // SIFIRLA BUTONU
                            IconButton(
                              onPressed: () => _manualReset(db),
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              tooltip: "Kasayı Sıfırla",
                            )
                          ],
                        ),
                        if (_lastResetDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.white70, size: 12),
                                const SizedBox(width: 5),
                                Text(
                                  "Son Sıfırlama: ${DateFormat('dd MMM HH:mm').format(_lastResetDate!)}",
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 11),
                                )
                              ],
                            ),
                          )
                      ],
                    ),
                  );
                },
              ),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<MemberModel>>(
                    stream: db.getMembers(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.length : 0;
                      return _StatCard(
                          title: "Toplam Üye",
                          count: "$count",
                          color: Colors.blue,
                          icon: LineIcons.users);
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StreamBuilder<List<dynamic>>(
                    stream: db.getTrainers(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.length : 0;
                      return _StatCard(
                          title: "Eğitmen",
                          count: "$count",
                          color: Colors.orange,
                          icon: LineIcons.userTie);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<MemberModel>>(
                    stream: db.getMembers(),
                    builder: (context, snapshot) {
                      int activeCount = 0;
                      if (snapshot.hasData) {
                        activeCount = snapshot.data!.where((m) {
                          bool isDateValid =
                              m.nextPaymentDate.isAfter(DateTime.now());
                          return isDateValid && m.isPaid;
                        }).length;
                      }
                      return _StatCard(
                          title: "Aktif Üye",
                          count: "$activeCount",
                          color: Colors.green,
                          icon: LineIcons.checkCircle);
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StreamBuilder<List<MemberModel>>(
                    stream: db.getMembers(),
                    builder: (context, snapshot) {
                      int thisMonthCount = 0;
                      if (snapshot.hasData) {
                        final now = DateTime.now();
                        thisMonthCount = snapshot.data!.where((m) {
                          return m.lastPaymentDate.year == now.year &&
                              m.lastPaymentDate.month == now.month;
                        }).length;
                      }
                      return _StatCard(
                          title: "Bu Ay Kayıt",
                          count: "$thisMonthCount",
                          color: Colors.purple,
                          icon: LineIcons.userPlus);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. YOKLAMA MERKEZİ ---
class _AttendanceHubTab extends StatelessWidget {
  const _AttendanceHubTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Yoklama Merkezi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _HubCard(
              title: "Yoklama Al",
              desc: "Sınıfları seç ve bugünün yoklamasını gir.",
              icon: LineIcons.clipboardList,
              color: Colors.redAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AttendanceScreen())),
            ),
            const SizedBox(height: 20),
            _HubCard(
              title: "Sınıf & Grup Yönetimi",
              desc: "Yeni spor dalları ve gruplar oluştur.",
              icon: LineIcons.sitemap,
              color: Colors.teal,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClassManagerScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. AYARLAR ---
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Ayarlar",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Icon(LineIcons.userShield, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text("Yönetici Hesabı",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(auth.currentUser?.email ?? "",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              onPressed: () => auth.logout(),
              icon: const Icon(LineIcons.alternateSignOut),
              label: const Text("Çıkış Yap"),
            )
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI WIDGETLAR ---

// DUYURU PANOSU (YÖNETİCİ/EĞİTMEN İÇİN EKLEME ÖZELLİKLİ)
class _AnnouncementBoard extends StatefulWidget {
  final DatabaseService db;
  const _AnnouncementBoard({required this.db});

  @override
  State<_AnnouncementBoard> createState() => _AnnouncementBoardState();
}

class _AnnouncementBoardState extends State<_AnnouncementBoard> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController =
      TextEditingController(); // Başlık için
  bool _isWriting = false;

  void _postAnnouncement() async {
    if (_textController.text.isEmpty) return;

    // Title opsiyonel, boşsa varsayılan atanır
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
          // Yazı Alanı
          if (_isWriting)
            Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Başlık (Örn: Tatil)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Duyuru içeriğini giriniz...",
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

          // Ekleme Butonu (Eğer yazmıyorsak)
          if (!_isWriting)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Aktif Duyurular",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _isWriting = true),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Ekle"),
                )
              ],
            ),

          const SizedBox(height: 10),

          // Duyuru Listesi
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
                        ? DateFormat('dd MMM, HH:mm', 'tr_TR')
                            .format(ts.toDate())
                        : "";

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(LineIcons.bullhorn,
                            size: 18, color: Colors.orange),
                      ),
                      title: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(dateStr,
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _deleteAnnouncement(doc.id),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(count,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HubCard(
      {required this.title,
      required this.desc,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text(desc,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
