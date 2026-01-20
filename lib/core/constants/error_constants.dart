class ErrorConstants {
  /// General
  static const String success = 'Başarılı';
  static const String error = 'Hata';

  /// Posts
  static const String updatePostSuccess = 'Gönderi güncellendi.';
  static const String updatePostUnsuccessMessage =
      'Gönderi güncellenirken bir sorun oluştu.';
  static const String updatePostUnsuccess = 'Gönderi güncelleme hatası';
  static const String createPostUnsuccess = 'Gönderi oluşturma hatası';
  static const String createPostUnsuccessMessage =
      'Gönderi paylaşılırken bir hata oluştu';
  static const String uniqueError = 'Tekil gönderi getirme hatası';
  static const String fetchUserError = 'Kullanıcı gönderilerini getirme hatası';
  static const String fetchAllPostsError = 'Hata - fetchAllPosts';
  static const String addCaptionImage = 'Lütfen bir metin veya görsel ekleyin!';
  static const String successShare = 'Gönderi paylaşıldı';
  static const String deleteSuccess = 'Gönderi başarıyla silindi.';
  static const String deleteUnsuccess = 'Gönderi silme hatası';
  static const String deleteUnsuccessMessage =
      'Gönderi silinirken bir sorun oluştu.';
  static const String loadPostUnsuccess = 'Gönderi Yüklenemedi';

  /// Comments
  static const String getCommentsError =
      'Gönderi güncellenirken bir sorun oluştu.';
  static const String addCommentError = 'Yorum ekleme hatası';
  static const String getCommentError = 'Yorumları getirme hatası';
  static const String addCommentUnsuccess =
      'Yorum eklenirken bir sorun oluştu.';
}
