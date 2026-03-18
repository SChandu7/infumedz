import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        "403601886832-na6gh8s11lijfpu9v9e0r1668em3720a.apps.googleusercontent.com",
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print("🚀 Starting Google Sign-In...");
      await _googleSignIn.signOut();

      // Step 1: Open Google popup
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      print("👤 Account selected: $account");

      if (account == null) {
        print("❌ User cancelled login");
        return {"error": "User cancelled"};
      }

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;

      print("🔐 Access Token: ${auth.accessToken}");
      print("🆔 ID Token: ${auth.idToken}");

      final idToken = auth.idToken;

      if (idToken == null) {
        print("❌ ID Token is NULL");
        return {"error": "No ID token"};
      }

      // Step 3: Send to backend
      print("📡 Sending token to backend...");

      final response = await http.post(
        Uri.parse("https://api.chandus7.in/api/infumedz/googleauth/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token": idToken}),
      );

      print("📥 Backend response status: ${response.statusCode}");
      print("📥 Backend response body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ Login successful");
        return data;
      } else {
        print("❌ Backend error: ${data["error"]}");
        return {"error": data["error"]};
      }
    } catch (e) {
      print("🔥 ERROR OCCURRED: $e");
      return {"error": e.toString()};
    }
  }
}
