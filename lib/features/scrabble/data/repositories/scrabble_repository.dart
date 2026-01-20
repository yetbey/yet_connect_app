import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:yet_x_app/features/scrabble/data/models/game_room.dart';
import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/game_move.dart';

class ScrabbleRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yet-x-app-default-rtdb.europe-west1.firebasedatabase.app',
  );

  // Rooms referansı
  DatabaseReference get _roomsRef => _database.ref('scrabble_rooms');

  // ============================================================================
  // ODA OLUŞTURMA
  // ============================================================================

  Future<GameRoom> createRoom({
    required String hostId,
    required int maxPlayers,
  }) async {
    try {
      final roomRef = _roomsRef.push();
      final roomId = roomRef.key!;

      // Boş tahta oluştur
      final board = ScrabbleConstants.createEmptyBoard();

      // Tile bag oluştur (harfleri karıştır)
      final tileBag = ScrabbleConstants.generateTileBag();

      // Host için harfler çek
      final hostRack = <String>[];
      for (int i = 0; i < 7 && tileBag.isNotEmpty; i++) {
        hostRack.add(tileBag.removeAt(0));
      }

      final room = GameRoom(
        id: roomId,
        hostId: hostId,
        playerIds: [hostId],
        maxPlayers: maxPlayers,
        status: GameStatus.waiting, // ✅ ready değil, waiting
        currentTurnPlayerId: null,
        board: board,
        scores: {hostId: 0},
        playerRacks: {hostId: hostRack},
        tileBag: tileBag, // ✅ remainingTiles değil, tileBag
        moves: [],
        createdAt: DateTime.now(),
      );

      await roomRef.set(room.toJson());

      LogService.i('✅ Scrabble odası oluşturuldu: $roomId');
      return room;
    } catch (e) {
      LogService.e('❌ Oda oluşturma hatası', e);
      rethrow;
    }
  }

  // ============================================================================
  // ODAYA KATILMA
  // ============================================================================

  Future<GameRoom> joinRoom({
    required String roomId,
    required String playerId,
  }) async {
    try {
      final roomRef = _roomsRef.child(roomId);
      final snapshot = await roomRef.get();

      if (!snapshot.exists) {
        throw Exception('Oda bulunamadı');
      }

      final roomData = Map<String, dynamic>.from(snapshot.value as Map);
      roomData['id'] = roomId;
      final room = GameRoom.fromJson(roomData);

      // Oda dolu mu?
      if (room.playerIds.length >= room.maxPlayers) {
        throw Exception('Oda dolu');
      }

      // Zaten odada mı?
      if (room.playerIds.contains(playerId)) {
        throw Exception('Zaten odadasınız');
      }

      // Oyuncu için harfler çek
      final playerRack = <String>[];
      final updatedTileBag = List<String>.from(room.tileBag); // ✅

      for (int i = 0; i < 7 && updatedTileBag.isNotEmpty; i++) {
        playerRack.add(updatedTileBag.removeAt(0));
      }

      // Güncellenmiş oda
      final updatedRoom = room.copyWith(
        playerIds: [...room.playerIds, playerId],
        scores: {...room.scores, playerId: 0},
        playerRacks: {...room.playerRacks, playerId: playerRack},
        tileBag: updatedTileBag, // ✅
      );

      await roomRef.update(updatedRoom.toJson());

      LogService.i('✅ Odaya katıldı: $playerId');
      return updatedRoom;
    } catch (e) {
      LogService.e('❌ Odaya katılma hatası', e);
      rethrow;
    }
  }

  // ============================================================================
  // OYUNU BAŞLATMA
  // ============================================================================

  Future<void> startGame(String roomId) async {
    try {
      final roomRef = _roomsRef.child(roomId);
      final snapshot = await roomRef.get();

      if (!snapshot.exists) {
        throw Exception('Oda bulunamadı');
      }

      final roomData = Map<String, dynamic>.from(snapshot.value as Map);
      roomData['id'] = roomId;
      final room = GameRoom.fromJson(roomData);

      // En az 2 oyuncu olmalı
      if (room.playerIds.length < 2) {
        throw Exception('Oyunu başlatmak için en az 2 oyuncu gerekli');
      }

      // İlk oyuncuyu seç (host)
      final updatedRoom = room.copyWith(
        status: GameStatus.playing,
        currentTurnPlayerId: room.hostId,
        startedAt: DateTime.now(),
      );

      await roomRef.update(updatedRoom.toJson());

      LogService.i('✅ Oyun başladı: $roomId');
    } catch (e) {
      LogService.e('❌ Oyun başlatma hatası', e);
      rethrow;
    }
  }

  // ============================================================================
  // HAMLE YAPMA
  // ============================================================================

  Future<void> makeMove({
    required String roomId,
    required String playerId,
    required List<PlacedTile> placedTiles,
    required String word,
    required int score,
  }) async {
    try {
      final roomRef = _roomsRef.child(roomId);
      final snapshot = await roomRef.get();

      if (!snapshot.exists) {
        throw Exception('Oda bulunamadı');
      }

      final roomData = Map<String, dynamic>.from(snapshot.value as Map);
      roomData['id'] = roomId;
      final room = GameRoom.fromJson(roomData);

      // Sıra kontrolü
      if (room.currentTurnPlayerId != playerId) {
        throw Exception('Sıra sizde değil');
      }

      // Tahtayı güncelle
      final updatedBoard = List<List<BoardCell>>.from(
        room.board.map((row) => List<BoardCell>.from(row)),
      );

      for (var tile in placedTiles) {
        updatedBoard[tile.row][tile.col] = BoardCell(
          row: tile.row,
          col: tile.col,
          letter: tile.letter,
          points: tile.points,
          multiplier: updatedBoard[tile.row][tile.col].multiplier,
        );
      }

      // Skoru güncelle
      final updatedScores = Map<String, int>.from(room.scores);
      updatedScores[playerId] = (updatedScores[playerId] ?? 0) + score;

      // Kullanılan harfleri raftan çıkar ve yeni harfler çek
      final playerRack = List<String>.from(room.playerRacks[playerId] ?? []);
      final updatedTileBag = List<String>.from(room.tileBag); // ✅

      for (var tile in placedTiles) {
        playerRack.remove(tile.letter);
      }

      // Yeni harfler çek
      while (playerRack.length < 7 && updatedTileBag.isNotEmpty) {
        playerRack.add(updatedTileBag.removeAt(0));
      }

      final updatedPlayerRacks = Map<String, List<String>>.from(room.playerRacks);
      updatedPlayerRacks[playerId] = playerRack;

      // Hamle kaydet
      final move = GameMove(
        playerId: playerId,
        placedTiles: placedTiles,
        word: word,
        score: score,
        timestamp: DateTime.now(),
      );

      final updatedMoves = [...room.moves, move];

      // Sıradaki oyuncu
      final currentIndex = room.playerIds.indexOf(playerId);
      final nextIndex = (currentIndex + 1) % room.playerIds.length;
      final nextPlayerId = room.playerIds[nextIndex];

      // Odayı güncelle
      final updatedRoom = room.copyWith(
        board: updatedBoard,
        scores: updatedScores,
        playerRacks: updatedPlayerRacks,
        tileBag: updatedTileBag, // ✅
        moves: updatedMoves,
        currentTurnPlayerId: nextPlayerId,
      );

      await roomRef.update(updatedRoom.toJson());

      LogService.i('✅ Hamle yapıldı: $word ($score puan)');
    } catch (e) {
      LogService.e('❌ Hamle yapma hatası', e);
      rethrow;
    }
  }

  // ============================================================================
  // ODA DİNLEME (REALTIME)
  // ============================================================================

  Stream<GameRoom?> watchRoom(String roomId) {
    return _roomsRef.child(roomId).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return GameRoom.fromJson(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  // ============================================================================
  // AKTİF ODALARI LİSTELEME
  // ============================================================================

  Future<List<GameRoom>> getActiveRooms() async {
    try {
      final snapshot = await _roomsRef.get();
      print('=== FIREBASE DATA DEBUG ===');
      print('Exists: ${snapshot.exists}');
      print('Value type: ${snapshot.value.runtimeType}');
      print('Value: ${snapshot.value}');
      print('========================');

      if (!snapshot.exists) {
        LogService.i('ℹ️ Hiç oda yok');
        return [];
      }

      final rooms = <GameRoom>[];
      final value = snapshot.value;

      // Null check
      if (value == null) {
        return [];
      }

      // Type check ve cast
      if (value is! Map) {
        LogService.e('❌ Beklenmeyen veri tipi: ${value.runtimeType}');
        return [];
      }

      final dataMap = Map<String, dynamic>.from(value as Map);

      // Her odayı parse et
      for (var entry in dataMap.entries) {
        try {
          final roomId = entry.key;
          final roomValue = entry.value;

          if (roomValue == null) continue;

          if (roomValue is! Map) {
            LogService.w('⚠️ Oda verisi Map değil: $roomId');
            continue;
          }

          final roomData = Map<String, dynamic>.from(roomValue as Map);

          // ID'yi ekle (Firebase'de key olarak tutuluyorsa)
          if (!roomData.containsKey('id')) {
            roomData['id'] = roomId;
          }

          final room = GameRoom.fromJson(roomData);

          // Sadece waiting status
          if (room.status == GameStatus.waiting) {
            rooms.add(room);
          }

        } catch (e, stack) {
          LogService.e('❌ Oda parse hatası: ${entry.key}', e);
          if (kDebugMode) {
            print('Stack: $stack');
            print('Value: ${entry.value}');
          }
          continue;
        }
      }

      LogService.i('✅ ${rooms.length} aktif oda bulundu');
      return rooms;

    } catch (e, stack) {
      LogService.e('❌ Oda listesi alma hatası', e);
      if (kDebugMode) {
        print('Stack: $stack');
      }
      return [];
    }
  }

  // ============================================================================
  // ODADAN AYRILMA
  // ============================================================================

  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    try {
      final roomRef = _roomsRef.child(roomId);
      final snapshot = await roomRef.get();

      if (!snapshot.exists) return;

      final roomData = Map<String, dynamic>.from(snapshot.value as Map);
      roomData['id'] = roomId;
      final room = GameRoom.fromJson(roomData);

      // Host ayrılıyorsa odayı sil
      if (room.hostId == playerId) {
        await roomRef.remove();
        LogService.i('✅ Oda silindi (host ayrıldı)');
        return;
      }

      // Oyuncuyu çıkar
      final updatedPlayerIds = room.playerIds.where((id) => id != playerId).toList();
      final updatedScores = Map<String, int>.from(room.scores)..remove(playerId);
      final updatedPlayerRacks = Map<String, List<String>>.from(room.playerRacks)..remove(playerId);

      // Harflerini geri koy
      final updatedTileBag = [...room.tileBag, ...?room.playerRacks[playerId]]; // ✅

      final updatedRoom = room.copyWith(
        playerIds: updatedPlayerIds,
        scores: updatedScores,
        playerRacks: updatedPlayerRacks,
        tileBag: updatedTileBag, // ✅
      );

      await roomRef.update(updatedRoom.toJson());

      LogService.i('✅ Oyuncu ayrıldı: $playerId');
    } catch (e) {
      LogService.e('❌ Odadan ayrılma hatası', e);
      rethrow;
    }
  }

  // ============================================================================
  // YARDIMCI FONKSİYONLAR
  // ============================================================================

  // Harf torbasını oluştur
  List<String> _generateTileBag() {
    final tiles = <String>[];
    ScrabbleConstants.letterCounts.forEach((letter, count) {
      tiles.addAll(List.filled(count, letter));
    });
    tiles.shuffle();
    return tiles;
  }

  // Torbadan harf çek
  List<String> _drawTiles(List<String> bag, int count) {
    final drawn = <String>[];
    final actualCount = count > bag.length ? bag.length : count;

    for (int i = 0; i < actualCount; i++) {
      drawn.add(bag.removeAt(0));
    }

    return drawn;
  }

  // Boş tahta oluştur
  List<List<BoardCell>> _createEmptyBoard() {
    final multipliers = ScrabbleConstants.getBoardMultipliers();
    return List.generate(
      ScrabbleConstants.boardSize,
          (row) => List.generate(
        ScrabbleConstants.boardSize,
            (col) => BoardCell(
          row: row,
          col: col,
          multiplier: multipliers[row][col],
        ),
      ),
    );
  }
}
