import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
//import 'dart:html' as html;
//import 'dart:io' if (dart.library.html) 'dart:html' as html;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:puzzleapp/images/images.dart';

import './traduction_home.dart';
import '../bloc/bloc_puzzle.dart';
import '../db/hive_dao_local.dart';
import '../db/realtime_db.dart';
import '../model/info.dart';
import '../model/puzzle.dart';
import '../model/user.dart';
import '../repository/repository.dart';
import '../static/val_statics.dart';
import '../widget/animated_number.dart';
import '../widget/progress_bar.dart';
import '../widget/puzzle_widget.dart';
import '../widget/responsive.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  BlocPuzzle _blocPuzzle = BlocPuzzle();

  bool isOnline = false;
  double sizePuzzle = 0;
  double sizeTile = 0;
  int seconds = 0;
  int optionMode = 0;
  int segmentedControlValue = 0;

  //multiplayer
  bool isSearching = false;
  bool isPlaying = false;
  bool isOpenAlertWinner = false;
  bool isInActive = false;
  StreamSubscription<DatabaseEvent>? _subscription = null;
  StreamSubscription<DatabaseEvent>? _subscriptionChallenger = null;
  StreamSubscription<DatabaseEvent>? _subscriptionEndChallenger = null;
  Puzzle puzzleOpponent = Puzzle.voidValues();

  late TraductionHome _traductionHome;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    if (kIsWeb) {
      /*
      html.window.onBeforeUnload.listen((_) {
        //print("page cerrada");
        _blocPuzzle.dispose();
        _subscription?.cancel();
        _subscriptionChallenger?.cancel();
        _subscriptionEndChallenger?.cancel();
        disconnectOnline();
        return null;
      });
      html.window.onUnload.listen((_) {
        //print("Undate update");
        _blocPuzzle.dispose();
        _subscription?.cancel();
        _subscriptionChallenger?.cancel();
        _subscriptionEndChallenger?.cancel();
        disconnectOnline();
        return null;
      });*/
    }

    online();
    super.initState();
  }

  @override
  void dispose() {
    disconnectOnline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        //print("resumed");
        online();
        break;
      case AppLifecycleState.inactive:
        //print("inactive");
        isInActive = true;
        disconnectOnline();
        break;
      case AppLifecycleState.paused:
        //print("paused");
        break;
      case AppLifecycleState.detached:
        //print("detached");
        break;
      case ui.AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    _traductionHome = Localizations.of<TraductionHome>(context, TraductionHome)!;
    //size puzzle
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double size = width > height ? height * 0.9 : width * 0.6;
    if (Responsive.isMobile(context)) {
      size = width * 0.6;
      if (kIsWeb) {
        size = width * 0.85;
      }
    } else if (Responsive.isTablet(context)) {
      size = width * 0.6;
    }
    if (!kIsWeb) {
      size = width * 0.85;
    }
    sizePuzzle = size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ValStatics.colorPrimary,
                ValStatics.colorSecondary,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: _puzzleGamer(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _puzzleGamer() {
    return StreamBuilder<Puzzle>(
        stream: _blocPuzzle.puzzleStream,
        initialData: Puzzle.voidValues(),
        builder: (context, snapshot) {
          Puzzle puzzle = snapshot.data!;
          if (puzzle.percentSolved == 100 && !isPlaying) {
            _modalToFinishLevel(puzzle: puzzle);
          }
          return Responsive(
              mobile: Column(children: [
                SizedBox(height: 20),
                _header(),
                _menu(),
                SizedBox(height: 10),
                _counters(puzzle: puzzle),
                _progress(puzzle: puzzle),
                SizedBox(height: 10),
                _buildPuzzle(puzzle: puzzle),
              ]),
              tablet: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Container(
                          height: sizePuzzle / 4,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              "Puzzle",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        _menu(),
                        _header(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(30),
                      width: sizePuzzle,
                      height: sizePuzzle,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Column(
                          children: [
                            _counters(puzzle: puzzle),
                            _progress(puzzle: puzzle),
                            SizedBox(height: 10),
                            _buildPuzzle(puzzle: puzzle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Container(
                          height: sizePuzzle / 3,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              "Puzzle",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        _menu(),
                        _header(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(30),
                      width: sizePuzzle,
                      height: sizePuzzle,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Column(
                          children: [
                            _counters(puzzle: puzzle),
                            _progress(puzzle: puzzle),
                            SizedBox(height: 10),
                            _buildPuzzle(puzzle: puzzle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ));
        });
  }

  Widget _progress({required Puzzle puzzle, double height = 10}) {
    return SizedBox(
      width: sizePuzzle,
      height: height,
      child: ProgressBar(
        percent: puzzle.percentSolved,
        decoration: BoxDecoration(
          color: ValStatics.colorAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        progressColor: ValStatics.colorSecondary,
        child: Text(
          "${_traductionHome.translate("completado")} ${puzzle.percentSolved.toStringAsFixed(2)}%",
          style: TextStyle(color: puzzle.percentSolved > 55 ? Colors.white.withOpacity(.5) : Colors.black.withOpacity(.5)),
        ),
      ),
    );
  }

  //header
  Widget _header() {
    double position1 = (sizePuzzle / 2) - sizePuzzle;
    double height = (sizePuzzle / 4) + 30;

    return Container(
      width: sizePuzzle,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          ValStatics.colorPrimary,
          ValStatics.colorSecondary,
        ]),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          AnimatedPositioned(
            left: 0,
            duration: Duration(seconds: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _image(
                    width: sizePuzzle / 4.5,
                    height: sizePuzzle / 4.5,
                  ),
                ),
                Text(
                  Repository().player1.name,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            right: puzzleOpponent.listTiles.length > 0 ? 0 : position1,
            duration: Duration(seconds: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    width: sizePuzzle / 4.5,
                    height: sizePuzzle / 4.5,
                    child: PuzzleWidget(
                      listTiles: puzzleOpponent.listTiles,
                      listTilesBytes: puzzleOpponent.listTilesBytes,
                      numberOfTiles: puzzleOpponent.level + 2,
                      sizePuzzle: sizePuzzle / 4.5,
                      optionMode: puzzleOpponent.optionMode,
                      isSolvedCallback: (bool isSolved) {
                        //print("isSolved: $isSolved oppoenent");
                        //the opponent is winner
                        alertWinner(puzzleWinner: puzzleOpponent, name: Repository().player2.name, winner: false);
                      },
                      onTap: (int index) {},
                    ),
                  ),
                ),
                SizedBox(
                  width: sizePuzzle / 4.5,
                  height: 3,
                  child: _progress(puzzle: puzzleOpponent, height: 3),
                ),
                Text(
                  Repository().player2.name,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _image({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      child: _blocPuzzle.puzzle.image.length == 0 ? const Center(child: CircularProgressIndicator()) : Image.memory(_blocPuzzle.puzzle.image),
    );
  }

  //top attempts nad time
  Widget _counters({required Puzzle puzzle}) {
    double size = sizePuzzle;
    return Center(
      child: Container(
        width: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            ValStatics.colorPrimary,
            ValStatics.colorSecondary,
          ]),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        child: Column(
          children: [
            StreamBuilder<int>(
                stream: _blocPuzzle.blocTimer.timerStream,
                initialData: 0,
                builder: (context, snapshot) {
                  seconds = snapshot.data as int;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: size / 4,
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                "${_traductionHome.translate("movimientos")}",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.contain,
                              child: AnimatedNumber(
                                number: _blocPuzzle.puzzle.moves.toDouble(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _level(puzzle: puzzle),
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: size / 4,
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                "${_traductionHome.translate("tiempo")}",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.contain,
                              child: AnimatedNumber(
                                number: seconds.toDouble(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _level({required Puzzle puzzle}) {
    double size = sizePuzzle / 3;

    return Container(
      padding: const EdgeInsets.all(5),
      width: size,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Material(
              elevation: 5,
              color: ValStatics.colorAccent,
              child: InkWell(
                onTap: Repository().isMultiplayer ? null : () => openMenu(),
                splashColor: Colors.amberAccent,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${_traductionHome.translate("nivel")} ${puzzle.level}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          //mode
          //if isMultiplayer is true, show the mode of the opponent
          Repository().isMultiplayer
              ? Container(
                  child: Text(
                    optionMode == 0
                        ? "MIX"
                        : optionMode == 1
                            ? "IMG"
                            : "NUM",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : Container(
                  width: sizePuzzle / 3,
                  height: 21,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CupertinoSlidingSegmentedControl(
                        groupValue: segmentedControlValue,
                        backgroundColor: ValStatics.colorAccent,
                        children: const <int, Widget>{0: Text('MIX'), 1: Text('IMG'), 2: Text('NUM')},
                        onValueChanged: (value) {
                          setState(() {
                            segmentedControlValue = value as int;
                          });
                          changeMode(value as int);
                        }),
                  ),
                )
        ],
      ),
    );
  }

  //reset resolve online
  Widget _menu() {
    return Container(
      width: sizePuzzle,
      decoration: BoxDecoration(
          //color: Colors.blue,
          ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: !Repository().isMultiplayer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      //return pop up
                      showDialog(
                        context: context,
                        builder: (context) {
                          return BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: AlertDialog(
                              title: Text("${_traductionHome.translate("refrescar")}", style: TextStyle(color: Colors.white)),
                              content: Text("${_traductionHome.translate("updateornewimage")}", style: TextStyle(color: Colors.white)),
                              backgroundColor: const Color(0xFF2C2C2C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              actions: [
                                ElevatedButton(
                                  child: Text("${_traductionHome.translate("nuevaimagen")}", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    //newImage();
                                    _blocPuzzle.sentEvent.add(DownloadImagePuzzle());
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  child: Text("${_traductionHome.translate("actualizar")}", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    //messUp();
                                    _blocPuzzle.sentEvent.add(MessUpPuzzle());
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  child: Text("${_traductionHome.translate("cancelar")}", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.refresh),
                    label: Text("${_traductionHome.translate("refrescar")}"),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      openUserOnline();
                    },
                    icon: Icon(Icons.online_prediction_outlined),
                    label: Row(
                      children: [
                        Visibility(
                          visible: isSearching,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 1,
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text("${_traductionHome.translate("enlinea")}"),
                      ],
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      //_blocPuzzle.showSolution();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Images())).then((value) {
                        if (Repository().imageBytes.length > 0) {
                          _blocPuzzle.puzzle.image = Repository().imageBytes;
                          Puzzle puzzle = _blocPuzzle.puzzle;
                          _blocPuzzle.startPuzzle(puzzle: puzzle);
                          _blocPuzzle.messUpPuzzle(level: puzzle.level);
                        }
                      });
                    },
                    icon: Icon(Icons.image),
                    label: Text("${_traductionHome.translate("imagenes")}"),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //visible if is multipalyer
            Visibility(
                visible: Repository().isMultiplayer,
                child: Container(
                  height: 40,
                  width: sizePuzzle,
                  margin: const EdgeInsets.all(20),
                  child: TextButton.icon(
                    onPressed: () {
                      //return pop up
                      showDialog(
                        context: context,
                        builder: (context) {
                          return BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: AlertDialog(
                              title: Text("Retire", style: TextStyle(color: Colors.white)),
                              content: Text("Sure you want to retire?", style: TextStyle(color: Colors.white)),
                              backgroundColor: const Color(0xFF2C2C2C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              actions: [
                                ElevatedButton(
                                  child: Text("Yes"),
                                  onPressed: () {
                                    retireOfChallenge(winner: false);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  child: Text("Cancel"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.exit_to_app),
                    label: Text("Retire"),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  //change mode
  void changeMode(int mode) {
    _blocPuzzle.sentEvent.add(UpdateModePuzzle(optionMode: mode));
    setState(() {
      optionMode = mode;
    });
  }

  //puzzle
  Widget _buildPuzzle({required Puzzle puzzle}) {
    int numberOfTiles = puzzle.level + 2;
    sizeTile = sizePuzzle / numberOfTiles;
    return Container(
      constraints: BoxConstraints(maxWidth: sizePuzzle, maxHeight: sizePuzzle),
      child: PuzzleWidget(
        listTiles: puzzle.listTiles,
        listTilesBytes: puzzle.listTilesBytes,
        numberOfTiles: numberOfTiles,
        sizePuzzle: sizePuzzle,
        optionMode: puzzle.optionMode,
        marging: 2,
        backgroundColor: ValStatics.colorAccent,
        onTap: (int index) {
          _blocPuzzle.sentEvent.add(MovePuzzle(index: index));
        },
        isSolvedCallback: (bool isSolved) {
          //print("isSolved: $isSolved you");
          //you is winner
          alertWinner(puzzleWinner: _blocPuzzle.puzzle, name: Repository().player1.name, winner: true);
        },
      ),
    );
  }

  //open menu pop up of levels
  void openMenu() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: ValStatics.colorSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 1", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 1);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 2", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 2);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 3", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 3);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 4", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 4);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 5", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 5);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 6", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 6);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 7", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 7);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 8", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 8);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 9", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 9);
                  },
                ),
                ListTile(
                  title: Text("${_traductionHome.translate("nivel")} 10", style: TextStyle(color: Colors.white, fontSize: 20)),
                  onTap: () {
                    Navigator.pop(context);
                    _upLevel(level: 10);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _upLevel({required int level}) {
    _blocPuzzle.sentEvent.add(UpdateLevelPuzzle(level: level));
  }

  //show modal finish level
  Future<void> _modalToFinishLevel({required Puzzle puzzle}) async {
    await Future.delayed(Duration(milliseconds: 500));
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ValStatics.colorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            '${_traductionHome.translate("felicitaciones")}',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '${_traductionHome.translate("finnivel")} ${puzzle.level}',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  '${_traductionHome.translate("movimientos")} ${puzzle.moves} ${_traductionHome.translate("en")} $seconds ${_traductionHome.translate("segundos")}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              icon: Icon(Icons.next_plan, color: Colors.white),
              label: Text(
                '${_traductionHome.translate("siguiente")} ${_traductionHome.translate("nivel")}',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _blocPuzzle.sentEvent.add(UpdateLevelPuzzle(level: puzzle.level + 1));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //multi player -------------------------------------
  //open menu pop up of users online
  void openUserOnline() async {
    setState(() {
      isSearching = true;
    });
    List<UserApp> users = await RealtimeDB.getUsersOnline();
    setState(() {
      isSearching = false;
    });
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: ValStatics.colorPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text("${_traductionHome.translate("usuariosonline")}", style: TextStyle(color: Colors.white, fontSize: 20)),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ),
                for (UserApp user in users)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: ListTile(
                      onTap: user.uid != Repository().player1.uid
                          ? () {
                              challangeUser(user: user);
                            }
                          : null,
                      title: Text(user.name, style: TextStyle(color: Colors.white, fontSize: 20)),
                      subtitle: Text("${user.points} ${_traductionHome.translate("puntos")}", style: TextStyle(color: Colors.white, fontSize: 15)),
                      trailing: IconButton(
                        onPressed: user.uid != Repository().player1.uid
                            ? () {
                                challangeUser(user: user);
                              }
                            : null,
                        icon: Icon(Icons.videogame_asset, color: user.uid != Repository().player1.uid ? Colors.white : Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  //challeange with user
  void challangeUser({required UserApp user}) async {
    String selectItem = "L${_traductionHome.translate("nivel")} 1 (3x3)";
    bool valueInsertImage = false;
    bool valueInsertMode = false;
    int points = 3;
    final List<String> items = [
      "${_traductionHome.translate("nivel")} 1 (3x3)",
      "${_traductionHome.translate("nivel")} 2 (4x4)",
      "${_traductionHome.translate("nivel")} 3 (5x5)",
      "${_traductionHome.translate("nivel")} 4 (6x6)",
      "${_traductionHome.translate("nivel")} 5 (7x7)",
      "${_traductionHome.translate("nivel")} 6 (8x8)",
      "${_traductionHome.translate("nivel")} 7 (9x9)",
      "${_traductionHome.translate("nivel")} 8 (10x10)",
      "${_traductionHome.translate("nivel")} 9 (11x11)",
      "${_traductionHome.translate("nivel")} 10 (12x12)",
    ];

    setState(() {
      isSearching = true;
    });
    Puzzle puzzle = Puzzle(
      level: 1,
      score: 0,
      moves: 0,
      optionMode: optionMode,
      listTiles: [1, 2, 3, 5, 4, 6, 8, 7, 0],
      image: Uint8List(0),
      listTilesBytes: [],
      percentSolved: 0,
    );
    setState(() {
      isSearching = false;
    });
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: ValStatics.colorPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(10.0),
            height: MediaQuery.of(context).size.height * 0.8,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text("${_traductionHome.translate("desafio")}", style: TextStyle(color: Colors.white, fontSize: 20)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "${_traductionHome.translate("atras")}",
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            //print("selected: $selectItem");
                            puzzle.level = int.parse(selectItem.split(" ")[1]);
                            if (valueInsertMode) {
                              puzzle.optionMode = _blocPuzzle.puzzle.optionMode;
                            } else {
                              puzzle.optionMode = 2;
                            }
                            if (valueInsertImage) {
                              Uint8List newImage = await _blocPuzzle.resizeImage(imageBytes: _blocPuzzle.puzzle.image, width: 150, height: 150);
                              puzzle.image = newImage;
                            } else {
                              puzzle.optionMode = 2;
                            }

                            int length = (puzzle.level + 2) * (puzzle.level + 2);
                            List<int> listTiles = List.generate(length, (index) => index);
                            listTiles.shuffle();
                            puzzle.listTiles = listTiles;

                            sendChallenge(userApp: user, puzzle: puzzle);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.send, color: Colors.white),
                          label: Text(
                            "${_traductionHome.translate("enviar")} ${_traductionHome.translate("desafio")}",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text("${_traductionHome.translate("seleccioneunnivel")}. (x $points ${_traductionHome.translate("puntos")})",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        )),
                  ),
                  Container(
                    child: ListTile(
                      onTap: () {},
                      title: Text(user.name, style: TextStyle(color: Colors.white, fontSize: 20)),
                      subtitle: Text("${user.points} ${_traductionHome.translate("puntos")}", style: TextStyle(color: Colors.white, fontSize: 15)),
                      trailing: Icon(Icons.person_outline_rounded, color: Colors.white),
                    ),
                  ),
                  Column(children: [
                    CheckboxListTile(
                      value: valueInsertImage,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          valueInsertImage = value!;
                        });
                      },
                      title: Text("${_traductionHome.translate("incluyemiimage")}", style: TextStyle(color: Colors.white, fontSize: 20)),
                      subtitle: Text("${_traductionHome.translate("resizeimage")}. (150 x 150)", style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                    CheckboxListTile(
                      value: valueInsertMode,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          valueInsertMode = value!;
                        });
                      },
                      title: Text("${_traductionHome.translate("modojuego")}", style: TextStyle(color: Colors.white, fontSize: 20)),
                      subtitle: Text("${_traductionHome.translate("modojuegonumerosoimagen")}", style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                    Container(
                      height: sizePuzzle / 2,
                      child: CupertinoPicker(
                        magnification: 1.5,
                        //backgroundColor: Colors.white,
                        itemExtent: 30, //height of each item
                        looping: true,
                        children: items
                            .map((item) => Center(
                                  child: Text(
                                    item,
                                    style: TextStyle(fontSize: 20, color: Colors.white),
                                  ),
                                ))
                            .toList(),
                        onSelectedItemChanged: (index) {
                          setState(() => points = index + 3);
                          selectItem = items[index];
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void sendChallenge({required UserApp userApp, required Puzzle puzzle}) async {
    //puzzle.listTiles = [1, 2, 3, 4, 5, 6, 0, 7, 8];
    Info info = await RealtimeDB.sendChallenge(userApp: userApp, puzzle: puzzle);
    SnackBar snackBar = SnackBar(
      content: Text(info.message),
      backgroundColor: info.status ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  //activate online and disconect
  void online() async {
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    if (user.isNotEmpty) {
      UserApp userApp = UserApp.fromJson(user);
      Info info = await RealtimeDB.setUserOnline(userApp: userApp);
      if (info.status) {
        listenChallenge();
        await RealtimeDB.retireAndEnd(uid: userApp.uid);
        setState(() {
          isOnline = true;
        });
      }
    }
  }

  void disconnectOnline() async {
    //print("disconnect online");
    _subscription?.cancel();
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    if (user.isNotEmpty) {
      UserApp userApp = UserApp.fromJson(user);
      await RealtimeDB.disconnectOnline(userApp: userApp);
    }
    retireOfChallenge(winner: false);
  }

  //listen challenge
  void listenChallenge() async {
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    if (user.isNotEmpty) {
      UserApp userApp = UserApp.fromJson(user);
      final FirebaseDatabase database = FirebaseDatabase.instance;
      final DatabaseReference databaseReference = database.ref().child('challenges/${userApp.uid}');
      Stream<DatabaseEvent> snapshot = await databaseReference.onChildAdded.asBroadcastStream();
      _subscription = snapshot.listen((DatabaseEvent event) async {
        //print("event: ${event.snapshot.value}");
        String idChallenge = event.snapshot.key.toString();
        if (event.snapshot.value != null) {
          if (event.snapshot.value == "true") {
            //void
          } else if (idChallenge.length > 10) {
            //acept challenge
            if (isPlaying) {
              SnackBar snackBar = SnackBar(
                content: Text("They accepted another challenge, you cannot participate because you are in another challenge"),
                backgroundColor: Colors.amber,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              return;
            }
            Repository().iamPlayer1 = true;
            Map<Object?, Object?> map = event.snapshot.value as Map<Object?, Object?>;
            String nameAcepted = map["name"].toString();
            String uidAcepted = map["uid"].toString();
            Repository().player2.name = nameAcepted;
            Repository().player2.uid = uidAcepted;

            Map<Object?, Object?> puzzle = map["puzzle"] as Map<Object?, Object?>;
            List<int> imageList = [];
            if (puzzle["image"] != "[]" && puzzle["image"] != null) {
              imageList = puzzle["image"].toString().replaceAll("[", "").replaceAll("]", "").split(",").map((item) => int.parse(item)).toList();
            }
            Map<String, dynamic> data = {
              "level": puzzle["level"],
              "score": puzzle["score"],
              "optionMode": puzzle["optionMode"],
              "moves": puzzle["moves"],
              "listTiles": puzzle["listTiles"],
              "image": imageList,
              "listTilesBytes": puzzle["listTilesBytes"] ?? [],
              "percentSolved": puzzle["percentSolved"],
            };

            Puzzle puzzleChallenge = Puzzle.fromJson(data);
            //update listTilesBytes if exist
            int parts = (puzzleChallenge.level + 2) * (puzzleChallenge.level + 2);
            List<List<int>> listTilesBytes = [];
            if (imageList.length > 0) {
              listTilesBytes = await _blocPuzzle.divideImage(imageBytes: Uint8List.fromList(puzzleChallenge.image), parts: parts);
            }
            puzzleChallenge.listTilesBytes = listTilesBytes;

            puzzleOpponent = puzzleChallenge;

            alertInitChallenge(name: nameAcepted, uid: uidAcepted, puzzleChallenge: puzzleChallenge);
          } else {
            //new challenge received
            if (isPlaying) {
              SnackBar snackBar = SnackBar(
                content: Text("You can't accept a challenge while playing against another player"),
                backgroundColor: Colors.orange,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              return;
            }
            Map<Object?, Object?> map = event.snapshot.value as Map<Object?, Object?>;
            UserApp userChallenge = UserApp(
              uid: map["uid"] as String,
              name: map["name"] as String,
              points: map["points"] as int,
              level: map["level"] as int,
              createdAt: map["createdAt"] != null ? DateTime.parse(map["createdAt"] as String) : DateTime.now(),
            );
            Repository().player2 = userChallenge;
            Map<Object?, Object?> puzzle = map["puzzle"] as Map<Object?, Object?>;
            List<int> imageList = [];
            if (puzzle["image"] != "[]") {
              imageList = puzzle["image"].toString().replaceAll("[", "").replaceAll("]", "").split(",").map((item) => int.parse(item)).toList();
            }

            Map<String, dynamic> data = {
              "level": puzzle["level"],
              "score": puzzle["score"],
              "optionMode": puzzle["optionMode"],
              "moves": puzzle["moves"],
              "listTiles": puzzle["listTiles"],
              "image": imageList,
              "listTilesBytes": puzzle["listTilesBytes"] ?? [],
              "percentSolved": puzzle["percentSolved"],
            };

            Puzzle puzzleChallenge = Puzzle.fromJson(data);
            int parts = (puzzleChallenge.level + 2) * (puzzleChallenge.level + 2);
            List<List<int>> listTilesBytes = [];
            if (imageList.length > 0) {
              listTilesBytes = await _blocPuzzle.divideImage(imageBytes: Uint8List.fromList(puzzleChallenge.image), parts: parts);
            }
            puzzleChallenge.listTilesBytes = listTilesBytes;
            openAceptChallenge(userChallenge: userChallenge, puzzleChallenge: puzzleChallenge, idChallenge: idChallenge);
          }
        }
      });

      //read event from stream
      /*await for (var event in snapshot) {
        if (event.snapshot.value != null) {
          //Map<String, dynamic> data = event.snapshot.value;
          print("data: ${event.snapshot.value}");
          if (event.snapshot.value != "true") {
            Map<Object?, Object?> map = event.snapshot.value as Map<Object?, Object?>;
            Map<String, dynamic> data = {
              "level": map["level"],
              "score": map["score"],
              "optionMode": map["optionMode"],
              "moves": map["moves"],
              "listTiles": map["listTiles"],
              "listTilesBytes": map["listTilesBytes"] ?? [],
              "percentSolved": map["percentSolved"],
            };
            print("data2: ${data}");
            openAceptChallenge();
          }
        }
      }*/
    }
  }

  void openAceptChallenge({required UserApp userChallenge, required Puzzle puzzleChallenge, required String idChallenge}) async {
    //return modal acept challenge
    //print("open acept challenge");
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    if (user.isNotEmpty) {
      UserApp userApp = UserApp.fromJson(user);

      //return alert dialog
      return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: Text("${_traductionHome.translate("nuevodesafio")} ${_traductionHome.translate("nivel")} ${puzzleChallenge.level}", style: TextStyle(fontSize: 20, color: Colors.white)),
                backgroundColor: ValStatics.colorPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${_traductionHome.translate("desafiode")} ${userChallenge.name}", style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: sizePuzzle / 2,
                        height: sizePuzzle / 2,
                        child: PuzzleWidget(
                          isSolvedCallback: (bool value) {},
                          listTiles: puzzleChallenge.listTiles,
                          listTilesBytes: puzzleChallenge.listTilesBytes,
                          numberOfTiles: puzzleChallenge.level + 2,
                          optionMode: puzzleChallenge.optionMode,
                          onTap: (int index) {},
                          sizePuzzle: sizePuzzle / 2,
                        ),
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text("${_traductionHome.translate("aceptar")}", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      //accept challenge
                      //update puzzle for oppoenent
                      _blocPuzzle.puzzle.image = puzzleChallenge.image;
                      puzzleOpponent.image = Uint8List.fromList(List.from(puzzleChallenge.image));
                      puzzleOpponent.listTilesBytes = List.from(puzzleChallenge.listTilesBytes);
                      //print("-->puzzleOpponent: ${puzzleOpponent.listTilesBytes.length}");
                      aceptChallenge(userChallenge, puzzleChallenge, idChallenge);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                  TextButton(
                    child: Text("${_traductionHome.translate("cancelar")}", style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      await RealtimeDB.rejectedChallenge(userApp: userApp, idChallenge: idChallenge);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              );
            });
          });
    }
  }

  //acept challenge on listener
  void aceptChallenge(UserApp userChallenge, Puzzle puzzleChallenge, String idChallenge) async {
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    if (user.isNotEmpty) {
      UserApp userApp = UserApp.fromJson(user);
      Repository().player2 = userChallenge;
      Repository().player1 = userApp;

      Info info = await RealtimeDB.acceptChallenge(userApp: userApp, userChallenge: userChallenge, puzzle: puzzleChallenge);
      await RealtimeDB.rejectedChallenge(userApp: userApp, idChallenge: idChallenge);
      if (info.status) {
        Repository().iamPlayer1 = false;
        optionMode = puzzleChallenge.optionMode;

        alertInitChallenge(name: "", uid: userApp.uid, puzzleChallenge: puzzleChallenge);
      } else {
        print("Error: ${info.message}");
        SnackBar snackBar = SnackBar(
          content: Text("Error: ${info.message}"),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void alertInitChallenge({required String name, required String uid, required Puzzle puzzleChallenge}) async {
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    int seconds = 10;
    isPlaying = true;
    //print("listTilesOpponent: ${puzzleOpponent.listTiles}");
    if (user.isNotEmpty) {
      //UserApp userApp = UserApp.fromJson(user);
      listenMovesOppenent(uid: uid, puzzleChallenge: puzzleChallenge);

      return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              if (seconds == 10) {
                Timer.periodic(Duration(seconds: 1), (timer) {
                  if (this.mounted) {
                    setState(() {
                      seconds--;
                    });
                  }
                  if (seconds <= 0) {
                    timer.cancel();
                    _blocPuzzle.startPuzzle(puzzle: puzzleChallenge);
                    Navigator.pop(context);
                  }
                });
              }

              return BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AlertDialog(
                  title: Text("${_traductionHome.translate("desafio")}", style: TextStyle(fontSize: 20, color: Colors.white)),
                  backgroundColor: ValStatics.colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${_traductionHome.translate("desafiode")} $name ${_traductionHome.translate("aceptado")}", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 10),
                      Text("${_traductionHome.translate("juegoiniciaen")}", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 10),
                      SizedBox(
                        width: sizePuzzle / 3,
                        height: sizePuzzle / 3,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: AnimatedOpacity(
                            opacity: seconds % 2 == 0 ? 1 : 0,
                            duration: Duration(seconds: 1),
                            child: Text("$seconds", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      AnimatedOpacity(
                        opacity: seconds % 2 == 0 ? 1 : 0,
                        duration: Duration(milliseconds: 400),
                        child: Text("${_traductionHome.translate("segundos")}", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            });
          });
    }
  }

  //listen moves opponent
  void listenMovesOppenent({required String uid, required Puzzle puzzleChallenge}) async {
    //print("uid: $uid");
    Repository().uidSinc = uid;
    setState(() {
      Repository().isMultiplayer = true;
    });

    final FirebaseDatabase database = FirebaseDatabase.instance;
    String player = Repository().iamPlayer1 ? "2" : "1"; //listen moves opponent
    String path = "moves/$uid/$player";
    final DatabaseReference databaseReference = database.ref().child(path);
    Stream<DatabaseEvent> snapshot = await databaseReference.onValue.asBroadcastStream();
    _subscriptionChallenger = snapshot.listen((DatabaseEvent event) async {
      //print("event.snapshot.value: ${event.snapshot.value}");
      if (event.snapshot.value != null) {
        //print("event.snapshot.value2: ${event.snapshot.value}");
        Map<Object?, Object?> puzzle = event.snapshot.value as Map<Object?, Object?>;
        List<int> imageList = [];
        if (puzzle["image"] != "[]" && puzzle["image"] != null) {
          imageList = puzzle["image"].toString().replaceAll("[", "").replaceAll("]", "").split(",").map((item) => int.parse(item)).toList();
        }
        Map<String, dynamic> data = {
          "level": puzzle["level"],
          "score": puzzle["score"],
          "optionMode": puzzle["optionMode"],
          "moves": puzzle["moves"],
          "listTiles": puzzle["listTiles"],
          "image": imageList,
          "listTilesBytes": puzzle["listTilesBytes"] ?? [],
          "percentSolved": puzzle["percentSolved"],
        };

        Puzzle puzzleChallenge = Puzzle.fromJson(data);
        int parts = (puzzleChallenge.level + 2) * (puzzleChallenge.level + 2);
        List<List<int>> listTilesBytes = [];
        if (imageList.length > 0) {
          listTilesBytes = await _blocPuzzle.divideImage(imageBytes: Uint8List.fromList(puzzleChallenge.image), parts: parts);
        }
        puzzleChallenge.listTilesBytes = listTilesBytes;

        //cache mage and listiTilesBytes
        puzzleChallenge.image = puzzleOpponent.image;
        puzzleChallenge.listTilesBytes = puzzleOpponent.listTilesBytes;

        if (this.mounted) {
          setState(() {
            puzzleOpponent = puzzleChallenge;
          });
        }
      }
    });

    //listen if retired o winner opponent
    listenOfEndOrRetireOpponent();
  }

  void listenOfEndOrRetireOpponent() async {
    String uid = Repository().uidSinc;
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = "moves/$uid";
    final DatabaseReference databaseReference = database.ref().child(path);
    Stream<DatabaseEvent> snapshot = await databaseReference.onChildRemoved.asBroadcastStream();
    _subscriptionEndChallenger?.cancel();
    _subscriptionEndChallenger = snapshot.listen((event) {
      //the opponent is retired you is winner
      //print("end or retired opponent");
      alertWinner(puzzleWinner: _blocPuzzle.puzzle, name: Repository().player1.name, winner: true);
    });
  }

  void alertWinner({required Puzzle puzzleWinner, required String name, required bool winner}) async {
    //print("alertWinner");
    if (isOpenAlertWinner) return;
    isOpenAlertWinner = true;
    retireOfChallenge(winner: winner);
    await Future.delayed(Duration(milliseconds: 500));

    Timer? timer = null;
    int _seconds = 0;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            if (timer == null) {
              timer = Timer.periodic(Duration(seconds: 1), (timer) {
                if (this.mounted) {
                  setState(() {
                    _seconds++;
                  });
                }
              });
            }
            return BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                title: ListTile(
                  title: Text("${_traductionHome.translate("ganador")}", style: TextStyle(fontSize: 20, color: Colors.white)),
                  trailing: IconButton(
                      onPressed: () {
                        timer?.cancel();
                        isPlaying = false;
                        isOpenAlertWinner = false;
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close, color: Colors.white)),
                ),
                backgroundColor: winner ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${_traductionHome.translate("elganadores")}", style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10),
                    SizedBox(
                      width: sizePuzzle / 3,
                      height: sizePuzzle / 4,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: AnimatedOpacity(
                          opacity: _seconds % 2 == 0 ? 1 : 0.5,
                          duration: Duration(seconds: 1),
                          child: Text("$name", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 10),
                    Text("${_traductionHome.translate("ganocon")} ${puzzleWinner.moves} ${_traductionHome.translate("movimientos")} ${_traductionHome.translate("en")} $seconds ${_traductionHome.translate("segundos")}", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          });
        });
  }

  void retireOfChallenge({required bool winner}) async {
    //print("retireOfChallenge");
    puzzleOpponent = Puzzle.voidValues();
    Repository().isMultiplayer = false;
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    UserApp userApp = UserApp.fromJson(user);
    if (winner) {
      userApp.points = userApp.points + _blocPuzzle.puzzle.level + 2;
      await HiveDaoLocal.setData(id: "user", data: userApp.toJson());
      await RealtimeDB.createUser(data: userApp.toJson());
    }
    _subscriptionChallenger?.cancel();
    _subscriptionEndChallenger?.cancel();
    _blocPuzzle.stopPuzzle();
    await RealtimeDB.retireAndEnd(uid: Repository().uidSinc);
    if (!isInActive) await RealtimeDB.setUserOnline(userApp: userApp);
    _blocPuzzle.messUpPuzzle(level: 1);
    if (this.mounted) {
      setState(() {
        isPlaying = false;
      });
    }
  }
}
