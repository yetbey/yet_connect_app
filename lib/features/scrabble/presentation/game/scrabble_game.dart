// lib/features/scrabble/presentation/game/scrabble_game.dart

import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/board_component.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/tile_component.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/components/rack_component.dart';
import 'package:yet_x_app/features/scrabble/data/models/game_room.dart';
import 'package:yet_x_app/features/scrabble/core/constants/scrabble_constants.dart';

class ScrabbleGame extends FlameGame with TapCallbacks, DragCallbacks, ScaleDetector {
  final String roomId;
  final String userId;
  final WidgetRef ref;

  late BoardComponent boardComponent;
  late RackComponent rackComponent;
  final List<TileComponent> draggedTiles = [];
  TileComponent? currentDraggedTile;

  double baseZoom = 1.0;
  Vector2? lastPanPosition;
  bool isPanning = false;

  double? targetZoom;
  double? startZoom;
  double zoomAnimationProgress = 0;
  static const double zoomAnimationDuration = 0.2;

  ScrabbleGame({
    required this.roomId,
    required this.userId,
    required this.ref,
  });

  @override
  Color backgroundColor() => const Color(0xFF0f3460);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Board component
    boardComponent = BoardComponent(
      boardSize: ScrabbleConstants.boardSize,
      cellSize: 40,
      game: this,
    );

    await add(boardComponent);
    boardComponent.scale = Vector2.all(0.7);

    // Rack component (başlangıçta boş)
    rackComponent = RackComponent(
      letters: [],
      tileSize: 50,
    );

    // Ekranın altına yerleştir
    rackComponent.position = Vector2(
      size.x / 2 - rackComponent.size.x / 2,
      size.y - rackComponent.size.y - 20,
    );

    await add(rackComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (targetZoom != null && startZoom != null) {
      zoomAnimationProgress += dt / zoomAnimationDuration;

      if (zoomAnimationProgress >= 1.0) {
        boardComponent.scale = Vector2.all(targetZoom!);
        targetZoom = null;
        startZoom = null;
        zoomAnimationProgress = 0;
        LogService.i('✅ Animasyon tamamlandı: ${boardComponent.scale.x}');
      } else {
        final t = Curves.easeOut.transform(zoomAnimationProgress);
        final currentScale = startZoom! + (targetZoom! - startZoom!) * t;
        boardComponent.scale = Vector2.all(currentScale);
      }
    }
  }

  void updateGameState(GameRoom room) {
    boardComponent.updateBoard(room.board);

    // Oyuncunun harflerini güncelle
    final playerRack = room.playerRacks[userId] ?? [];
    rackComponent.updateLetters(playerRack);

    LogService.i('🎮 Oyuncu harfleri güncellendi: $playerRack');
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isPanning) return;

    final tapPosition = event.localPosition;
    boardComponent.handleTap(tapPosition);
  }

  // ============================================================================
  // PAN (Kaydırma)
  // ============================================================================

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    isPanning = true;
    lastPanPosition = event.canvasPosition;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (lastPanPosition != null) {
      final delta = event.localDelta;

      // boardComponent pozisyonunu değiştir
      boardComponent.position += delta;

      lastPanPosition = Vector2(
        lastPanPosition!.x + delta.x,
        lastPanPosition!.y + delta.y,
      );
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    isPanning = false;
    lastPanPosition = null;

    if (currentDraggedTile != null) {
      final dropPosition = currentDraggedTile!.position;
      boardComponent.handleDrop(currentDraggedTile!, dropPosition);
      currentDraggedTile!.endDrag();
      currentDraggedTile = null;
    }
  }

  // ============================================================================
  // PINCH TO ZOOM
  // ============================================================================

  @override
  void onScaleStart(ScaleStartInfo info) {
    baseZoom = boardComponent.scale.x;
    targetZoom = null;
    startZoom = null;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final scaleVector = info.scale.global;
    final double scaleFactor = scaleVector.x;

    double newZoom = baseZoom * scaleFactor;

    if (newZoom < 0.5) newZoom = 0.5;
    if (newZoom > 2.0) newZoom = 2.0;

    boardComponent.scale = Vector2.all(newZoom);
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    baseZoom = boardComponent.scale.x;
  }

  // ============================================================================
  // ZOOM CONTROLS
  // ============================================================================

  void zoomIn() {
    LogService.i('🔍🔍🔍 ZOOM IN ÇAĞRILDI');
    final currentZoom = boardComponent.scale.x;
    double newZoom = currentZoom + 0.2;
    if (newZoom > 2.0) newZoom = 2.0;

    startZoom = currentZoom;
    targetZoom = newZoom;
    zoomAnimationProgress = 0;

    LogService.i('🔍 Başlangıç: $currentZoom → Hedef: $newZoom');
  }

  void zoomOut() {
    LogService.i('🔍🔍🔍 ZOOM OUT ÇAĞRILDI');
    final currentZoom = boardComponent.scale.x;
    double newZoom = currentZoom - 0.2;
    if (newZoom < 0.5) newZoom = 0.5;

    startZoom = currentZoom;
    targetZoom = newZoom;
    zoomAnimationProgress = 0;

    LogService.i('🔍 Başlangıç: $currentZoom → Hedef: $newZoom');
  }

  void resetZoom() {
    LogService.i('🔍🔍🔍 RESET ZOOM ÇAĞRILDI');

    startZoom = boardComponent.scale.x;
    targetZoom = 0.7;
    zoomAnimationProgress = 0;

    boardComponent.position = Vector2.zero();

    LogService.i('🔍 Başlangıç: $startZoom → Hedef: 0.7');
  }
}
