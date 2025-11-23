import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart'; // Tambahkan import ini

class GoogleAuthService {
  // Tambahkan scope CalendarApi.calendarEventsScope
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      CalendarApi.calendarEventsScope, // <--- INI PENTING: Izin tulis kalender
    ],
  );

  // Getter untuk mengambil instance google sign in (dibutuhkan nanti oleh CalendarService)
  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        print("Sukses Login Google: ${account.email}");
      }
      return account;
    } catch (error) {
      print("Gagal Login Google: $error");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }
}