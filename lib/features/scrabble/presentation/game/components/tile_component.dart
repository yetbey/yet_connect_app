// lib/features/scrabble/presentation/game/components/tile_component.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class TileComponent extends PositionComponent with DragCallbacks {
  final String letter;
  final int points;
  final double cellSize;

  Vector2? originalPosition;
  bool isDragging = false;
  bool isPlacedOnBoard = false;

  TileComponent({
    required this.letter,
    required this.points,
    required this.cellSize,
  }) {
    size = Vector2.all(cellSize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Orijinal pozisyonu kaydet
    originalPosition = position.clone();

    // Tile görünümü
    await _createTileVisual();
  }

  Future<void> _createTileVisual() async {
    // Arka plan
    final background = RectangleComponent(
      size: size,
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8DC), Color(0xFFFFE4B5)],
        ).createShader(Rect.fromLTWH(0, 0, cellSize, cellSize)),
    );
    background.position = Vector2.zero();
    await add(background);

    // Gölge efekti
    final shadow = RectangleComponent(
      size: size * 0.95,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    await add(shadow);

    // Harf metni
    final letterText = TextComponent(
      text: letter,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: cellSize * 0.5,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2C3E50),
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    await add(letterText);

    // Puan metni
    final pointsText = TextComponent(
      text: points.toString(),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: cellSize * 0.2,
          fontWeight: FontWeight.bold,
          color: Colors.black.withOpacity(0.5),
        ),
      ),
      anchor: Anchor.bottomRight,
      position: Vector2(size.x - 4, size.y - 2),
    );
    await add(pointsText);
  }

  // ============================================================================
  // DRAG CALLBACKS
  // ============================================================================

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    if (isPlacedOnBoard) return; // Tahtaya yerleştirilmişse sürüklenemesin

    isDragging = true;
    priority = 100; // En üstte görünsün

    // Büyüt
    scale = Vector2.all(1.2);

    print('🎯 Tile sürüklenmeye başladı: $letter');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return;

    // Tile'ı fare/parmak pozisyonuna taşı
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    if (!isDragging) return;

    isDragging = false;
    priority = 0;
    scale = Vector2.all(1.0);

    print('🎯 Tile bırakıldı: $letter at $position');
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  // ✅ YENİ: endDrag metodu
  void endDrag() {
    isDragging = false;
    priority = 0;
    scale = Vector2.all(1.0);
  }

  void returnToOriginal() {
    if (originalPosition != null) {
      position = originalPosition!.clone();
      isPlacedOnBoard = false;
      scale = Vector2.all(1.0);
      isDragging = false;
      priority = 0;
      print('↩️ Tile geri döndü: $letter');
    }
  }

  void placeOnBoard(Vector2 newPosition) {
    position = newPosition;
    isPlacedOnBoard = true;
    originalPosition = null;
    scale = Vector2.all(1.0);
    isDragging = false;
    priority = 0;
    print('✅ Tile tahtaya yerleşti: $letter at $newPosition');
  }

  void removeFromBoard() {
    isPlacedOnBoard = false;
    print('❌ Tile tahtadan kaldırıldı: $letter');
  }
}
