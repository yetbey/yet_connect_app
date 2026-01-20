class GameMove {
  final String playerId;
  final List<PlacedTile> placedTiles;
  final String word;
  final int score;
  final DateTime timestamp;
  final bool isValid;

  GameMove({
    required this.playerId,
    required this.placedTiles,
    required this.word,
    required this.score,
    required this.timestamp,
    this.isValid = true,
  });

  factory GameMove.empty() {
    return GameMove(
      playerId: '',
      placedTiles: [],
      word: '',
      score: 0,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'placedTiles': placedTiles.map((t) => t.toJson()).toList(),
      'word': word,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
      'isValid': isValid,
    };
  }

  factory GameMove.fromJson(Map<String, dynamic> json) {
    return GameMove(
      playerId: json['playerId'],
      placedTiles: (json['placedTiles'] as List)
          .map((t) => PlacedTile.fromJson(t))
          .toList(),
      word: json['word'],
      score: json['score'],
      timestamp: DateTime.parse(json['timestamp']),
      isValid: json['isValid'] ?? true,
    );
  }
}

class PlacedTile {
  final String letter;
  final int row;
  final int col;
  final int points;

  PlacedTile({
    required this.letter,
    required this.row,
    required this.col,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'row': row,
      'col': col,
      'points': points,
    };
  }

  factory PlacedTile.fromJson(Map<String, dynamic> json) {
    return PlacedTile(
      letter: json['letter'],
      row: json['row'],
      col: json['col'],
      points: json['points'],
    );
  }
}
