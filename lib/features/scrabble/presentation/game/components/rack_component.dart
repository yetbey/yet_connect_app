// lib/features/scrabble/presentation/game/components/rack_component.dart

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/tile_component.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';

class RackComponent extends PositionComponent {
  final List<String> letters;
  final double tileSize;
  final List<TileComponent> tiles = [];

  RackComponent({
    required this.letters,
    this.tileSize = 50,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Raf arka planı
    final rackWidth = letters.length * (tileSize + 8) + 16;
    final rackHeight = tileSize + 16;

    size = Vector2(rackWidth, rackHeight);

    final background = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF8B4513).withValues(alpha: .8),
    );
    background.position = Vector2.zero();
    await add(background);

    // Tile'ları oluştur
    await _createTiles();
  }

  Future<void> _createTiles() async {
    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final points = ScrabbleConstants.letterPoints[letter] ?? 0;

      final tile = TileComponent(
        letter: letter,
        points: points,
        cellSize: tileSize,
      );

      tile.position = Vector2(
        (i * (tileSize + 8)) + tileSize / 2 + 8,
        size.y / 2,
      );

      tiles.add(tile);
      await add(tile);
    }
  }

  void updateLetters(List<String> newLetters) {
    // Mevcut tile'ları temizle
    for (var tile in tiles) {
      tile.removeFromParent();
    }
    tiles.clear();

    // Yeni tile'ları ekle
    _createTiles();
  }

  TileComponent? getTileAt(Vector2 position) {
    for (var tile in tiles) {
      if (tile.containsPoint(position - tile.position)) {
        return tile;
      }
    }
    return null;
  }
}
