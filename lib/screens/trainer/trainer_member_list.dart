import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/member_model.dart';
import '../../providers/auth_provider.dart';
import 'workout_editor.dart';
import '../common/measurement_screen.dart'; // <-- YENİ EKRAN IMPORTU

enum SortType { nameAsc, nameDesc, daysAsc, daysDesc }

class TrainerMemberListScreen extends StatefulWidget {
  const TrainerMemberListScreen({super.key});

  @override
  State<TrainerMemberListScreen> createState() =>
      _TrainerMemberListScreenState();
}

class _TrainerMemberListScreenState extends State<TrainerMemberListScreen> {
  final AuthService _authService = AuthService();
  String _searchText = "";
  SortType _currentSort = SortType.nameAsc;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String myGymId = authProvider.gymId ?? '';
    final dbService = DatabaseService(gymId: myGymId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ARAMA VE SIRALAMA ALANI
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchText = val),
                    decoration: InputDecoration(
                      hintText: "Üye Ara...",
                      prefixIcon: const Icon(LineIcons.search),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<SortType>(
                    icon: const Icon(LineIcons.sortAmountDown),
                    tooltip: "Sırala",
                    onSelected: (SortType result) {
                      setState(() {
                        _currentSort = result;
                      });
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<SortType>>[
                      const PopupMenuItem<SortType>(
                        value: SortType.nameAsc,
                        child: Row(children: [
                          Icon(LineIcons.font, size: 18),
                          SizedBox(width: 8),
                          Text('İsim (A-Z)')
                        ]),
                      ),
                      const PopupMenuItem<SortType>(
                        value: SortType.nameDesc,
                        child: Row(children: [
                          Icon(LineIcons.font, size: 18),
                          SizedBox(width: 8),
                          Text('İsim (Z-A)')
                        ]),
                      ),
                      const PopupMenuItem<SortType>(
                        value: SortType.daysAsc,
                        child: Row(children: [
                          Icon(LineIcons.hourglassStart, size: 18),
                          SizedBox(width: 8),
                          Text('Süresi Bitenler (Önce)')
                        ]),
                      ),
                      const PopupMenuItem<SortType>(
                        value: SortType.daysDesc,
                        child: Row(children: [
                          Icon(LineIcons.hourglassEnd, size: 18),
                          SizedBox(width: 8),
                          Text('Süresi Bitenler (Sonra)')
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LİSTE ALANI
          Expanded(
            child: StreamBuilder<List<MemberModel>>(
              stream: dbService.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var members = snapshot.data!
                    .where((m) => m.name
                        .toLowerCase()
                        .contains(_searchText.toLowerCase()))
                    .toList();

                // SIRALAMA MANTIĞI
                members.sort((a, b) {
                  switch (_currentSort) {
                    case SortType.nameAsc:
                      return a.name
                          .toLowerCase()
                          .compareTo(b.name.toLowerCase());
                    case SortType.nameDesc:
                      return b.name
                          .toLowerCase()
                          .compareTo(a.name.toLowerCase());
                    case SortType.daysAsc:
                      if (!a.isPaid && b.isPaid) return -1;
                      if (a.isPaid && !b.isPaid) return 1;
                      return a.nextPaymentDate.compareTo(b.nextPaymentDate);
                    case SortType.daysDesc:
                      if (!a.isPaid && b.isPaid) return 1;
                      if (a.isPaid && !b.isPaid) return -1;
                      return b.nextPaymentDate.compareTo(a.nextPaymentDate);
                  }
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildMemberCard(context, members[index], dbService),
                );
              },
            ),
          ),
        ],
      ),
      // ÜYE EKLEME BUTONU
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context, myGymId),
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Üye Ekle", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, MemberModel member, DatabaseService db) {
    final int daysLeft =
        member.nextPaymentDate.difference(DateTime.now()).inDays;

    // Program kontrolü
    final hasProgram = member.workoutProgram != null &&
        member.workoutProgram!.isNotEmpty &&
        member.workoutProgram != "[]";

    return GestureDetector(
      // TIKLAYINCA PROGRAM YAZMAYA GİDER
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WorkoutEditorScreen(member: member)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // AVATAR
            CircleAvatar(
                backgroundColor: Colors.black,
                child: Text(member.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 15),

            // BİLGİLER
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Icon(
                          hasProgram ? Icons.check_circle : Icons.error_outline,
                          size: 12,
                          color: hasProgram ? Colors.green : Colors.orange),
                      const SizedBox(width: 4),
                      Text(hasProgram ? "Program Var" : "Program Yok",
                          style: TextStyle(
                              color: hasProgram ? Colors.green : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      member.isPaid
                          ? (daysLeft < 0
                              ? "⚠️ Süre Doldu"
                              : "⏳ $daysLeft gün kaldı")
                          : "⛔ Ödeme Bekleniyor",
                      style: TextStyle(
                          color: member.isPaid && daysLeft > 3
                              ? Colors.grey
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // ÖDEME DURUMU (TIKLANABİLİR)
            GestureDetector(
              onTap: () {
                if (member.isPaid) {
                  db.cancelPayment(member.id);
                } else {
                  _showPaymentDialog(context, member, db);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      member.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: member.isPaid ? Colors.green : Colors.red),
                ),
                child: Text(
                  member.isPaid ? "ÖDENDİ" : "BORÇLU",
                  style: TextStyle(
                      color: member.isPaid
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // --- YENİ EKLENEN VÜCUT ÖLÇÜM BUTONU ---
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MeasurementScreen(
                          memberId: member.id, memberName: member.name)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50, shape: BoxShape.circle),
                child: const Icon(LineIcons.lineChart,
                    size: 20, color: Colors.blue),
              ),
            ),

            const SizedBox(width: 5),

            // AYARLAR / DÜZENLEME BUTONU
            InkWell(
              onTap: () => _showEditMemberDialog(context, member, db),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.settings, size: 20, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- ÜYE DÜZENLEME & SİLME PENCERESİ (GÜNCELLENMİŞ) ---
  void _showEditMemberDialog(
      BuildContext context, MemberModel member, DatabaseService db) {
    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone);
    final debtCtrl = TextEditingController(
        text: member.debt > 0 ? member.debt.toString() : "");
    DateTime startDate = member.lastPaymentDate;
    DateTime endDate = member.nextPaymentDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Üye Bilgileri"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputDeco("Ad Soyad", LineIcons.user, nameCtrl),
                const SizedBox(height: 10),
                _inputDeco("Telefon", LineIcons.phone, phoneCtrl,
                    isPhone: true),
                const SizedBox(height: 10),
                const Text("Üyelik Tarihleri",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(children: [
                  Expanded(
                      child: _dateBox("Başlangıç", startDate, () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030));
                    if (d != null) setModalState(() => startDate = d);
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _dateBox("Bitiş", endDate, () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030));
                    if (d != null) setModalState(() => endDate = d);
                  })),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: debtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: "Kalan Borç (Opsiyonel)",
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.red.shade50),
                ),
                const SizedBox(height: 20),

                // SİLME BUTONU
                TextButton.icon(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                                title: const Text("Silinsin mi?"),
                                content: const Text("Bu işlem geri alınamaz."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text("Vazgeç")),
                                  TextButton(
                                      onPressed: () {
                                        db.deleteMember(member.id);
                                        Navigator.pop(c); // Onayı kapa
                                        Navigator.pop(ctx); // Düzenlemeyi kapa
                                      },
                                      child: const Text("SİL",
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ));
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Üyeyi Sil",
                        style: TextStyle(color: Colors.red)))
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  double debt =
                      double.tryParse(debtCtrl.text.replaceAll(',', '.')) ?? 0;
                  db.updateMemberDetails(member.id, nameCtrl.text,
                      phoneCtrl.text, startDate, endDate, debt);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bilgiler güncellendi!")));
                }
              },
              child: const Text("GÜNCELLE"),
            )
          ],
        );
      }),
    );
  }

  // --- ÖDEME PENCERESİ (GÜNCELLENMİŞ) ---
  void _showPaymentDialog(
      BuildContext context, MemberModel member, DatabaseService db) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    final amountCtrl = TextEditingController();
    final debtCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: Text("${member.name} Ödemesi"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Ödeme ve yeni bitiş tarihini seçiniz:"),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(
                      child: _dateBox("Ödeme Tarihi", startDate, () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030));
                    if (d != null) setModalState(() => startDate = d);
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _dateBox("Bitiş Tarihi", endDate, () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030));
                    if (d != null) setModalState(() => endDate = d);
                  })),
                ]),
                const SizedBox(height: 15),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Alınan Tutar (₺)",
                      border: OutlineInputBorder(),
                      hintText: "Örn: 1500"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: debtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Kalan Borç (Varsa)",
                      border: OutlineInputBorder(),
                      hintText: "Örn: 0"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () {
                // VALIDASYON 1: Tutar
                if (amountCtrl.text.isEmpty) {
                  showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                            title: const Text("Uyarı"),
                            content: const Text(
                                "Lütfen 'Alınan Tutar' kısmını doldurunuz. (0 yazabilirsiniz)"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text("Tamam"))
                            ],
                          ));
                  return;
                }

                // VALIDASYON 2: Borç
                if (debtCtrl.text.isEmpty) {
                  showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                            title: const Text("Uyarı"),
                            content: const Text(
                                "Lütfen 'Kalan Borç' kısmını doldurunuz. (Borç yoksa 0 yazınız)"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text("Tamam"))
                            ],
                          ));
                  return;
                }

                double amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                double debt =
                    double.tryParse(debtCtrl.text.replaceAll(',', '.')) ?? 0;

                db.confirmPayment(member.id, startDate, endDate, amount, debt);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ödeme kaydedildi!")));
              },
              child: const Text("ONAYLA"),
            )
          ],
        );
      }),
    );
  }

  // --- YENİ ÜYE EKLEME (Admin ile Aynı) ---
  void _showAddMemberDialog(BuildContext context, String gymId) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    bool isPaid = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Yeni Üye Hesabı"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputDeco("Ad Soyad", LineIcons.user, nameCtrl),
                const SizedBox(height: 10),
                _inputDeco("Telefon (5xx...)", LineIcons.phone, phoneCtrl,
                    isPhone: true),
                const SizedBox(height: 10),
                _inputDeco("E-posta", LineIcons.envelope, emailCtrl),
                const SizedBox(height: 10),
                _inputDeco("Şifre", LineIcons.lock, passCtrl, isPass: true),
                SwitchListTile(
                  title: const Text("Ödeme Alındı",
                      style: TextStyle(fontSize: 14)),
                  value: isPaid,
                  activeTrackColor: Colors.green,
                  onChanged: (val) => setModalState(() => isPaid = val),
                ),
                Opacity(
                  opacity: isPaid ? 1.0 : 0.4,
                  child: AbsorbPointer(
                    absorbing: !isPaid,
                    child: Row(children: [
                      Expanded(
                          child: _dateBox("Ödeme", startDate, () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030));
                        if (d != null) setModalState(() => startDate = d);
                      })),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _dateBox("Bitiş", endDate, () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030));
                        if (d != null) setModalState(() => endDate = d);
                      })),
                    ]),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameCtrl.text.isNotEmpty &&
                          emailCtrl.text.isNotEmpty &&
                          phoneCtrl.text.startsWith('5') &&
                          phoneCtrl.text.length == 10 &&
                          passCtrl.text.length >= 6) {
                        setModalState(() => isLoading = true);
                        try {
                          await _authService.createGymMember(
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                              gymId: gymId,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              startDate: startDate,
                              endDate: endDate,
                              isPaid: isPaid);
                          if (context.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setModalState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Hata: $e"),
                                backgroundColor: Colors.red));
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Lütfen tüm alanları doğru doldurun!")));
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("KAYDET", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      }),
    );
  }

  // --- YARDIMCI WIDGETLAR ---
  Widget _inputDeco(String hint, IconData icon, TextEditingController ctrl,
      {bool isPass = false, bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)
            ]
          : [],
      decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.black54),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none)),
    );
  }

  Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(DateFormat('dd/MM/yy').format(date),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(LineIcons.userSlash, size: 60, color: Colors.grey),
      SizedBox(height: 10),
      Text("Henüz hiç üye yok.", style: TextStyle(color: Colors.grey))
    ]));
  }
}
