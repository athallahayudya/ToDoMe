import 'package:googleapis/calendar/v3.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:todome/services/google_auth_service.dart';
import '../models/task.dart';

class CalendarService {
  final GoogleAuthService _authService = GoogleAuthService();

  Future<bool> insertTaskToCalendar(Task task) async {
    try {
      // 1. Cek apakah user sudah login Google
      var googleSignIn = _authService.googleSignIn;
      var account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();

      if (account == null) {
        print("User belum login Google");
        return false;
      }

      // 2. Dapatkan Authenticated Client (Jembatan Flutter ke Google API)
      // Ini butuh package 'extension_google_sign_in_as_googleapis_auth' di pubspec.yaml
      final httpClient = await googleSignIn.authenticatedClient();
      
      if (httpClient == null) {
        print("Gagal mendapatkan auth client");
        return false;
      }

      // 3. Inisialisasi API Kalender
      final calendarApi = CalendarApi(httpClient);

      // 4. Siapkan Data Event
      // Jika deadline null, kita pakai waktu sekarang + 1 jam (sebagai default)
      final startTime = task.deadline ?? DateTime.now();
      final endTime = startTime.add(const Duration(hours: 1)); // Durasi default 1 jam

      final event = Event(
        summary: task.judul, // Judul di Kalender
        description: task.deskripsi ?? "Tugas dari ToDoMe", // Deskripsi
        start: EventDateTime(
          dateTime: startTime.toUtc(), // Wajib UTC atau sertakan timeZone
          timeZone: "Asia/Jakarta", // Sesuaikan dengan target user
        ),
        end: EventDateTime(
          dateTime: endTime.toUtc(),
          timeZone: "Asia/Jakarta",
        ),
      );

      // 5. Kirim ke Kalender 'primary' (Kalender utama user)
      final value = await calendarApi.events.insert(event, "primary");
      
      print("Berhasil simpan ke kalender. ID Event: ${value.id}");
      return true;

    } catch (e) {
      print("Error Calendar Service: $e");
      return false;
    }
  }
}