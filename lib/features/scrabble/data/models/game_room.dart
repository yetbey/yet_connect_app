// lib/features/scrabble/data/models/game_room.dart

import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';
import 'package:yet_x_app/features/scrabble/data/models/game_move.dart';

enum GameStatus { waiting, playing, finished }

class GameRoom {
  final String id;
  final String hostId;
  final List<String> playerIds;
  final int maxPlayers;
  final GameStatus status;
  final String? currentTurnPlayerId;
  final List<List<BoardCell>> board;
  final Map<String, int> scores;
  final Map<String, List<String>> playerRacks;
  final List<String> tileBag;
  final List<GameMove> moves;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const GameRoom({
    required this.id,
    required this.hostId,
    required this.playerIds,
    required this.maxPlayers,
    required this.status,
    this.currentTurnPlayerId,
    required this.board,
    required this.scores,
    required this.playerRacks,
    required this.tileBag,
    required this.moves,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'playerIds': playerIds,
      'maxPlayers': maxPlayers,
      'status': status.name,
      'currentTurnPlayerId': currentTurnPlayerId,
      'board': board.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
      'scores': scores,
      'playerRacks': playerRacks,
      'tileBag': tileBag,
      'moves': moves.map((move) => move.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
    };
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      playerIds: (json['playerIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      maxPlayers: json['maxPlayers'] as int? ?? 2,
      status: _parseStatus(json['status']),
      currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
      board: _parseBoard(json['board']),
      scores: _parseScores(json['scores']),
      playerRacks: _parsePlayerRacks(json['playerRacks']),
      tileBag: (json['tileBag'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      moves: _parseMoves(json['moves']),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
    );
  }

  // ============================================================================
  // HELPER METODLAR (ÖNEMLİ!)
  // ============================================================================

  static GameStatus _parseStatus(dynamic status) {
    if (status == null) return GameStatus.waiting;
    if (status is GameStatus) return status;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'waiting':
        return GameStatus.waiting;
      case 'playing':
        return GameStatus.playing;
      case 'finished':
        return GameStatus.finished;
      default:
        return GameStatus.waiting;
    }
  }

  static List<List<BoardCell>> _parseBoard(dynamic board) {
    if (board == null) return [];

    try {
      final boardList = board as List<dynamic>;
      return boardList.map((row) {
        final rowList = row as List<dynamic>;
        return rowList.map((cell) {
          if (cell is Map) {
            // Firebase Map<Object?, Object?> → Map<String, dynamic>
            final cellMap = <String, dynamic>{};
            (cell as Map<Object?, Object?>).forEach((key, value) {
              if (key != null) {
                cellMap[key.toString()] = value;
              }
            });
            return BoardCell.fromJson(cellMap);
          }
          return BoardCell.empty();
        }).toList();
      }).toList();
    } catch (e) {
      print('❌ Board parse error: $e');
      return [];
    }
  }

  static Map<String, int> _parseScores(dynamic scores) {
    if (scores == null) return {};

    try {
      if (scores is Map) {
        final result = <String, int>{};
        scores.forEach((key, value) {
          result[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
        });
        return result;
      }
      return {};
    } catch (e) {
      print('❌ Scores parse error: $e');
      return {};
    }
  }

  static Map<String, List<String>> _parsePlayerRacks(dynamic playerRacks) {
    if (playerRacks == null) return {};

    try {
      if (playerRacks is Map) {
        final result = <String, List<String>>{};
        playerRacks.forEach((key, value) {
          if (value is List) {
            result[key.toString()] = value.map((e) => e.toString()).toList();
          }
        });
        return result;
      }
      return {};
    } catch (e) {
      print('❌ PlayerRacks parse error: $e');
      return {};
    }
  }

  static List<GameMove> _parseMoves(dynamic moves) {
    if (moves == null) return [];

    try {
      if (moves is List) {
        return moves.map((move) {
          if (move is Map) {
            final moveMap = <String, dynamic>{};
            (move as Map<Object?, Object?>).forEach((key, value) {
              if (key != null) {
                moveMap[key.toString()] = value;
              }
            });
            return GameMove.fromJson(moveMap);
          }
          return GameMove.empty();
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Moves parse error: $e');
      return [];
    }
  }

  GameRoom copyWith({
    String? id,
    String? hostId,
    List<String>? playerIds,
    int? maxPlayers,
    GameStatus? status,
    String? currentTurnPlayerId,
    List<List<BoardCell>>? board,
    Map<String, int>? scores,
    Map<String, List<String>>? playerRacks,
    List<String>? tileBag,
    List<GameMove>? moves,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return GameRoom(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      playerIds: playerIds ?? this.playerIds,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      status: status ?? this.status,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      board: board ?? this.board,
      scores: scores ?? this.scores,
      playerRacks: playerRacks ?? this.playerRacks,
      tileBag: tileBag ?? this.tileBag,
      moves: moves ?? this.moves,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}
