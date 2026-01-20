class BoardCell {
  final int row;
  final int col;
  final String? letter; // Harf yerleştirilmişse
  final int? points; // Harf puanı
  final String? playerId; // Kim yerleştirdi
  final CellMultiplier multiplier; // Çarpan tipi

  BoardCell({
    required this.row,
    required this.col,
    this.letter,
    this.points,
    this.playerId,
    this.multiplier = CellMultiplier.normal,
  });

  factory BoardCell.empty() {
    return BoardCell(
      row: 0,
      col: 0,
      letter: null,
      points: null,
      multiplier: CellMultiplier.normal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'letter': letter,
      'points': points,
      'playerId': playerId,
      'multiplier': multiplier.name,
    };
  }

  factory BoardCell.fromJson(Map<String, dynamic> json) {
    return BoardCell(
      row: json['row'] as int? ?? 0,
      col: json['col'] as int? ?? 0,
      letter: json['letter'] as String?,
      points: json['points'] as int?,
      multiplier: _parseMultiplier(json['multiplier']),
    );
  }

  static CellMultiplier _parseMultiplier(dynamic multiplier) {
    if (multiplier == null) return CellMultiplier.normal;

    final multiplierStr = multiplier.toString().toLowerCase();
    switch (multiplierStr) {
      case 'doubleword':
        return CellMultiplier.doubleWord;
      case 'tripleword':
        return CellMultiplier.tripleWord;
      case 'doubleletter':
        return CellMultiplier.doubleLetter;
      case 'tripleletter':
        return CellMultiplier.tripleLetter;
      case 'center':
        return CellMultiplier.center;
      default:
        return CellMultiplier.normal;
    }
  }

  BoardCell copyWith({
    int? row,
    int? col,
    String? letter,
    int? points,
    String? playerId,
    CellMultiplier? multiplier,
  }) {
    return BoardCell(
      row: row ?? this.row,
      col: col ?? this.col,
      letter: letter ?? this.letter,
      points: points ?? this.points,
      playerId: playerId ?? this.playerId,
      multiplier: multiplier ?? this.multiplier,
    );
  }

  bool get isEmpty => letter == null;
}

enum CellMultiplier {
  normal, // Sıradan
  doubleWord, // 2x Kelime (DW)
  tripleWord, // 3x Kelime (TW)
  doubleLetter, // 2x Harf (DL)
  tripleLetter, // 3x Harf (TL)
  center, // Merkez (başlangıç)
}
