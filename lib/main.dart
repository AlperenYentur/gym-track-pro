import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// BU IMPORT ZATEN VARDI, KULLANIYORUZ:
import 'package:intl/date_symbol_data_local.dart';

// Provider ve Servisler
import 'providers/auth_provider.dart';
import 'models/user_role.dart';

// Ekranlar
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/trainer/trainer_home.dart';
import 'screens/user/user_home_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("FlutterError: ${details.exception}");
    };

    debugPrint("DEBUG: WidgetsFlutterBinding.ensureInitialized() completed");

    // 1. Firebase Başlatılıyor
    debugPrint("DEBUG: Initializing Firebase...");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("DEBUG: Firebase initialization completed successfully");
    } catch (e, stack) {
      debugPrint("DEBUG: Firebase initialization failed: $e\n$stack");
    }

    // 2. TÜRKÇE TARİH FORMATI BAŞLATILIYOR
    debugPrint("DEBUG: Initializing date formatting...");
    try {
      await initializeDateFormatting('tr_TR', null);
      debugPrint("DEBUG: Date formatting initialization completed successfully");
    } catch (e) {
      debugPrint("DEBUG: Date formatting initialization failed with error: $e");
    }

    debugPrint("DEBUG: Running MyApp...");
    runApp(const MyApp());
    debugPrint("DEBUG: runApp() finished");
  }, (error, stack) {
    debugPrint("Uncaught async error: $error\n$stack");
  });
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
    if (auth.role == UserRole.admin) {
      return const AdminHomeScreen();
    } else if (auth.role == UserRole.trainer) {
      return const TrainerHomeScreen();
    } else if (auth.role == UserRole.member) {
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
