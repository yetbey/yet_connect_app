class UrlHelper {
  /// Supabase Storage URL'ini normalize et (query string'leri temizle)
  static String normalizeSupabaseUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    try {
      final uri = Uri.parse(url);

      // Supabase storage URL'i değilse olduğu gibi dön
      if (!uri.host.contains('supabase')) return url;

      // Query parametrelerini temizle (timestamp gibi)
      return Uri(scheme: uri.scheme, host: uri.host, path: uri.path).toString();
    } catch (e) {
      return url;
    }
  }
}
