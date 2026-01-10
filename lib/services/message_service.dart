import 'package:url_launcher/url_launcher.dart';

class MessageService {
  static Future<void> sendWhatsApp(
      {required String phone, required String message}) async {
    // Numaradaki tüm karakterleri temizle
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Türkiye formatına (90) getir
    if (cleanPhone.startsWith('5') && cleanPhone.length == 10) {
      cleanPhone = '90$cleanPhone';
    } else if (cleanPhone.startsWith('05') && cleanPhone.length == 11) {
      cleanPhone = '9$cleanPhone';
    }

    final Uri url = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");

    try {
      // Dış uygulamayı açmayı dene
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("WhatsApp başlatılamadı: $e");
    }
  }
}
