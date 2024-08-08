import 'package:shared_preferences/shared_preferences.dart';

class LoginCache {
  static final LoginCache _instance = LoginCache._internal();
  factory LoginCache() => _instance; // Factory constructor to return the same instance

  LoginCache._internal(); // Private constructor
  static const _email = 'emailKey';
  static const _pw = 'passwordKey';
  static const _fn = 'fnKey';
  static const _ln = 'lnKey';
  static const _signedIn = 'signedIn';

    Future<void> setSignedIn(bool str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedIn, str);
  }

  Future<bool> getSignedIn() async {
     final prefs = await SharedPreferences.getInstance();
     final signedIn = prefs.getBool(_signedIn);
     return signedIn ?? false;
  }

  Future<void> setEmail(String str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_email, str);
  }

  Future<String> getEmail() async {
     final prefs = await SharedPreferences.getInstance();
     final email = prefs.getString(_email);
     return email ?? '';
  }

    Future<void> setPW(String str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pw, str);
  }

  Future<String> getPW() async {
     final prefs = await SharedPreferences.getInstance();
     final pw = prefs.getString(_pw);
     return pw ?? '';
  }

    Future<void> setFN(String str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fn, str);
  }

  Future<String> getFN() async {
     final prefs = await SharedPreferences.getInstance();
     final fn = prefs.getString(_fn);
     return fn ?? '';
  }

    Future<void> setLN(String str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ln, str);
  }

  Future<String> getLN() async {
     final prefs = await SharedPreferences.getInstance();
     final ln = prefs.getString(_ln);
     return ln ?? '';
  }
}
