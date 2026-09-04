import 'package:yet_x_app/features/scrabble/data/models/game_room.dart';
import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import '../models/game_move.dart';

/// ⚠️ GEÇİCİ STUB: Bu repository daha önce Firebase Realtime Database
/// kullanıyordu. Firebase projeden kaldırıldığı için derleme hatası
/// vermesin diye metotlar geçici olarak devre dışı bırakıldı.
///
/// TODO: Scrabble'ı Supabase Realtime + `scrabble_rooms`/`scrabble_chat`
/// tabloları üzerinden baştan yaz. Bu dosya o zamana kadar Scrabble
/// ekranlarının açılmasını engellemez ama oyun işlevsel olmaz.
class ScrabbleRepository {
  Future<GameRoom> createRoom({
    required String hostId,
    required int maxPlayers,
  }) async {
    LogService.w('⚠️ ScrabbleRepository.createRoom devre dışı (Firebase kaldırıldı)');
    throw UnimplementedError(
      'Scrabble şu an Supabase\'e taşınıyor, geçici olarak kullanılamıyor.',
    );
  }

  Future<GameRoom> joinRoom({
    required String roomId,
    required String playerId,
  }) async {
    LogService.w('⚠️ ScrabbleRepository.joinRoom devre dışı (Firebase kaldırıldı)');
    throw UnimplementedError(
      'Scrabble şu an Supabase\'e taşınıyor, geçici olarak kullanılamıyor.',
    );
  }

  Future<void> startGame(String roomId) async {
    LogService.w('⚠️ ScrabbleRepository.startGame devre dışı (Firebase kaldırıldı)');
    throw UnimplementedError(
      'Scrabble şu an Supabase\'e taşınıyor, geçici olarak kullanılamıyor.',
    );
  }

  Future<void> makeMove({
    required String roomId,
    required String playerId,
    required List<dynamic> placedTiles,
    required String word,
    required int score,
  }) async {
    LogService.w('⚠️ ScrabbleRepository.makeMove devre dışı (Firebase kaldırıldı)');
    throw UnimplementedError(
      'Scrabble şu an Supabase\'e taşınıyor, geçici olarak kullanılamıyor.',
    );
  }

  Stream<GameRoom?> watchRoom(String roomId) {
    LogService.w('⚠️ ScrabbleRepository.watchRoom devre dışı (Firebase kaldırıldı)');
    return const Stream.empty();
  }

  Future<List<GameRoom>> getActiveRooms() async {
    LogService.w('⚠️ ScrabbleRepository.getActiveRooms devre dışı (Firebase kaldırıldı)');
    return [];
  }

  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    LogService.w('⚠️ ScrabbleRepository.leaveRoom devre dışı (Firebase kaldırıldı)');
  }
}