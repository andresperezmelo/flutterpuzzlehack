import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:puzzleapp/bloc/bloc_timer.dart';
import 'package:puzzleapp/db/realtime_db.dart';
import 'dart:ui' as ui;
import 'package:puzzleapp/model/puzzle.dart';
import 'package:puzzleapp/repository/repository.dart';

class BlocPuzzleBase {}

class UpdateLevelPuzzle extends BlocPuzzleBase {
  late int level;
  UpdateLevelPuzzle({required this.level});
}

class UpdateModePuzzle extends BlocPuzzleBase {
  late int optionMode;
  UpdateModePuzzle({required this.optionMode});
}

class MessUpPuzzle extends BlocPuzzleBase {}

class MovePuzzle extends BlocPuzzleBase {
  late int index;
  MovePuzzle({required this.index});
}

class DownloadImagePuzzle extends BlocPuzzleBase {}

class StopPuzzle extends BlocPuzzleBase {}

class BlocPuzzle {
  final StreamController<BlocPuzzleBase> _input = StreamController();
  StreamSink<BlocPuzzleBase> get sentEvent => _input.sink;

  final StreamController<Puzzle> _puzzleController = StreamController<Puzzle>();
  Stream<Puzzle> get puzzleStream => _puzzleController.stream;

  BlocTimer blocTimer = BlocTimer();
  final Uri imageUrl = Uri.parse('https://picsum.photos/400');
  Puzzle puzzle = Puzzle.voidValues();
  List<int> listTilesCorrect = [];

  BlocPuzzle() {
    messUpPuzzle(level: 1);
    //downloadImage();
    selectImageAseets();
    _input.stream.listen(_onEvent);
  }

  void _onEvent(BlocPuzzleBase event) {
    if (event is UpdateLevelPuzzle) {
      messUpPuzzle(level: event.level);
    } else if (event is MovePuzzle) {
      movePuzzle(index: event.index);
    } else if (event is MessUpPuzzle) {
      messUpPuzzle(level: puzzle.level);
    } else if (event is DownloadImagePuzzle) {
      puzzle.image = Uint8List.fromList([]);
      update(puzzle: puzzle);
      downloadImage();
    } else if (event is UpdateModePuzzle) {
      puzzle.optionMode = event.optionMode;
      update(puzzle: puzzle);
    } else if (event is StopPuzzle) {}
  }

  Future<void> messUpPuzzle({required int level}) async {
    level = level;
    int numberOfPuzzles = (level + 2) * (level + 2);
    List<int> listTiles = List.generate(numberOfPuzzles, (index) => index);
    listTiles.shuffle();
    //listTiles = [1, 2, 3, 4, 5, 6, 0, 7, 8];

    listTilesCorrect = List.of(listTiles);
    listTilesCorrect.removeWhere((element) => element == 0);
    listTilesCorrect.add(0);

    puzzle.listTiles = listTiles;
    puzzle.moves = 0;
    puzzle.level = level;
    puzzle.percentSolved = 0;

    if (puzzle.image.isNotEmpty) {
      puzzle.listTilesBytes = await divideImage(imageBytes: puzzle.image, parts: puzzle.listTiles.length);
    }

    blocTimer.sentEvent.add(ResetTime());
    blocTimer.sentEvent.add(StartTime());

    update(puzzle: puzzle);
  }

  Future<void> movePuzzle({required int index}) async {
    if (puzzle.percentSolved == 100) return;

    if (puzzle.listTiles[index] == 0) return;

    int indexEmpty = puzzle.listTiles.indexOf(0);
    if (indexEmpty == -1) return;
    if (indexEmpty == index) return;

    int numberOfPuzzles = puzzle.listTiles.length;
    int numberTiles = sqrt(numberOfPuzzles).floor();

    puzzle.moves++;
    if (indexEmpty == index - 1 || indexEmpty == index + 1) {
      puzzle.listTiles[indexEmpty] = puzzle.listTiles[index];
      puzzle.listTiles[index] = 0;
    } else if (indexEmpty == index - numberTiles || indexEmpty == index + numberTiles) {
      puzzle.listTiles[indexEmpty] = puzzle.listTiles[index];
      puzzle.listTiles[index] = 0;
    }

    //percent solved
    int numberOfTilesCorrect = 1;
    for (int i = 0; i < puzzle.listTiles.length; i++) {
      if (puzzle.listTiles[i] == i + 1) {
        numberOfTilesCorrect++;
      }
    }
    puzzle.percentSolved = (numberOfTilesCorrect / puzzle.listTiles.length) * 100;
    update(puzzle: puzzle);
    if (puzzle.percentSolved == 100) {
      blocTimer.sentEvent.add(StopTime());
    }

    //send server moves
    if (Repository().isMultiplayer) {
      Puzzle puzzleSend = Puzzle(
        image: Uint8List(0),
        listTiles: puzzle.listTiles,
        moves: puzzle.moves,
        level: puzzle.level,
        percentSolved: puzzle.percentSolved,
        optionMode: puzzle.optionMode,
        listTilesBytes: [],
        score: 0,
      );
      puzzleSend.listTilesBytes = [];
      RealtimeDB.sendMovesChallenge(puzzle: puzzleSend, uid: Repository().uidSinc, player: Repository().iamPlayer1 ? "1" : "2");
    }
  }

  void startPuzzle({required Puzzle puzzle}) {
    this.puzzle = puzzle;
    //update list correct
    listTilesCorrect = List.of(puzzle.listTiles);
    listTilesCorrect.removeWhere((element) => element == 0);
    listTilesCorrect.add(0);
    //resset time
    blocTimer.sentEvent.add(ResetTime());
    blocTimer.sentEvent.add(StartTime());
    update(puzzle: puzzle);
  }

  void stopPuzzle() {
    blocTimer.sentEvent.add(StopTime());
  }

  void showSolution() async {
    //auto resolve puzzle
    print("show solution");
    if (puzzle.percentSolved == 100) return;
    int i = 0;
    while (puzzle.listTiles.toString() != listTilesCorrect.toString()) {
      i++;
      await Future.delayed(Duration(milliseconds: 500));
      //print("show solution2 $i");
      int indexEmpty = puzzle.listTiles.indexOf(0);
      print("index empty: $indexEmpty");
      if (indexEmpty == -1) return;
      //index avilable move
      List<int> listIndexAvilableMove = [];
      int numberOfPuzzles = puzzle.listTiles.length;
      int size = sqrt(numberOfPuzzles).floor();

      if (indexEmpty == indexEmpty - 1 && indexEmpty % size != 0) {
        listIndexAvilableMove.add(indexEmpty + 1);
      }
      int indexmove = indexEmpty - 1;
      print("index avilable move: $listIndexAvilableMove size: $size");

      movePuzzle(index: indexmove);
      if (i > 5) break;
    }
  }

  void selectImageAseets() async {
    String name = "1.png";
    rootBundle.load('assets/images/$name').then((value) async {
      puzzle.image = value.buffer.asUint8List();
      puzzle.image = puzzle.image;
      puzzle.listTilesBytes = await divideImage(imageBytes: puzzle.image, parts: puzzle.listTiles.length);
      update(puzzle: puzzle);
    });
  }

  Future<Uint8List?> downloadImage() async {
    Uint8List? bytes = null;
    try {
      http.Response response = await http.get(imageUrl);
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
        puzzle.image = bytes;
        puzzle.image = puzzle.image;
        puzzle.listTilesBytes = await divideImage(imageBytes: puzzle.image, parts: puzzle.listTiles.length);
        update(puzzle: puzzle);
      } else {
        print("error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error of red: $e");
    }

    return bytes;
  }

  Future<List<List<int>>> divideImage({required Uint8List imageBytes, required int parts}) async {
    if (imageBytes.length == 0) return [];

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    int width = image.width;
    int height = image.height;

    //if image is not square then resize
    if (width != height) {
      final int sizeNew = width < height ? width : height;
      width = sizeNew;
      height = sizeNew;
      final int initCut = (width - sizeNew) ~/ 2;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(sizeNew.toDouble(), sizeNew.toDouble())));
      canvas.drawPaint(Paint()); //fondo
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(initCut.toDouble(), 0, sizeNew.toDouble(), sizeNew.toDouble()), //src => la posicion (left,top,width,height) donde inicia el recorte de la imagen eje (0, 100, 100, 100)
        Rect.fromLTWH(0, 0, sizeNew.toDouble(), sizeNew.toDouble()), //dst => donde (inicia a pintar left y top) y (tamaño width,height)
        Paint(),
      );

      ui.Picture picture = recorder.endRecording();
      ui.Image img = await picture.toImage(sizeNew, sizeNew); //tamaño de la imagen final
      ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      imageBytes = pngBytes!.buffer.asUint8List();
    }

    List<List<int>> tilesBytes = [];
    //int parts = parts;
    //square root of parts

    int numberTilesHorizontal = sqrt(parts).floor();
    double sizeTileImg = width / numberTilesHorizontal;
    for (int i = 0; i < parts; i++) {
      try {
        final ui.PictureRecorder recorder2 = await ui.PictureRecorder();
        final Canvas canvas2 = await Canvas(recorder2, Rect.fromPoints(Offset(0.0, 0.0), Offset(width.toDouble(), height.toDouble())));

        double letf = i % numberTilesHorizontal * width / numberTilesHorizontal;
        double top = i ~/ numberTilesHorizontal * height / numberTilesHorizontal;
        //print(" left: $letf top: $top");
        canvas2.drawImageRect(
          image,
          Rect.fromLTWH(letf, top, sizeTileImg, sizeTileImg),
          Rect.fromLTWH(0, 0, sizeTileImg, sizeTileImg),
          Paint(),
        );
        ui.Picture picture = await recorder2.endRecording();
        ui.Image img = await picture.toImage(sizeTileImg.toInt(), sizeTileImg.toInt()); //tamaño de la imagen final
        ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

        List<int> list = List.of(pngBytes!.buffer.asUint8List());

        //index 0 is the end tile
        if (i == parts - 1) {
          tilesBytes.insert(0, list);
        } else {
          tilesBytes.add(list);
        }
        picture.dispose();
        img.dispose();
      } catch (e) {
        print("error: $e");
      }
    }
    //print("tiles: ${tilesBytes.length}");

    return tilesBytes;

    /*
    Paint fondoPaint = new Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(width.toDouble(), height.toDouble())));
    canvas.drawPaint(fondoPaint); //fondo

    //canvas.drawImage(image, Offset(0, 0), fondoPaint);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(100, 100, 100, 100), //src => la posicion (left,top,width,height) donde inicia el recorte de la imagen eje (0, 100, 100, 100)
      Rect.fromLTWH(0, 0, 200, 200), //dst => donde (inicia a pintar left y top) y (tamaño width,height)
      fondoPaint,
    );

    ui.Picture picture = recorder.endRecording();
    ui.Image img = await picture.toImage(200, 200); //tamaño de la imagen final
    ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    List<int> list = List.of(pngBytes!.buffer.asUint8List());
    tilesBytes = [];

    setState(() {
      tilesBytes.add(list);
    });
    */
  }

  Future<Uint8List> resizeImage({required Uint8List imageBytes, required int width, required int height}) async {
    Uint8List imageNew = imageBytes;

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    int widthActual = image.width;
    int heightActual = image.height;

    Paint fondoPaint = new Paint()..style = PaintingStyle.fill;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(width.toDouble(), height.toDouble())));
    canvas.drawPaint(fondoPaint); //fondo

    //canvas.drawImage(image, Offset(0, 0), fondoPaint);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, widthActual.toDouble(), heightActual.toDouble()), //src => la posicion (left,top,width,height) donde inicia el recorte de la imagen eje (0, 100, 100, 100)
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), //dst => donde (inicia a pintar left y top) y (tamaño width,height)
      fondoPaint,
    );

    ui.Picture picture = recorder.endRecording();
    ui.Image img = await picture.toImage(width, height); //tamaño de la imagen final
    ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    imageNew = pngBytes!.buffer.asUint8List();

    return imageNew;
  }

  void update({required Puzzle puzzle}) {
    _puzzleController.add(puzzle);
  }

  void dispose() {
    _input.close();
    _puzzleController.close();
  }
}
