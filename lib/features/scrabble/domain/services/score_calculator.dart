// lib/features/scrabble/domain/services/score_calculator.dart

import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';
import 'package:yet_x_app/features/scrabble/data/models/game_move.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';

class ScoreCalculator {
  /// Hamle puanını hesapla
  static int calculateMoveScore({
    required List<PlacedTile> placedTiles,
    required List<List<BoardCell>> board,
  }) {
    int totalScore = 0;
    int wordMultiplier = 1;

    for (var tile in placedTiles) {
      final cell = board[tile.row][tile.col];
      int letterScore = tile.points;

      // Harf çarpanları
      switch (cell.multiplier) {
        case CellMultiplier.doubleLetter:
          letterScore *= 2;
          break;
        case CellMultiplier.tripleLetter:
          letterScore *= 3;
          break;
        case CellMultiplier.doubleWord:
          wordMultiplier *= 2;
          break;
        case CellMultiplier.tripleWord:
          wordMultiplier *= 3;
          break;
        case CellMultiplier.center:
          wordMultiplier *= 2; // Merkez 2x kelime
          break;
        default:
          break;
      }

      totalScore += letterScore;
    }

    // Kelime çarpanını uygula
    totalScore *= wordMultiplier;

    // Tüm 7 harfi kullandıysa +50 bonus
    if (placedTiles.length == 7) {
      totalScore += 50;
    }

    return totalScore;
  }

  /// Tahtadan kelimeleri bul ve puanla
  static Map<String, int> findAndScoreWords({
    required List<PlacedTile> newTiles,
    required List<List<BoardCell>> board,
  }) {
    final words = <String, int>{};

    // Yatay kelimeleri kontrol et
    for (var tile in newTiles) {
      final word = _getHorizontalWord(tile.row, tile.col, board);
      if (word.isNotEmpty && word.length > 1) {
        words[word] = calculateMoveScore(
          placedTiles: _getWordTiles(tile.row, tile.col, board, true),
          board: board,
        );
      }
    }

    // Dikey kelimeleri kontrol et
    for (var tile in newTiles) {
      final word = _getVerticalWord(tile.row, tile.col, board);
      if (word.isNotEmpty && word.length > 1) {
        words[word] = calculateMoveScore(
          placedTiles: _getWordTiles(tile.row, tile.col, board, false),
          board: board,
        );
      }
    }

    return words;
  }

  // Yatay kelimeyi al
  static String _getHorizontalWord(
    int row,
    int col,
    List<List<BoardCell>> board,
  ) {
    int start = col;
    int end = col;

    // Sola git
    while (start > 0 && board[row][start - 1].letter != null) {
      start--;
    }

    // Sağa git
    while (end < ScrabbleConstants.boardSize - 1 &&
        board[row][end + 1].letter != null) {
      end++;
    }

    if (start == end) return '';

    String word = '';
    for (int i = start; i <= end; i++) {
      word += board[row][i].letter ?? '';
    }

    return word;
  }

  // Dikey kelimeyi al
  static String _getVerticalWord(
    int row,
    int col,
    List<List<BoardCell>> board,
  ) {
    int start = row;
    int end = row;

    // Yukarı git
    while (start > 0 && board[start - 1][col].letter != null) {
      start--;
    }

    // Aşağı git
    while (end < ScrabbleConstants.boardSize - 1 &&
        board[end + 1][col].letter != null) {
      end++;
    }

    if (start == end) return '';

    String word = '';
    for (int i = start; i <= end; i++) {
      word += board[i][col].letter ?? '';
    }

    return word;
  }

  // Kelime tile'larını al
  static List<PlacedTile> _getWordTiles(
    int row,
    int col,
    List<List<BoardCell>> board,
    bool horizontal,
  ) {
    final tiles = <PlacedTile>[];

    if (horizontal) {
      int start = col;
      while (start > 0 && board[row][start - 1].letter != null) {
        start--;
      }

      int end = col;
      while (end < ScrabbleConstants.boardSize - 1 &&
          board[row][end + 1].letter != null) {
        end++;
      }

      for (int i = start; i <= end; i++) {
        final cell = board[row][i];
        if (cell.letter != null) {
          tiles.add(
            PlacedTile(
              letter: cell.letter!,
              row: row,
              col: i,
              points: cell.points ?? 0,
            ),
          );
        }
      }
    } else {
      int start = row;
      while (start > 0 && board[start - 1][col].letter != null) {
        start--;
      }

      int end = row;
      while (end < ScrabbleConstants.boardSize - 1 &&
          board[end + 1][col].letter != null) {
        end++;
      }

      for (int i = start; i <= end; i++) {
        final cell = board[i][col];
        if (cell.letter != null) {
          tiles.add(
            PlacedTile(
              letter: cell.letter!,
              row: i,
              col: col,
              points: cell.points ?? 0,
            ),
          );
        }
      }
    }

    return tiles;
  }
}
