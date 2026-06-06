class ApiConstants {
  // ─── LOCAL DEV ───────────────────────────────────────────────────────────
  // Android can't use 'localhost' — use your PC's LAN IP instead.
  // If the app can't connect, try 192.168.194.115 (check ipconfig on your PC).
  // static const String baseUrl = 'http://192.168.194.115:3000';

  // ─── PRODUCTION (uncomment when deploying) ───────────────────────────────
  static const String baseUrl = 'https://apinparking.cohtek.com';

  static const String apiBaseUrl = '$baseUrl/api';
}
