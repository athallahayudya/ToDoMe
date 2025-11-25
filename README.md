# To Do Me – Frontend (Flutter)

To Do Me adalah aplikasi manajemen produktivitas (To-Do List) berbasis **Flutter** yang terhubung dengan **Laravel Backend API**.  
Dokumen ini berisi panduan setup lengkap front-end agar berjalan dengan baik di lingkungan lokal.

---

## 1. Ringkasan Fitur Utama

### 1.1 Sistem Autentikasi Hibrida

#### Register Manual (Strict Mode)
- Input wajib: Nama, Email, Password  
- Email Verification **wajib**  
- Akun **tidak dapat login** sebelum diverifikasi  

#### Google Sign-In (Android Native)
- Login 1 sentuhan melalui Google  
- Jika user baru → diarahkan ke halaman *Set Password Aplikasi*  
- Logout aman: melakukan `GoogleSignIn.disconnect()` + menghapus token JWT dari `flutter_secure_storage`  

---

### 1.2 Manajemen Tugas
- Membuat, menyunting, menghapus tugas  
- Subtasks (Checklist)  
- Kategori tugas  
- Filter: Aktif, Terlambat, Selesai  
- Sorting + tampilan expandable  

---

### 1.3 Dashboard Statistik
- Grafik mingguan (Line Chart)  
- Pie Chart completion rate  
- Summary Cards (total tugas, selesai, tertunda)

---

## 2. Persyaratan Environment (Wajib)

### 2.1 Software Utama
- Flutter SDK versi **3.x.x** atau lebih baru  
- VS Code atau Android Studio  
- Backend Laravel (`todome_backend`) berjalan:  
  ```bash
  php artisan serve
  ```

### 2.2 Perangkat
- Android Emulator (AVD)  
- HP fisik (USB Debugging ON)  
- Chrome/Edge (untuk testing Web)

### 2.3 Google Sign-In Requirements
- Akses Google Cloud Console  
- SHA-1 fingerprint  
- OAuth 2.0 Client ID (Android)

---

## 3. Instalasi Project

### 3.1 Clone Repo
```bash
git clone https://github.com/SeptianTito123/todome.git
cd todome
```

### 3.2 Install Dependencies
```bash
flutter pub get
```

Jika error:
```bash
flutter pub upgrade
```

---

## 4. Menjalankan Backend Laravel

Pastikan backend berjalan sebelum menjalankan frontend.

```bash
cd C:\laragon\www\todome_backend
php artisan serve
```

Default URL backend:

```
http://127.0.0.1:8000
```

---

## 5. Konfigurasi Koneksi API

Semua endpoint API diatur di:

```
lib/services/api_service.dart
```

Kode otomatis mendeteksi platform:

```dart
static String get _baseUrl {
  if (kIsWeb) {
    return "http://127.0.0.1:8000/api";
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    return "http://10.0.2.2:8000/api";
  } else {
    return "http://127.0.0.1:8000/api";
  }
}
```

**Jika menggunakan HP Fisik**, ubah menjadi IP Laptop:

```
http://192.168.1.xx:8000/api
```

---

## 6. Setup Google Sign-In (Penting)

Tanpa setup ini, login Google akan error:

> ApiException: 10 – DEVELOPER_ERROR

### 6.1 Ambil SHA-1 Fingerprint

Masuk folder android:

```bash
cd android
```

Windows:
```bash
.\gradlew signingReport
```

Mac/Linux:
```bash
./gradlew signingReport
```

Cari:
```
Variant: debug
SHA1: XX:XX:XX:...
```

### 6.2 Daftarkan di Google Cloud Console
- Masuk ke *API & Services → Credentials*  
- Pilih **OAuth Client ID (Android)**  
- Isi:
  - Package Name (sesuai `build.gradle`)  
  - SHA-1 fingerprint  

---

## 7. Menjalankan Aplikasi Flutter

Pastikan:
- Backend aktif  
- Emulator/Device menyala  

Jalankan:
```bash
flutter run
```

---

## 8. Alur Verifikasi Email (Mode Development)

Karena backend berjalan di laptop (localhost):

1. User register dari HP/Emulator  
2. Email verifikasi masuk ke Gmail  
3. **Link verifikasi hanya dapat dibuka di Laptop**, bukan HP  
4. Klik tombol verifikasi  
5. Setelah sukses, kembali ke HP → Login berhasil  

Jika dibuka dari HP → akan gagal (127.0.0.1 mengarah ke HP, bukan laptop)

---

## 9. Struktur Folder

```
lib/
 ├─ screens/
 │   ├─ login_screen.dart
 │   ├─ register_screen.dart
 │   ├─ google_setup_screen.dart
 │   ├─ home_screen.dart
 │   ├─ task_detail_screen.dart
 │   └─ profile_screen.dart
 │
 ├─ services/
 │   ├─ api_service.dart
 │   └─ google_auth_service.dart
 │
 └─ models/
     ├─ task.dart
     ├─ category.dart
     └─ subtask.dart
```

---

## 10. Package Penting

### http  
Untuk seluruh komunikasi API (GET, POST, PUT, DELETE).

### flutter_secure_storage  
Menyimpan token login secara aman dan terenkripsi.

### intl  
Digunakan untuk format tanggal dan waktu.

---

## 11. Troubleshooting

### A. Manifest Merger Failed  
Solusi:
```xml
package="com.example.todome"
```

### B. ApiException: 10 (Google Login)
Penyebab:
- SHA-1 belum terdaftar  
- Package name tidak cocok  

### C. Error: Ambiguous import: Category  
Solusi:
```dart
import 'package:flutter/foundation.dart' hide Category;
```

### D. Link Email Verification Invalid  
Tambahkan pada Laravel:

```php
URL::forceRootUrl('http://127.0.0.1:8000');
```

---
---

## 12. Integrasi Calendar (Table Calendar + Google Calendar API)

Jika Anda ingin menambahkan fitur kalender (misalnya untuk menampilkan agenda, tugas per hari, atau integrasi Google Calendar), ikuti langkah-langkah berikut.

---

### 12.1 Instalasi Package `table_calendar`

Anda dapat menambahkan package menggunakan salah satu dari dua cara berikut.

### Cara 1 — Instalasi via Terminal (Rekomendasi)
Buka terminal di VS Code atau Android Studio (pastikan Anda berada di folder project `todome`), kemudian jalankan:

```bash
flutter pub add table_calendar
```

---

### Cara 2 — Tambahkan Manual melalui `pubspec.yaml`

Jika instalasi via terminal gagal, Anda bisa menambahkannya secara manual:

1. Buka file `pubspec.yaml`.
2. Cari bagian:

   ```yaml
   dependencies:
   ```
3. Tambahkan baris berikut di bawah package lain seperti `fl_chart` atau `intl`:

   ```yaml
   # --- TAMBAHKAN INI ---
   table_calendar: ^3.1.2
   ```

Contoh struktur:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Package yang sudah ada
  fl_chart: ^0.68.0
  cupertino_icons: ^1.0.8
  http: ^1.5.0
  flutter_secure_storage: ^9.2.4
  intl: ^0.20.2
  google_sign_in: ^6.2.1
  googleapis: ^13.1.0 
  extension_google_sign_in_as_googleapis_auth: ^2.0.7

  # --- TAMBAHKAN INI ---
  table_calendar: ^3.1.2
```

Setelah itu, **simpan file** (`Ctrl+S` / `Cmd+S`). VS Code biasanya akan menjalankan `flutter pub get` secara otomatis.

---

## 12.2 Aktivasi Google Calendar API (Wajib untuk Integrasi Calendar)

Agar akses Google Calendar tidak menghasilkan error seperti:

> **403 Forbidden – Calendar API has not been used in project**

Anda harus mengaktifkan API-nya di Google Cloud Console.

### Langkah-langkah:

1. Buka **Google Cloud Console**.
2. Pilih project yang sama dengan yang Anda gunakan untuk **Google Sign-In** aplikasi ini.
3. Masuk ke menu:
   ```
   APIs & Services → Library
   ```
4. Pada kolom pencarian, ketik:
   ```
   Google Calendar API
   ```
5. Klik hasil yang muncul, lalu tekan tombol:
   ```
   ENABLE
   ```
6. (Opsional namun direkomendasikan)  
   Pada menu:
   ```
   APIs & Services → OAuth Consent Screen
   ```
   Tambahkan scope berikut jika diinginkan:
   ```
   /auth/calendar.events
   ```

Untuk mode pengembangan (Developer Mode), biasanya cukup **mengaktifkan** Calendar API saja.

---

## 13. Setup & Troubleshooting Lanjutan (Profil & Kamera)

Bagian ini mencakup konfigurasi tambahan untuk fitur **Edit Profil**, termasuk akses kamera, galeri, izin Android/iOS, serta update SDK yang diperlukan agar aplikasi berjalan tanpa error.

---

### 13.1 Update Dependency di pubspec.yaml

Pastikan package berikut sudah ditambahkan untuk fitur foto profil:

```yaml
dependencies:
  image_picker: ^1.2.1        # Mengambil gambar dari kamera/galeri
  permission_handler: ^12.0.1 # Mengelola izin kamera/galeri
```

Jalankan:

```bash
flutter pub get
```

---

### 13.2 Konfigurasi Izin Android (AndroidManifest.xml)

Agar aplikasi tidak crash saat mengambil gambar dari kamera atau membuka galeri, tambahkan izin berikut pada:

```
android/app/src/main/AndroidManifest.xml
```

Tambahkan di **atas** tag `<application ...>`:

```xml
<manifest ...>

    <!-- IZIN KAMERA & GALERI -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false" />

    <!-- Untuk akses galeri tergantung versi Android -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

    <application ...>
```

Catatan:  
Android 13+ menggunakan `READ_MEDIA_IMAGES` menggantikan `READ_EXTERNAL_STORAGE`.

---

### 13.3 Update Versi Android SDK (build.gradle)

Package modern seperti `image_picker` memerlukan Android SDK terbaru.

Buka:

```
android/app/build.gradle
```

Pastikan nilai berikut:

```gradle
android {
    namespace = "com.example.todome"
    compileSdk = 36     // WAJIB 35 atau 36

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // WAJIB 35 atau 36
    }
}
```

Jika tidak dinaikkan, aplikasi bisa:

- crash saat membuka kamera,
- gagal build,
- menampilkan error “Manifest merger failed”.

---

### 13.4 Konfigurasi iOS (Info.plist)

Jika menjalankan aplikasi di iOS (device/simulator), Anda harus menambahkan izin di:

```
ios/Runner/Info.plist
```

Tambahkan:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi membutuhkan akses galeri untuk memilih foto profil.</string>

<key>NSCameraUsageDescription</key>
<string>Aplikasi membutuhkan akses kamera untuk mengambil foto profil baru.</string>
```

Jika izin ini tidak ada, aplikasi akan langsung crash pada iOS.

---

### 13.5 Troubleshooting: Kamera Emulator Error

Jika kamera di Android Emulator menampilkan layar hitam, freeze, atau crash:

#### Solusi:
1. Buka **Device Manager** di Android Studio  
2. Klik ikon **Edit (Pencil)** pada emulator  
3. Klik **Show Advanced Settings**  
4. Pada bagian **Camera**:
   - Ubah **Front Camera** → `Webcam0` atau `Emulated`
   - Ubah **Back Camera** → `Webcam0` atau `Emulated`
5. Klik **Finish**
6. Lakukan **Cold Boot Now** pada emulator

Emulator default memang sering gagal membaca kamera laptop atau virtual device.

---



