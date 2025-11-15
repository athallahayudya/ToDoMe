# -------------------------------
# Catatan Setup Frontend (todome)
# -------------------------------

Ini adalah project frontend (Flutter) untuk aplikasi mobile ToDoMe.
Aplikasi ini terhubung ke `todome_backend` (API Laravel) untuk semua data.

## 1. Persyaratan Environment (Wajib)

Pastikan environment Anda memenuhi syarat berikut:
* **Flutter SDK:** Terinstal (rekomendasi versi 3.x.x atau lebih baru).
* **IDE:** VS Code (dengan ekstensi Flutter) atau Android Studio.
* **Emulator:** Android Virtual Device (AVD) yang sudah disiapkan melalui Android Studio, atau perangkat HP fisik.
* **Backend:** Project `todome_backend` **WAJIB** berjalan di Laragon (`php artisan serve`).

## 2. Langkah Instalasi

Langkah-langkah ini untuk menjalankan project di komputer baru.

1.  **Clone Repository:**
    ```bash
    git clone [https://github.com/SeptianTito123/todome.git](https://github.com/SeptianTito123/todome.git)
    cd todome
    ```

2.  **Install Dependencies (Flutter):**
    * Unduh semua *package* Dart/Flutter yang diperlukan.
    * Ini adalah "composer install"-nya Flutter.
    ```bash
    # Catatan: Menginstal semua dependensi dari pubspec.yaml
    flutter pub get
    ```

3.  **Jalankan Backend Server:**
    * Pastikan server Laravel (`todome_backend`) Anda berjalan di terminal lain.
    ```bash
    # Di C:\laragon\www\todome_backend
    php artisan serve
    ```

4.  **Jalankan Aplikasi Flutter:**
    * Pastikan Emulator Anda sudah menyala.
    * Pastikan VS Code mendeteksi emulator Anda (di pojok kanan bawah).
    * Tekan `F5` di VS Code atau jalankan perintah:
    ```bash
    flutter run
    ```

## 3. PENTING: Koneksi ke Backend (API)

Alamat IP Backend (API) diatur di satu tempat.

* **File:** `lib/services/api_service.dart`
* **Variabel:** `_baseUrl`

**Aturan Alamat IP:**
* Jika Anda menjalankan di **Emulator Android**, IP **WAJIB**:
    `"http://10.0.2.2:8000/api"`
    (10.0.2.2 adalah alamat "ajaib" dari dalam Emulator untuk merujuk ke `localhost` komputer Anda).

* Jika Anda menjalankan di **iOS Simulator** atau **Windows Desktop/Web**, gunakan:
    `"http://127.0.0.1:8000/api"`

File `api_service.dart` saat ini sudah diatur untuk mendeteksi Android secara otomatis.

## 4. Package Utama yang Digunakan

* **`http`:**
    * Digunakan untuk semua komunikasi API (GET, POST, PUT, DELETE) ke backend Laravel.

* **`flutter_secure_storage`:**
    * Digunakan untuk menyimpan **`access_token`** (dari Login) secara aman dan terenkripsi di dalam HP.
    * Token ini kemudian otomatis dilampirkan di setiap *request* API yang aman.

## 5. Struktur Folder (Penting)

* `lib/screens/`
    * Berisi semua "Halaman" atau "Wajah" (UI) aplikasi, seperti `login_screen.dart`, `register_screen.dart`, `home_screen.dart`.

* `lib/services/`
    * Berisi "Otak" logika bisnis.
    * `api_service.dart`: Satu-satunya file yang bertanggung jawab berbicara dengan API Laravel.

* `lib/models/`
    * Berisi "Cetakan" (blueprint) data, seperti `task.dart`. (Akan kita tambahkan `category.dart`, `user.dart` nanti).