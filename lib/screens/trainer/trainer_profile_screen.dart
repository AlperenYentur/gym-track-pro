import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/trainer_model.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final _authService = AuthService();

  // Controllerlar
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = true; // İlk yükleme kontrolü

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // Verileri güncelleme fonksiyonu
  void _updateProfile(String trainerId, String currentPhone, String currentName,
      String currentSpec) async {
    final String newName = _nameController.text.trim();
    final String newPhone = _phoneController.text.trim();
    final String newSpec = _specialtyController.text.trim();
    final String newPass = _passController.text.trim();

    // Validasyonlar
    if (newName.isEmpty || newSpec.isEmpty) {
      _showSnack("İsim ve Uzmanlık boş bırakılamaz!", Colors.orange);
      return;
    }

    if (!newPhone.startsWith('5') || newPhone.length != 10) {
      _showSnack(
          "Telefon 5 ile başlamalı ve 10 hane olmalıdır!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final db = DatabaseService(gymId: auth.gymId);

      // 1. Profil Bilgilerini Güncelle (Eğer değişiklik varsa)
      if (newName != currentName ||
          newPhone != currentPhone ||
          newSpec != currentSpec) {
        await db.updateTrainer(trainerId, newName, newPhone, newSpec);
      }

      // 2. Şifre Güncelle (Eğer doluysa)
      if (newPass.isNotEmpty) {
        if (newPass.length < 6) {
          throw Exception("Şifre en az 6 karakter olmalı!");
        }
        await _authService.updatePassword(newPass);
        _passController.clear();
      }

      if (mounted) _showSnack("Profil başarıyla güncellendi! ✅", Colors.green);
    } catch (e) {
      if (mounted) _showSnack("Hata: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final db = DatabaseService(gymId: auth.gymId);
    final myUid = auth.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profil Ayarları",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LineIcons.alternateSignOut, color: Colors.red),
            onPressed: () => auth.logout(),
            tooltip: "Çıkış Yap",
          )
        ],
      ),
      body: StreamBuilder<TrainerModel?>(
        stream: db.getTrainerProfile(myUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Profil yüklenemedi."));
          }

          final trainer = snapshot.data!;

          // İlk açılışta verileri controller'a doldur
          if (_isInit) {
            _nameController.text = trainer.name;
            _phoneController.text = trainer.phone;
            _specialtyController.text = trainer.specialty;
            _isInit =
                false; // Bir daha doldurma (Kullanıcı yazarken silinmesin)
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black,
                  child: Icon(LineIcons.userTie, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(trainer.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                _inputField("Ad Soyad", LineIcons.user, _nameController),
                const SizedBox(height: 15),
                _inputField("Uzmanlık Alanı", LineIcons.certificate,
                    _specialtyController),
                const SizedBox(height: 15),
                _inputField(
                    "Telefon (0 olmadan)", LineIcons.phone, _phoneController,
                    isPhone: true),
                const SizedBox(height: 15),
                _inputField("Yeni Şifre (Değişmeyecekse boş bırak)",
                    LineIcons.lock, _passController,
                    isPass: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading
                        ? null
                        : () => _updateProfile(trainer.id, trainer.phone,
                            trainer.name, trainer.specialty),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("GÜNCELLE",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController ctrl,
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
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
