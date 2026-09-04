// lib/features/scrabble/presentation/game/components/cell_component.dart

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:yet_x_app/features/scrabble/data/models/board_cell.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/tile_component.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';

class CellComponent extends PositionComponent {
  final int row;
  final int col;
  final CellMultiplier multiplier;
  final double cellSize;

  TileComponent? tile;
  bool isHighlighted = false;

  CellComponent({
    required this.row,
    required this.col,
    required this.multiplier,
    required this.cellSize,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(cellSize - 4);

    // Hücre arka planı
    await add(_buildCellBackground());

    // Çarpan text'i
    if (multiplier != CellMultiplier.normal) {
      await add(_buildMultiplierLabel());
    }
  }

  Component _buildCellBackground() {
    final color = ScrabbleConstants.cellColors[multiplier] ?? Colors.grey;

    return RectangleComponent(
      size: size,
      paint: Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: .7),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y))
        ..style = PaintingStyle.fill,
    )..add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.white.withValues(alpha: .1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      ),
    );
  }

  Component _buildMultiplierLabel() {
    final text = _getMultiplierText();

    return TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withValues(alpha: .8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
  }

  String _getMultiplierText() {
    switch (multiplier) {
      case CellMultiplier.doubleWord:
        return '2W';
      case CellMultiplier.tripleWord:
        return '3W';
      case CellMultiplier.doubleLetter:
        return '2L';
      case CellMultiplier.tripleLetter:
        return '3L';
      case CellMultiplier.center:
        return '★';
      default:
        return '';
    }
  }

  void placeTile(TileComponent newTile) {
    tile = newTile;
    newTile.position = Vector2(2, 2);
    add(newTile);

    // Yerleştirme animasyonu
    newTile.add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.3,
          curve: Curves.bounceOut,
        ),
      ),
    );
    newTile.scale = Vector2.all(0.5);
  }

  void removeTile() {
    if (tile != null) {
      tile!.removeFromParent();
      tile = null;
    }
  }

  void onTapped() {
    // Vurgu efekti
    isHighlighted = !isHighlighted;

    add(
      ColorEffect(
        isHighlighted ? Colors.yellow.withValues(alpha: .3) : Colors.transparent,
        EffectController(duration: 0.2),
        opacityTo: isHighlighted ? 0.3 : 0,
      ),
    );
  }
}
