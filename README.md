# YET Connect 🚀

YET Connect, modern kullanıcı arayüzü prensipleriyle tasarlanmış, gerçek zamanlı iletişim ve sosyal ağ özelliklerini bir araya getiren kapsamlı bir Flutter uygulamasıdır. Yüksek performanslı durum yönetimi, çevrimdışı (offline-first) çalışma yeteneği ve entegre oyunlaştırma özellikleriyle gelişmiş bir mobil uygulama deneyimi sunar[cite: 1].

## ✨ Öne Çıkan Özellikler

* **Çevrimdışı Çalışma (Offline-First Mimarisi):** SQLite (`sqflite`) ve Hive kullanılarak yapılandırılan önbellek mimarisi sayesinde, kullanıcılar internet bağlantısı olmasa bile sohbet geçmişlerine ve akışa (feed) erişebilir[cite: 1, 2].
* **Gerçek Zamanlı Sohbet (Real-time Chat):** Supabase entegrasyonu ile anlık mesajlaşma, fotoğraf/video gönderimi, mesaj yanıtlama ve anlık okundu/okunmadı (badge) bildirimleri[cite: 1].
* **Gelişmiş Sosyal Akış & Hikayeler:** Medya destekli gönderi paylaşımı, beğeni/yorum etkileşimleri, etiket (tag) tabanlı arama ve 24 saat süreli hikaye (story) paylaşım altyapısı[cite: 1].
* **Kapsamlı Kimlik Doğrulama:** Supabase Auth altyapısı ile E-posta/Şifre, 8 haneli OTP doğrulaması ve Google Sign-In entegrasyonu[cite: 1].
* **Oyunlaştırma & Flame Motoru:** Kullanıcı etkinliklerine dayalı puanlama/rütbe sistemi ve uygulama içine entegre edilmiş, Flame oyun motoru ile desteklenen Scrabble oyunu[cite: 1, 2].
* **Modern ve Akıcı UI/UX:** Özel animasyonlu alt gezinme çubuğu (lens efektli), Riverpod ile yönetilen Dinamik Karanlık/Aydınlık Tema, Shimmer yükleme efektleri ve Glassmorphism (cam efekti) detayları[cite: 1].
* **Bildirim Sistemi:** Firebase Cloud Messaging (FCM) ve Local Notifications ile arka plan ve ön plan anlık push bildirimleri[cite: 1, 2].

## 🛠 Teknoloji Yığını ve Mimari

Uygulama, "Feature-Driven Design" (Özellik Odaklı Tasarım) ve Clean Architecture prensipleri gözetilerek geliştirilmiştir[cite: 1].

* **Çerçeve:** Flutter (SDK ^3.9.2)[cite: 2]
* **Durum Yönetimi (State Management):** Riverpod (`flutter_riverpod`)[cite: 2]
* **Arka Uç (Backend):** Supabase (PostgreSQL, Realtime, Storage)[cite: 1]
* **Yerel Depolama (Local Storage):** `sqflite` (İlişkisel veriler) & `hive` (Anahtar-Değer verileri)[cite: 2]
* **Oyun Motoru:** Flame & Flame Audio[cite: 2]
* **Medya Yönetimi:** `image_picker`, `video_player`, `flutter_image_compress`, `cached_network_image`[cite: 2]
* **Analitik ve Hata Takibi:** Firebase Analytics & Firebase Crashlytics[cite: 1, 2]
* **Çoklu Dil:** `easy_localization` (Türkçe ve İngilizce)[cite: 1, 2]

## 📱 Ekran Görüntüleri

| Akış (Feed) | Gerçek Zamanlı Sohbet | Özel Navigasyon & Profil |
| :---: | :---: | :---: |
| ![Feed](LINK_EKLE) | ![Chat](LINK_EKLE) | ![Profile](LINK_EKLE) |

*(Not: Yukarıdaki alanlara projenin GitHub reposuna yüklediğin görsellerin linklerini ekleyebilirsin.)*

## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyebilirsiniz.

1. **Depoyu Klonlayın:**
   ```bash
   git clone [https://github.com/KULLANICI_ADI/yet_x_app.git](https://github.com/KULLANICI_ADI/yet_x_app.git)
   cd yet_x_app