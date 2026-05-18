# 🏋️‍♂️ GymTrackPro - White-Label SaaS Gym Management System

GymTrackPro, spor salonları için geliştirilmiş, yüksek ölçeklenebilirliğe sahip, "Branch-Based White-Label" (Dal Tabanlı Marka Giydirme) mimarisiyle kurgulanmış bir SaaS platformudur. Tek bir kod tabanı üzerinden, farklı spor salonlarına özel (renk, logo ve izole veritabanı) bağımsız uygulamalar üretilmesini sağlar.

![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase)

## ✨ Öne Çıkan Özellikler

* **Multi-Tenant (Çoklu Kiracı) Mimari:** Her müşteri (spor salonu) mantıksal (`gymId`) ve fiziksel (farklı Firebase projeleri) olarak birbirinden tamamen izoledir.
* **Akıllı Git İş Akışı:** Çekirdek özellikler `master` dalında geliştirilirken, müşteriye özel özelleştirmeler (tema, ikon, db bağlantısı) `client/gym-name` dallarında yaşar.
* **Tip Güvenli (Type-Safe) Rol Yönetimi:** `UserRole` enum yapısı ile Admin, Trainer ve Member yetkilendirmeleri hata payı olmaksızın yönetilir.
* **Sorgu Optimizasyonu & Sayfalama (Pagination):** Firestore okuma maliyetlerini düşürmek ve performansı artırmak için büyük listelerde sayfalama (infinite-scroll) ve "Composite Index" yapısı kullanılmıştır.
* **Çapraz Platform:** Aynı kod tabanı ile Android (APK/AAB), iOS ve Web (Firebase Hosting) üzerinde çalışır.

## 🏗️ Mimari ve Branch Stratejisi

Projenin yönetilebilirliği, Git dallarının stratejik kullanımına dayanır:

* **`master` (Core Branch):** Uygulamanın motorudur. Genel özellikler, hata düzeltmeleri ve performans iyileştirmeleri burada yapılır. Herhangi bir müşteriye özel veri veya logo içermez.
* **`salon-a` (Client Branch):** Belirli bir müşterinin canlı ortamıdır. `master` dalından beslenir ancak kendine ait `firebase_options_salona.dart` bağlantısını, özel UI temalarını ve paket ismini (applicationId) barındırır.
  * *Güncelleme Akışı:* `master` dalında yapılan bir yenilik, `git merge master` komutu ile müşteri dalına aktarılırken, müşterinin özel veritabanı bağlantısı korunur.

## 🗄️ Veritabanı Şeması (Firestore)

Veriler NoSQL hiyerarşisine göre optimize edilmiştir:
* **`users`:** Kimlik doğrulama ve rol (`UserRole`) yönetimi.
* **`members`:** Üye profilleri, ödeme durumları ve hatırlatıcı logları (`reminders` sub-collection).
* **`sessions`:** Antrenman/Ders programları ve katılımcı listeleri.
* **`attendance_records`:** Yoklama geçmişi.

*(Not: Tüm koleksiyonlarda verilerin karışmasını engellemek için `gymId` alanı zorunlu tutulmuştur.)*

