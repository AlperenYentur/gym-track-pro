import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sadece sayı girişi için gerekli
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/trainer_model.dart'; // Model dosyasını import ettiğinden emin ol

class TrainerListScreen extends StatefulWidget {
  const TrainerListScreen({super.key});

  @override
  State<TrainerListScreen> createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends State<TrainerListScreen> {
  bool _isLoading = false;

  // EĞİTMEN EKLEME VE DÜZENLEME PENCERESİ
  // trainer parametresi boş gelirse "EKLEME", dolu gelirse "DÜZENLEME" modu çalışır.
  void _showTrainerDialog(BuildContext parentContext, String gymId,
      {TrainerModel? trainer}) {
    final isEditing = trainer != null;

    // Controller'ları mevcut verilerle veya boş başlatıyoruz
    final emailController = TextEditingController(); // Düzenlemede gizlenecek
    final passwordController =
        TextEditingController(); // Düzenlemede gizlenecek
    final nameController =
        TextEditingController(text: isEditing ? trainer.name : "");
    final phoneController =
        TextEditingController(text: isEditing ? trainer.phone : "");
    final specialtyController =
        TextEditingController(text: isEditing ? trainer.specialty : "");

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Eğitmeni Düzenle" : "Yeni Eğitmen Ekle",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, "Ad Soyad", LineIcons.user),
              const SizedBox(height: 10),

              // E-posta ve Şifre sadece YENİ kayıt eklerken görünür
              if (!isEditing) ...[
                _buildTextField(emailController, "E-posta", LineIcons.envelope),
                const SizedBox(height: 10),
                _buildTextField(passwordController, "Şifre", LineIcons.lock,
                    isObscure: true),
                const SizedBox(height: 10),
              ],

              // TELEFON GİRİŞ ALANI
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: "Telefon (Örn: 5xxxxxxxxx)",
                  prefixIcon: const Icon(LineIcons.phone),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(specialtyController,
                  "Uzmanlık (Fitness, Yoga vb.)", LineIcons.certificate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // --- DOĞRULAMA (VALIDATION) ---
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final spec = specialtyController.text.trim();

              // Ortak alan kontrolü
              if (name.isEmpty || spec.isEmpty) {
                _showSnack(
                    context, "Lütfen İsim ve Uzmanlık giriniz!", Colors.orange);
                return;
              }

              // Yeni kayıtsa E-posta/Şifre kontrolü de yap
              if (!isEditing) {
                if (emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty) {
                  _showSnack(
                      context, "E-posta ve Şifre zorunludur!", Colors.orange);
                  return;
                }
              }

              // Telefon Kontrolü
              if (phone.isEmpty ||
                  !phone.startsWith('5') ||
                  phone.length != 10) {
                _showSnack(
                    context,
                    "⚠️ Telefon 5 ile başlamalı ve 10 haneli olmalıdır!",
                    Colors.red);
                return;
              }

              // --- KAYIT / GÜNCELLEME İŞLEMİ ---
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                if (isEditing) {
                  // DÜZENLEME İŞLEMİ (Sadece DatabaseService kullanılır)
                  await DatabaseService(gymId: gymId).updateTrainer(
                    trainer.id, // ID değişmez
                    name,
                    phone,
                    spec,
                  );
                  if (mounted) {
                    _showSnack(context, "Bilgiler güncellendi! ✅", Colors.blue);
                  }
                } else {
                  // YENİ EKLEME İŞLEMİ (AuthService kullanılır - Kullanıcı oluşturur)
                  await AuthService().createTrainer(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    gymId: gymId,
                    name: name,
                    phone: phone,
                    specialty: spec,
                  );
                  if (mounted) {
                    _showSnack(
                        context, "Eğitmen başarıyla eklendi! ✅", Colors.green);
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showSnack(context, "Hata: $e", Colors.red);
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(isEditing ? "GÜNCELLE" : "KAYDET"),
          ),
        ],
      ),
    );
  }

  // EĞİTMEN SİLME FONKSİYONU
  void _deleteTrainer(String trainerId, String name, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eğitmeni Sil"),
        content: Text("$name adlı eğitmeni silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await db.deleteTrainer(trainerId);
              if (mounted) {
                _showSnack(context, "Eğitmen silindi.", Colors.grey);
              }
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // YARDIMCI WIDGET: INPUT ALANI
  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final db = DatabaseService(gymId: auth.gymId);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Eğitmen Listesi",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<TrainerModel>>(
              stream: db.getTrainers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LineIcons.userTie,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text("Henüz eğitmen eklenmemiş.",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final trainers = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trainers.length,
                  itemBuilder: (context, index) {
                    final trainer = trainers[index];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(LineIcons.userTie,
                              color: Colors.orange),
                        ),
                        title: Text(trainer.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            Text("${trainer.specialty} • ${trainer.phone}"),
                        // --- DÜZENLEME VE SİLME BUTONLARI ---
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // DÜZENLEME BUTONU
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTrainerDialog(
                                  context, auth.gymId ?? "",
                                  trainer: trainer), // Modeli gönderiyoruz
                            ),
                            // SİLME BUTONU
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _deleteTrainer(trainer.id, trainer.name, db),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTrainerDialog(
            context, auth.gymId ?? ""), // Trainer göndermiyoruz = Yeni Ekleme
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text("Eğitmen Ekle", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
