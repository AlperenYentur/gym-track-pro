import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// BU IMPORT ZATEN VARDI, KULLANIYORUZ:
import 'package:intl/date_symbol_data_local.dart';

// Provider ve Servisler
import 'providers/auth_provider.dart';

// Ekranlar
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/trainer/trainer_home.dart';
import 'screens/user/user_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase Başlatılıyor
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. TÜRKÇE TARİH FORMATI BAŞLATILIYOR (HATAYI ÇÖZEN SATIR BU)
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GYM TRACK PRO',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// GİRİŞ KONTROL MERKEZİ (ROUTER)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // 1. Durum: Yükleniyor...
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    // 2. Durum: Giriş yapılmamış -> Login Ekranı
    if (!auth.isAuth) {
      return const LoginScreen();
    }

    // 3. Durum: Rolüne göre yönlendir
    if (auth.role == 'admin') {
      return const AdminHomeScreen();
    } else if (auth.role == 'trainer') {
      return const TrainerHomeScreen();
    } else if (auth.role == 'member') {
      return const UserHomeScreen();
    }

    // --- 4. DURUM: HATA / BİLİNMEYEN ROL ---
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "HATA: Rol Tanımlanamadı",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Kullanıcı rolü: ${auth.role ?? 'Bulunamadı'}\nLütfen yöneticinizle iletişime geçin.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white),
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text("ÇIKIŞ YAP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
