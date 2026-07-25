import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  UserRole? _role;
  String? _gymId;
  bool _isLoading = true; // Uygulama açılırken yükleniyor durumunda başlasın

  // Getterlar (Dışarıdan erişim için)
  User? get currentUser => _user;
  UserRole? get role => _role;
  String? get gymId => _gymId;
  bool get isLoading => _isLoading;
  bool get isAuth => _user != null;

  AuthProvider() {
    _init();
  }

  // Dinleyiciyi Başlat
  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _user = user;

      if (user != null) {
        // Kullanıcı giriş yaptıysa Rolünü ve GymId'sini çek
        await _fetchUserDetails(user.uid);
      } else {
        // Çıkış yaptıysa bilgileri sıfırla
        _role = null;
        _gymId = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // Veritabanından Rol ve Gym ID çekme
  Future<void> _fetchUserDetails(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _role = UserRole.fromString(data['role']);
        final fetchedGymId = data['gymId'] as String?;
        _gymId = (fetchedGymId != null && fetchedGymId.isNotEmpty) ? fetchedGymId : 'salon1';
      }
    } catch (e) {
      debugPrint("Kullanıcı detayları çekilemedi: $e");
    }
  }

  // Giriş Yap
  Future<String?> login(String email, String password) async {
    try {
      await _authService.login(email, password);
      return null; // Hata yok
    } catch (e) {
      return "Giriş başarısız: ${e.toString()}";
    }
  }

  // Çıkış Yap
  Future<void> logout() async {
    await _authService.logout();
    _role = null;
    _gymId = null;
    notifyListeners();
  }
}
