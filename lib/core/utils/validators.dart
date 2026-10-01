import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

class Validators {
  Validators._();

  static const int passwordMinLength = 8;
  static const int passwordMaxBytes = 72;
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const int nameMinLength = 2;
  static const int nameMaxLength = 50;
  static const int otpLength = 8;

  static final RegExp _emailRegExp = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );
  static final RegExp _upper = RegExp(r'\p{Lu}', unicode: true);
  static final RegExp _lower = RegExp(r'\p{Ll}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);
  static final RegExp _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final RegExp _nameRegExp =
  RegExp(r"^\p{L}[\p{L} '’.\-]*$", unicode: true);
  static final RegExp _usernameChars = RegExp(r'^[a-z0-9_]+$');

  static const Set<String> _reservedUsernames = {
    'admin', 'administrator', 'root', 'support', 'help', 'moderator', 'mod',
    'system', 'official', 'yet', 'yetconnect', 'yet_connect', 'api', 'www',
    'null', 'undefined', 'settings', 'login', 'register', 'security',
  };

  static String _required(String label) =>
      LocaleKeys.validation_required_field.tr(args: [label]);

  static String? name(String? value) {
    final v = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v.isEmpty) return _required(LocaleKeys.auth_full_name.tr());
    if (v.runes.length < nameMinLength) {
      return LocaleKeys.validation_name_min_length.tr();
    }
    if (v.runes.length > nameMaxLength) {
      return LocaleKeys.validation_name_max_length.tr();
    }
    if (!_nameRegExp.hasMatch(v)) return LocaleKeys.validation_invalid_name.tr();
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return LocaleKeys.validation_email_required.tr();
    final invalid = LocaleKeys.validation_invalid_email.tr();
    if (v.length > 254 || !_emailRegExp.hasMatch(v)) return invalid;

    final at = v.lastIndexOf('@');
    final local = v.substring(0, at);
    final domain = v.substring(at + 1);
    if (local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return invalid;
    }
    final tld = domain.split('.').last;
    if (tld.length < 2 || RegExp(r'^\d+$').hasMatch(tld)) return invalid;
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validation_password_required.tr();
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validation_password_required.tr();
    }
    if (value.length < passwordMinLength) {
      return LocaleKeys.validation_password_min_length.tr();
    }
    if (utf8.encode(value).length > passwordMaxBytes) {
      return LocaleKeys.validation_password_max_length.tr();
    }
    final ok = _upper.hasMatch(value) &&
        _lower.hasMatch(value) &&
        _digit.hasMatch(value) &&
        _symbol.hasMatch(value);
    if (!ok) return LocaleKeys.validation_password_complexity.tr();
    return null;
  }

  static String? Function(String?) newPassword({
    required String Function() currentPassword,
  }) {
    return (value) {
      final error = password(value);
      if (error != null) return error;
      if (value == currentPassword()) {
        return LocaleKeys.validation_password_same_as_current.tr();
      }
      return null;
    };
  }

  static String? Function(String?) confirmPassword(
      String Function() original,
      ) {
    return (value) {
      if (value == null || value.isEmpty) {
        return LocaleKeys.auth_confirm_new_password.tr();
      }
      if (value != original()) return LocaleKeys.auth_passwords_not_match.tr();
      return null;
    };
  }

  static String? normalizePhone(String? value) {
    if (value == null) return null;
    var p = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.isEmpty) return null;
    if (p.startsWith('00')) p = '+${p.substring(2)}';

    if (p.startsWith('+')) {
      final digits = p.substring(1);
      return RegExp(r'^[1-9]\d{7,14}$').hasMatch(digits) ? '+$digits' : null;
    }
    if (!RegExp(r'^\d+$').hasMatch(p)) return null;

    if (p.startsWith('90') && p.length == 12) {
      p = p.substring(2);
    } else if (p.startsWith('0') && p.length == 11) {
      p = p.substring(1);
    }
    return RegExp(r'^5\d{9}$').hasMatch(p) ? '+90$p' : null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validation_phone_required.tr();
    }
    if (normalizePhone(value) == null) {
      return LocaleKeys.validation_invalid_phone.tr();
    }
    return null;
  }

  static String? username(String? value) {
    final v = value ?? '';
    if (v.trim().isEmpty) return LocaleKeys.validation_username_required.tr();
    if (v.length < usernameMinLength) {
      return LocaleKeys.validation_username_min_length.tr();
    }
    if (v.length > usernameMaxLength) {
      return LocaleKeys.validation_username_max_length.tr();
    }
    if (!_usernameChars.hasMatch(v)) {
      return LocaleKeys.validation_username_invalid_chars.tr();
    }
    if (!RegExp(r'^[a-z]').hasMatch(v)) {
      return LocaleKeys.validation_username_must_start_with_letter.tr();
    }
    if (v.endsWith('_') || v.contains('__')) {
      return LocaleKeys.validation_username_invalid_underscore.tr();
    }
    if (_reservedUsernames.contains(v)) {
      return LocaleKeys.validation_username_reserved.tr();
    }
    return null;
  }

  static String? Function(String?) otp({int length = otpLength}) {
    return (value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) return LocaleKeys.validation_otp_required.tr();
      if (!RegExp(r'^\d+$').hasMatch(v) || v.length != length) {
        return LocaleKeys.validation_otp_invalid_length
            .tr(args: [length.toString()]);
      }
      return null;
    };
  }
}