import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart'; // Provider eklendi
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/member_model.dart';
import '../../providers/auth_provider.dart'; // AuthProvider eklendi

class ProfileScreen extends StatefulWidget {
  final MemberModel member;
  const ProfileScreen({super.key, required this.member});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _passController = TextEditingController();
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.member.phone);
  }

  void _updateProfile() async {
    final String newPhone = _phoneController.text.trim();
    final String newPass = _passController.text.trim();
    final dbService = DatabaseService();

    if (!newPhone.startsWith('5') || newPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Telefon 5 ile başlamalı ve 10 hane olmalıdır!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Telefon güncelle
      if (newPhone != widget.member.phone) {
        await dbService.updateMemberPhone(widget.member.id, newPhone);
      }

      // Şifre güncelle (Eğer girildiyse)
      if (newPass.isNotEmpty) {
        if (newPass.length < 6) {
          throw Exception("Şifre en az 6 karakter olmalı!");
        }
        await _authService.updatePassword(newPass);
        _passController.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profil güncellendi! ✅"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profilim",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Icon(LineIcons.user, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(widget.member.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(authProvider.currentUser?.email ?? "",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            _inputField("Telefon Numaranız", LineIcons.phone, _phoneController,
                isPhone: true),
            const SizedBox(height: 15),
            _inputField(
                "Yeni Şifre (İsteğe Bağlı)", LineIcons.lock, _passController,
                isPass: true),
            const SizedBox(height: 30),

            // GÜNCELLE BUTONU
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("BİLGİLERİ GÜNCELLE",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // ÇIKIŞ YAP BUTONU (YENİ EKLENDİ)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => authProvider.logout(),
                icon: const Icon(LineIcons.alternateSignOut, color: Colors.red),
                label: const Text("ÇIKIŞ YAP",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
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
