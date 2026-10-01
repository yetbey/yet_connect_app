import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PasswordBreachChecker {
  static Future<bool> isBreached(String password) async {
    try{
      final digest = sha1.convert(utf8.encode(password)).toString().toUpperCase();
      final prefix = digest.substring(0, 5);
      final suffix = digest.substring(5);
      
      final res = await http.get(
        Uri.parse('https://api.pwnedpasswords.com/range/$prefix'),
        headers: {'Add-Padding': 'true'},
      ).timeout(const Duration(seconds: 4));
      
      if (res.statusCode != 200) return false;
      
      for (final line in res.body.split('\n')) {
        final parts = line.trim().split(':');
        if (parts.length == 2 && parts[0] == suffix) {
          return (int.tryParse(parts[1]) ?? 0) > 0;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}