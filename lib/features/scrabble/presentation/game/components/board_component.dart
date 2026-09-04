// lib/features/scrabble/presentation/game/components/board_component.dart

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/cell_component.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/tile_component.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';

class BoardComponent extends PositionComponent {
  final int boardSize;
  final double cellSize;
  final FlameGame game;

  final List<List<CellComponent>> cells = [];
  final List<TileComponent> placedTiles = [];

  BoardComponent({
    required this.boardSize,
    required this.cellSize,
    required this.game,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final boardWidth = boardSize * cellSize;
    final boardHeight = boardSize * cellSize;

    // ✅ DÜZELTME: Tahtayı daha aşağı ve merkeze yerleştir
    position = Vector2(
      (game.size.x - boardWidth) / 2,
      (game.size.y - boardHeight) / 2 - 50, // Daha az yukarı kaydır
    );

    size = Vector2(boardWidth, boardHeight);

    // Arka plan
    final backgroundRect = RectangleComponent(
      size: size,
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF34495E),
          ],
        ).createShader(Rect.fromLTWH(0, 0, boardWidth, boardHeight)),
      position: Vector2.zero(),
    );

    await add(backgroundRect);

    // Hücreleri oluştur
    _createCells();

    // Giriş animasyonu
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.8,
          curve: Curves.elasticOut,
        ),
      ),
    );
    scale = Vector2.all(0.8); // ✅ 0.5 yerine 0.8 başlat
  }

  void _createCells() {
    final multipliers = ScrabbleConstants.getBoardMultipliers();

    for (int row = 0; row < boardSize; row++) {
      final rowCells = <CellComponent>[];

      for (int col = 0; col < boardSize; col++) {
        final cell = CellComponent(
          row: row,
          col: col,
          multiplier: multipliers[row][col],
          cellSize: cellSize,
        );

        cell.position = Vector2(
          col * cellSize + 2,
          row * cellSize + 2,
        );

        add(cell);
        rowCells.add(cell);
      }

      cells.add(rowCells);
    }
  }

  void updateBoard(List<List<BoardCell>> boardState) {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        final cellState = boardState[row][col];
        final cellComponent = cells[row][col];

        if (cellState.letter != null && cellComponent.tile == null) {
          // Yeni tile ekle
          final tile = TileComponent(
            letter: cellState.letter!,
            points: cellState.points ?? 0,
            cellSize: cellSize,
          );

          cellComponent.placeTile(tile);
        }
      }
    }
  }

  void handleTap(Vector2 tapPosition) {
    final localPos = tapPosition - position;
    final row = (localPos.y / cellSize).floor();
    final col = (localPos.x / cellSize).floor();

    if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
      cells[row][col].onTapped();
    }
  }

  void handleDrop(TileComponent tile, Vector2 globalPosition) {
    // Global pozisyonu board lokal pozisyonuna çevir
    final localPos = globalPosition - position;

    // Hangi hücreye bırakıldı?
    final row = (localPos.y / cellSize).floor();
    final col = (localPos.x / cellSize).floor();

    LogService.i('🎯 Drop position: global=$globalPosition, local=$localPos');
    LogService.i('🎯 Grid position: row=$row, col=$col');

    // Tahta sınırları içinde mi?
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      LogService.i('⚠️ Tahta dışında bırakıldı');
      tile.returnToOriginal();
      return;
    }

    final targetCell = cells[row][col];

    // Hücre boş mu?
    if (targetCell.tile != null) {
      LogService.i('⚠️ Hücre dolu: ($row, $col)');
      tile.returnToOriginal();
      return;
    }

    // ✅ Tile'ı hücreye yerleştir
    final cellCenterPos = Vector2(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );

    tile.placeOnBoard(position + cellCenterPos);
    targetCell.tile = tile;
    placedTiles.add(tile);

    LogService.i('✅ Tile yerleştirildi: ${tile.letter} at ($row, $col)');
  }
}
