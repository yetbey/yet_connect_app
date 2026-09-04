// lib/features/scrabble/presentation/screens/scrabble_game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/scrabble/presentation/game/scrabble_game.dart';
import 'package:yet_x_app/features/scrabble/presentation/providers/scrabble_provider.dart';
import 'dart:ui';
import '../../core/constants/scrabble_constants.dart';

class ScrabbleGameScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String userId;

  const ScrabbleGameScreen({
    super.key,
    required this.roomId,
    required this.userId,
  });

  @override
  ConsumerState<ScrabbleGameScreen> createState() => _ScrabbleGameScreenState();
}

class _ScrabbleGameScreenState extends ConsumerState<ScrabbleGameScreen> {
  late final ScrabbleGame _game;

  @override
  void initState() {
    super.initState();

    _game = ScrabbleGame(
      roomId: widget.roomId,
      userId: widget.userId,
      ref: ref,
    );

    ref.read(scrabbleProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final scrabbleState = ref.watch(scrabbleProvider);
    final currentRoom = scrabbleState.currentRoom;

    ref.listen<ScrabbleState>(scrabbleProvider, (previous, next) {
      if (next.currentRoom != null) {
        _game.updateGameState(next.currentRoom!);
      }
    });

    if (currentRoom == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldLeave = await _showLeaveDialog();

        if (shouldLeave) {
          await ref
              .read(scrabbleProvider.notifier)
              .leaveRoom(widget.userId);

          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Flame Game
            GameWidget(game: _game),

            // Üst overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopOverlay(currentRoom),
            ),

            // Alt overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomOverlay(currentRoom),
            ),

            // Sağ overlay
            Positioned(
              top: 100,
              right: 0,
              child: _buildRightOverlay(currentRoom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(dynamic room) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 40, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: .6),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () async {
                final shouldLeave = await _showLeaveDialog();
                if (shouldLeave) {
                  await ref.read(scrabbleProvider.notifier).leaveRoom(widget.userId);
                  if (mounted) Navigator.pop(context);
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: room.playerIds.map<Widget>((playerId) {
                    final isCurrentTurn = room.currentTurnPlayerId == playerId;
                    final score = room.scores[playerId] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentTurn
                            ? Colors.amber.withValues(alpha: .3)
                            : Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrentTurn ? Colors.amber : Colors.white.withValues(alpha: .3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isCurrentTurn
                                    ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                                    : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                playerId.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                playerId == widget.userId ? 'Sen' : 'Oyuncu',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$score',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(dynamic room) {
    final playerRack = room.playerRacks[widget.userId] ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: .8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 70,
              child: playerRack.isEmpty
                  ? Center(
                child: Text(
                  'Harfler yükleniyor...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .5),
                    fontSize: 12,
                  ),
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: playerRack.map<Widget>((letter) {
                        return _buildTileWidget(letter);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightOverlay(dynamic room) {
    final isMyTurn = room.currentTurnPlayerId == widget.userId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.zoom_in,
            color: Colors.purple,
            onTap: () {
              HapticFeedback.lightImpact();
              _game.zoomIn();
            },
          ),

          const SizedBox(height: 8),

          _buildActionButton(
            icon: Icons.zoom_out,
            color: Colors.purple,
            onTap: () {
              HapticFeedback.lightImpact();
              _game.zoomOut();
            },
          ),

          const SizedBox(height: 8),

          _buildActionButton(
            icon: Icons.center_focus_strong,
            color: Colors.purple,
            onTap: () {
              HapticFeedback.lightImpact();
              _game.resetZoom();
            },
          ),

          const SizedBox(height: 16),

          if (isMyTurn)
            _buildActionButton(
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () {
                HapticFeedback.mediumImpact();
                // TODO: Hamleyi oyna
              },
            ),

          if (isMyTurn) const SizedBox(height: 8),

          if (isMyTurn)
            _buildActionButton(
              icon: Icons.forward,
              color: Colors.orange,
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Pas geç
              },
            ),

          if (isMyTurn) const SizedBox(height: 8),

          if (isMyTurn)
            _buildActionButton(
              icon: Icons.shuffle,
              color: Colors.blue,
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Harfleri değiştir
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          LogService.i('🎮 BUTON TIKLANDI: $icon');
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: .7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTileWidget(String letter) {
    final points = ScrabbleConstants.letterPoints[letter] ?? 0;

    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8DC), Color(0xFFFFE4B5)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            right: 3,
            child: Text(
              points.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: .5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLeaveDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Oyundan Ayrıl?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Oyundan ayrılmak istediğinize emin misiniz?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Ayrıl'),
            ),
          ],
        ),
      ),
    ) ?? false;
  }
}
