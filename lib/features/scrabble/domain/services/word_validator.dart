// lib/features/scrabble/domain/services/word_validator.dart

class WordValidator {
  // Türkçe kelime sözlüğü (basitleştirilmiş - gerçek projede API kullanın)
  static final Set<String> _turkishWords = {
    'KEDİ', 'KÖPEK', 'EV', 'MASA', 'SANDALYE', 'OKUL', 'KİTAP',
    'KALEM', 'DEFTER', 'ARABA', 'UÇAK', 'GEMİ', 'TREN', 'OTOBÜS',
    'TELEFON', 'BİLGİSAYAR', 'TABLET', 'OYUN', 'SPOR', 'MÜZİK',
    'ŞARKI', 'DANS', 'RESİM', 'FİLM', 'GAZETE', 'DERGI',
    'YEMEK', 'İÇECEK', 'KAHVE', 'ÇAY', 'SU', 'MEYVE', 'SEBZE',
    'ET', 'BALIK', 'EKMEK', 'PEYNIR', 'YUMURTA', 'SÜT', 'YOĞURT',
    'BAL', 'REÇEL', 'TEREYAĞI', 'ZEYTİN', 'BİBER', 'DOMATES',
    // ... daha fazla kelime ekleyin
  };

  /// Kelime geçerli mi kontrol et
  static bool isValidWord(String word) {
    final normalized = word.toUpperCase().trim();

    // En az 2 harf olmalı
    if (normalized.length < 2) return false;

    // Sözlükte var mı?
    return _turkishWords.contains(normalized);
  }

  /// Birden fazla kelime kontrol et
  static List<String> validateWords(List<String> words) {
    return words.where((word) => isValidWord(word)).toList();
  }

  /// Geçersiz kelimeleri bul
  static List<String> findInvalidWords(List<String> words) {
    return words.where((word) => !isValidWord(word)).toList();
  }
}
