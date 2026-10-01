import 'package:flutter/services.dart';

TextEditingValue _withText(TextEditingValue base, String text, int offset) {
  final safe = offset.clamp(0, text.length);
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: safe),
  );
}

String _trLower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
String _trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

class TitleCaseFormatter extends TextInputFormatter {
  final bool turkish;
  TitleCaseFormatter({this.turkish = true});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;

    String lower(String s) => turkish ? _trLower(s) : s.toLowerCase();
    String upper(String s) => turkish ? _trUpper(s) : s.toUpperCase();

    final text = newValue.text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return upper(word.substring(0, 1)) + lower(word.substring(1));
    }).join(' ');

    if (text == newValue.text) return newValue;
    return _withText(newValue, text, newValue.selection.extentOffset);
  }
}

class LowerCaseFormatter extends TextInputFormatter {
  LowerCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('İ', 'i').toLowerCase();
    if (text == newValue.text) return newValue;
    return _withText(newValue, text, newValue.selection.extentOffset);
  }
}

class NoSpaceFormatter extends TextInputFormatter {
  NoSpaceFormatter();

  static final RegExp _ws = RegExp(r'\s');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;
    if (!text.contains(_ws)) return newValue;

    final cleaned = text.replaceAll(_ws, '');
    final cursor = newValue.selection.extentOffset;
    final before = cursor < 0
        ? cleaned.length
        : text
        .substring(0, cursor.clamp(0, text.length))
        .replaceAll(_ws, '')
        .length;
    return _withText(newValue, cleaned, before);
  }
}