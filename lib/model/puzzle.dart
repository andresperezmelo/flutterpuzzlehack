import 'dart:typed_data';

class Puzzle {
  late int level;
  late int score;
  late int moves;
  late int optionMode;
  late List<int> listTiles;
  late Uint8List image;
  late List<List<int>> listTilesBytes;
  late double percentSolved = 0;

  Puzzle({
    required this.level,
    required this.score,
    required this.moves,
    required this.optionMode,
    required this.listTiles,
    required this.image,
    required this.listTilesBytes,
    required this.percentSolved,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        level: json["level"],
        score: json["score"],
        moves: json["moves"],
        optionMode: json["optionMode"],
        listTiles: List<int>.from(json["listTiles"].map((x) => x)),
        image: Uint8List.fromList(json["image"]),
        listTilesBytes: List<List<int>>.from(json["listTilesBytes"].map((x) => List<int>.from(x.map((x) => x)))),
        percentSolved: double.parse(json["percentSolved"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "level": level,
        "score": score,
        "moves": moves,
        "optionMode": optionMode,
        "listTiles": List<dynamic>.from(listTiles.map((x) => x)),
        "image": List<dynamic>.from(image.map((x) => x)),
        "listTilesBytes": List<dynamic>.from(listTilesBytes.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "percentSolved": percentSolved,
      };

  factory Puzzle.voidValues() => Puzzle(
        level: 0,
        score: 0,
        moves: 0,
        optionMode: 0,
        listTiles: [],
        image: Uint8List(0),
        listTilesBytes: [],
        percentSolved: 0,
      );
}
