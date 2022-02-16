import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../static/val_statics.dart';

class PuzzleWidget extends StatelessWidget {
  final List<int> listTiles;
  final List<List<int>> listTilesBytes;
  final int numberOfTiles;
  final double sizePuzzle;
  final int optionMode;
  final double marging;
  final Color backgroundColor;
  final Function(int) onTap;
  final Function(bool) isSolvedCallback;

  const PuzzleWidget({
    required this.listTiles,
    required this.listTilesBytes,
    required this.numberOfTiles,
    required this.sizePuzzle,
    required this.optionMode,
    this.marging = 0,
    this.backgroundColor = ValStatics.colorPrimary,
    required this.onTap,
    required this.isSolvedCallback,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //if list of tiles is empty, return empty widget
    if (listTiles.length == 0) return Container();
    List<int> listOrder = List.generate(listTiles.length, (index) => index);
    listOrder.removeWhere((element) => element == 0);
    listOrder.add(0);
    bool isSolved = false;
    if (listOrder.toString() == listTiles.toString()) {
      isSolvedCallback(true);
      isSolved = true;
    }

    //option mode
    bool isMix = optionMode == 0;
    bool isImg = optionMode == 1;
    bool isNum = optionMode == 2;

    double width = sizePuzzle + marging * 2;
    double height = sizePuzzle + marging * 2;
    double widthTile = (width / numberOfTiles) - marging;
    double heightTile = (height / numberOfTiles) - marging;
    double margin = this.marging;

    return Container(
      child: Stack(
        children: [
          for (int i = 0; i < listTiles.length; i++)
            AnimatedPositioned(
              key: Key(listTiles[i].toString()),
              duration: Duration(milliseconds: 500),
              left: i % numberOfTiles * widthTile,
              top: i ~/ numberOfTiles * heightTile,
              child: Material(
                color: this.backgroundColor,
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Container(
                    width: widthTile - margin,
                    height: heightTile - margin,
                    margin: EdgeInsets.all(margin),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(margin * 2),
                      color: listTiles[i] == 0
                          ? Colors.grey.shade300
                          : isNum
                              ? Colors.blue.shade200
                              : Colors.transparent,
                      //border: isSolved ? null : Border.all(width: .2),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        listTilesBytes.length > 0 && listTiles[i] != 0 && isImg || listTilesBytes.length > 0 && listTiles[i] != 0 && isMix || listTilesBytes.length > 0 && isSolved && isMix
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(margin),
                                child: Image.memory(
                                  Uint8List.fromList(listTilesBytes[listTiles[i]]),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              )
                            : Container(),
                        Visibility(
                          visible: isNum || isMix || listTilesBytes.length == 0,
                          child: FittedBox(
                            child: listTiles[i] != 0
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(margin),
                                    child: Text(
                                      listTiles[i].toString(),
                                      style: TextStyle(
                                        color: listTilesBytes.length > 0 ? Colors.black.withOpacity(0.4) : ValStatics.colorPrimary,
                                      ),
                                    ),
                                  )
                                : Container(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
