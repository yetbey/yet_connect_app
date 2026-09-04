import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

class Validators {
  // Regex Tanımları
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~.]).{8,}$',
  );
  // Açıklama: En az 1 Büyük harf, 1 Küçük harf, 1 Rakam, 1 Özel karakter ve min 8 karakter.

  static final RegExp _usernameRegExp = RegExp(
    r'^[a-zA-Z0-9_]+$',
  );
  // Açıklama: Sadece harf, rakam ve alt çizgi. Boşluk yok.

  // --- VALIDATORS ---

  // 1. İsim Soyisim Doğrulama
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validation_required_field.tr();
    }
    if (value.trim().length < 3) {
      return LocaleKeys.validation_name_min_length.tr();
    }
    // Sadece harf ve boşluk kontrolü
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ ]+$').hasMatch(value)) {
      return LocaleKeys.validation_invalid_name.tr();
    }
    return null;
  }

  // 2. Email Doğrulama
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validation_email_required.tr();
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return LocaleKeys.validation_invalid_email.tr();
    }
    return null;
  }

  // 3. Şifre Doğrulama (Güçlü Şifre)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validation_password_required.tr();
    }
    if (value.length < 8) {
      return LocaleKeys.validation_password_min_length.tr();
    }
    if (!_passwordRegExp.hasMatch(value)) {
      return 'Şifre en az 1 büyük harf, 1 rakam ve 1 özel karakter içermelidir.';
      // Bunu LocaleKeys'e eklemelisin: validation_password_complexity
    }
    return null;
  }

  // 4. Telefon Numarası Doğrulama
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validation_phone_required.tr();
    }
    // Boşlukları temizle
    final String cleanPhone = value.replaceAll(' ', '');

    // Sadece rakam içerdiğinden emin ol
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return LocaleKeys.validation_invalid_phone.tr();
    }

    // Uzunluk kontrolü (Ülkeye göre değişir ama genelde 10-11 hanedir)
    if (cleanPhone.length < 10 || cleanPhone.length > 13) {
      return LocaleKeys.validation_invalid_phone.tr();
    }
    return null;
  }

  // 5. Kullanıcı Adı Doğrulama
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${LocaleKeys.auth_username.tr()} ${LocaleKeys.validation_required.tr()}';
    }
    if (value.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır.';
    }
    if (!_usernameRegExp.hasMatch(value)) {
      return 'Kullanıcı adı sadece harf, rakam ve alt çizgi (_) içerebilir.';
    }
    return null;
  }
}