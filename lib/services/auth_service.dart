import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // EKLENDİ
import '../firebase_options.dart'; // EKLENDİ (Firebase ayarlarını çekmek için)
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Giriş
  Future<User?> login(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return result.user;
  }

  // Çıkış
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Şifre Güncelleme
  Future<void> updatePassword(String newPassword) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword);
    }
  }

  // Admin Kaydı (Burası genelde login ekranından yapıldığı için standart kalabilir)
  Future<void> registerAdmin(
      String email, String password, String gymName) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;

    if (user != null) {
      await _db.collection('admins').doc(user.uid).set({
        'email': email,
        'gymName': gymName,
        'role': UserRole.admin.toStr,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Admin users tablosuna da eklenebilir
      await _db.collection('users').doc(user.uid).set({
        'email': email,
        'role': UserRole.admin.toStr,
        'gymId': user.uid, // Admin kendi ID'si GymID olur
      });
    }
  }

  // --- EĞİTMEN KAYDI (DÜZELTİLDİ: Admin oturumu kapanmasın diye) ---
  Future<void> createTrainer({
    required String email,
    required String password,
    required String gymId,
    required String name,
    required String phone,
    required String specialty,
  }) async {
    FirebaseApp? tempApp;
    try {
      // 1. Geçici bir Firebase uygulaması başlatıyoruz
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Bu geçici uygulama üzerinden kayıt yapıyoruz
      UserCredential result = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // 3. Veritabanı kayıtlarını (Firestore) yapıyoruz
      if (user != null) {
        // Trainers Koleksiyonuna
        await _db.collection('trainers').doc(user.uid).set({
          'gymId': gymId,
          'email': email,
          'name': name,
          'phone': phone,
          'specialty': specialty,
          'role': UserRole.trainer.toStr,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Users Koleksiyonuna (Giriş yetkisi için)
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'role': UserRole.trainer.toStr,
          'gymId': gymId,
        });
      }
    } catch (e) {
      rethrow; // Hatayı yukarı fırlat
    } finally {
      // 4. İşlem bitince geçici uygulamayı siliyoruz
      await tempApp?.delete();
    }
  }

  // --- ÜYE KAYDI (DÜZELTİLDİ: Admin oturumu kapanmasın diye) ---
  Future<void> createGymMember({
    required String email,
    required String password,
    required String gymId,
    required String name,
    required String phone,
    required DateTime startDate,
    required DateTime endDate,
    required bool isPaid,
    double debt = 0.0,
    double paidAmount = 0.0,
  }) async {
    FirebaseApp? tempApp;
    try {
      // 1. Geçici bir Firebase uygulaması başlatıyoruz
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterAppMember',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Bu geçici uygulama üzerinden kayıt yapıyoruz
      UserCredential result = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // 3. Veritabanı kayıtlarını yapıyoruz
      if (user != null) {
        // Members Koleksiyonuna
        await _db.collection('members').doc(user.uid).set({
          'gymId': gymId,
          'email': email,
          'name': name,
          'phone': phone,
          'role': UserRole.member.toStr,
          'isPaid': isPaid,
          'debt': debt,
          'lastPaymentDate': Timestamp.fromDate(startDate),
          'nextPaymentDate': Timestamp.fromDate(endDate),
          'createdAt': FieldValue.serverTimestamp(),
          'workoutProgram': null, // Başlangıçta boş
        });

        // 3.1 Kasa Kaydı (Eğer ödeme alındıysa)
        if (paidAmount > 0) {
          await _db.collection('transactions').add({
            'gymId': gymId,
            'type': 'income',
            'amount': paidAmount,
            'description': 'Yeni Üyelik Kaydı ($name)',
            'date': FieldValue.serverTimestamp(),
            'relatedMemberId': user.uid,
          });
        }

        // Users Koleksiyonuna
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'role': UserRole.member.toStr,
          'gymId': gymId,
        });
      }
    } catch (e) {
      rethrow;
    } finally {
      // 4. Geçici uygulamayı temizle
      await tempApp?.delete();
    }
  }
}
