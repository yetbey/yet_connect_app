// lib/features/scrabble/core/constants/scrabble_constants.dart

import 'package:flutter/material.dart';
import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';

class ScrabbleConstants {
  static const int boardSize = 15;

  // Harf puanları
  static const Map<String, int> letterPoints = {
    'A': 1, 'B': 3, 'C': 4, 'Ç': 4, 'D': 3,
    'E': 1, 'F': 7, 'G': 5, 'Ğ': 8, 'H': 5,
    'I': 2, 'İ': 1, 'J': 10, 'K': 1, 'L': 1,
    'M': 2, 'N': 1, 'O': 2, 'Ö': 7, 'P': 5,
    'R': 1, 'S': 2, 'Ş': 4, 'T': 1, 'U': 2,
    'Ü': 3, 'V': 7, 'Y': 3, 'Z': 4,
  };

  // Harf sayıları (kaç tane var)
  static const Map<String, int> letterCounts = {
    'A': 12, 'B': 2, 'C': 2, 'Ç': 2, 'D': 3,
    'E': 8, 'F': 1, 'G': 2, 'Ğ': 1, 'H': 2,
    'I': 4, 'İ': 7, 'J': 1, 'K': 7, 'L': 7,
    'M': 4, 'N': 5, 'O': 3, 'Ö': 1, 'P': 1,
    'R': 6, 'S': 3, 'Ş': 2, 'T': 5, 'U': 3,
    'Ü': 2, 'V': 1, 'Y': 2, 'Z': 2,
  };

  // Hücre renkleri
  static const Map<CellMultiplier, Color> cellColors = {
    CellMultiplier.normal: Color(0xFF3A8FB7),
    CellMultiplier.doubleLetter: Color(0xFF8EC5FC),
    CellMultiplier.tripleLetter: Color(0xFF4F86F7),
    CellMultiplier.doubleWord: Color(0xFFFFB6C1),
    CellMultiplier.tripleWord: Color(0xFFFF6B9D),
    CellMultiplier.center: Color(0xFFFFD700),
  };

  // Boş tahta oluştur
  static List<List<BoardCell>> createEmptyBoard() {
    final multipliers = getBoardMultipliers();
    final board = <List<BoardCell>>[];

    for (int row = 0; row < boardSize; row++) {
      final rowCells = <BoardCell>[];
      for (int col = 0; col < boardSize; col++) {
        rowCells.add(BoardCell(
          row: row,
          col: col,
          letter: null,
          points: null,
          multiplier: multipliers[row][col],
        ));
      }
      board.add(rowCells);
    }

    return board;
  }

  // Tile bag oluştur (harfleri karıştır)
  static List<String> generateTileBag() {
    final tiles = <String>[];

    letterCounts.forEach((letter, count) {
      for (int i = 0; i < count; i++) {
        tiles.add(letter);
      }
    });

    tiles.shuffle();
    return tiles;
  }

  // Tahta çarpanlarını döndür
  static List<List<CellMultiplier>> getBoardMultipliers() {
    final board = List.generate(
      boardSize,
          (_) => List.filled(boardSize, CellMultiplier.normal),
    );

    // Merkez (★)
    board[7][7] = CellMultiplier.center;

    // Triple Word (kırmızı köşeler)
    final tripleWord = [
      [0, 0], [0, 7], [0, 14],
      [7, 0], [7, 14],
      [14, 0], [14, 7], [14, 14],
    ];
    for (var pos in tripleWord) {
      board[pos[0]][pos[1]] = CellMultiplier.tripleWord;
    }

    // Double Word (pembe)
    final doubleWord = [
      [1, 1], [1, 13],
      [2, 2], [2, 12],
      [3, 3], [3, 11],
      [4, 4], [4, 10],
      [10, 4], [10, 10],
      [11, 3], [11, 11],
      [12, 2], [12, 12],
      [13, 1], [13, 13],
    ];
    for (var pos in doubleWord) {
      board[pos[0]][pos[1]] = CellMultiplier.doubleWord;
    }

    // Triple Letter (koyu mavi)
    final tripleLetter = [
      [1, 5], [1, 9],
      [5, 1], [5, 5], [5, 9], [5, 13],
      [9, 1], [9, 5], [9, 9], [9, 13],
      [13, 5], [13, 9],
    ];
    for (var pos in tripleLetter) {
      board[pos[0]][pos[1]] = CellMultiplier.tripleLetter;
    }

    // Double Letter (açık mavi)
    final doubleLetter = [
      [0, 3], [0, 11],
      [2, 6], [2, 8],
      [3, 0], [3, 7], [3, 14],
      [6, 2], [6, 6], [6, 8], [6, 12],
      [7, 3], [7, 11],
      [8, 2], [8, 6], [8, 8], [8, 12],
      [11, 0], [11, 7], [11, 14],
      [12, 6], [12, 8],
      [14, 3], [14, 11],
    ];
    for (var pos in doubleLetter) {
      board[pos[0]][pos[1]] = CellMultiplier.doubleLetter;
    }

    return board;
  }
}
