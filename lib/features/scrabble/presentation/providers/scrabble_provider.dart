

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/scrabble/data/models/game_move.dart';
import 'package:yet_x_app/features/scrabble/data/models/game_room.dart';
import 'package:yet_x_app/features/scrabble/data/repositories/scrabble_repository.dart';

final scrabbleRepositoryProvider = Provider((ref) => ScrabbleRepository());

class ScrabbleState {
  final GameRoom? currentRoom;
  final bool isLoading;
  final String? error;
  final List<GameRoom> availableRooms;

  const ScrabbleState({
    this.currentRoom,
    this.isLoading = false,
    this.error,
    this.availableRooms = const [],
});

  ScrabbleState copyWith({
    GameRoom? currentRoom,
    bool? isLoading,
    String? error,
    List<GameRoom>? availableRooms,
}) {
    return ScrabbleState(
      currentRoom: currentRoom ?? this.currentRoom,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      availableRooms: availableRooms ?? this.availableRooms,
    );
  }
}

class ScrabbleNotifier extends Notifier<ScrabbleState> {
  late final ScrabbleRepository _repository;

  @override
  ScrabbleState build() {
    _repository = ref.read(scrabbleRepositoryProvider);
    return const ScrabbleState();
  }

  // ============================================================================
  // ODA OLUŞTURMA
  // ============================================================================

  Future<String?> createRoom({
    required String userId,
    required int maxPlayers,
}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
     final room = await _repository.createRoom(hostId: userId, maxPlayers: maxPlayers);

     state = state.copyWith(currentRoom: room, isLoading: false);

     // Odayı dinlemeyi başlat
      _listenToRoom(room.id);

      LogService.i('Oda oluşturuldu: ${room.id}');
      return room.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Oda oluşturulamadı: $e',
      );
      LogService.e('❌ Oda oluşturma hatası', e);
      return null;
    }
  }

  // ============================================================================
  // ODAYA KATILMA
  // ============================================================================

  Future<bool> joinRoom({
    required String roomId,
    required String userId,
}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final room = await _repository.joinRoom(roomId: roomId, playerId: userId);

      state = state.copyWith(currentRoom: room, isLoading: false);

      _listenToRoom(room.id);

      LogService.i('Odaya Katıldı: $roomId');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Odaya katılınamadı: $e',
      );
      LogService.e('❌ Odaya katılma hatası', e);
      return false;
    }
  }

  // ============================================================================
  // OYUNU BAŞLATMA
  // ============================================================================

  Future<void> startGame() async {
    if (state.currentRoom == null) return;

    try {
      await _repository.startGame(state.currentRoom!.id);
      LogService.i('Oyun Basşlatıldı ...');
    } catch (e) {
      state = state.copyWith(error: 'Oyun başlatılamadı: $e');
      LogService.e('❌ Oyun başlatma hatası', e);
    }
  }

  // ============================================================================
  // HAMLE YAPMA
  // ============================================================================

  Future<bool> makeMove({
    required String userId,
    required List<PlacedTile> placedTiles,
    required String word,
    required int score,
}) async {
    if (state.currentRoom == null) return false;

    try {
      await _repository.makeMove(roomId: state.currentRoom!.id, playerId: userId, placedTiles: placedTiles, word: word, score: score);
      LogService.i('✅ Hamle yapıldı: $word ($score puan)');
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Hamle yapılamadı: $e');
      LogService.e('❌ Hamle yapma hatası', e);
      return false;
    }
  }

  // ============================================================================
  // AKTİF ODALARI YÜKLEME
  // ============================================================================

  Future<void> loadAvailableRooms() async {
    state = state.copyWith(isLoading: true);

    try {
      final rooms = await _repository.getActiveRooms();
      state = state.copyWith(
        availableRooms: rooms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Odalar yüklenemedi: $e',
      );
      LogService.e('❌ Oda listesi hatası', e);
    }
  }

  // ============================================================================
  // ODADAN AYRILMA
  // ============================================================================

  Future<void> leaveRoom(String userId) async {
    if (state.currentRoom == null) return;

    try {
      await _repository.leaveRoom(roomId: state.currentRoom!.id, playerId: userId);

      state = state.copyWith(currentRoom: null);
      LogService.i('✅ Odadan ayrıldı');
    } catch (e) {
      LogService.e('❌ Odadan ayrılma hatası', e);
    }
  }

  // ============================================================================
  // REALTIME DİNLEME
  // ============================================================================

  void _listenToRoom(String roomId) {
    _repository.watchRoom(roomId).listen((room) {
      if (room != null) {
        state = state.copyWith(currentRoom: room);
      }
    });
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final scrabbleProvider = NotifierProvider<ScrabbleNotifier, ScrabbleState>(
      () => ScrabbleNotifier(),
);