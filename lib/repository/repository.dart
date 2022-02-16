import 'dart:typed_data';

import 'package:puzzleapp/model/user.dart';

class Repository {
  Repository._();
  static final Repository _singleton = Repository._();
  factory Repository() => _singleton;

  bool isMultiplayer = false;
  bool iamPlayer1 = true;
  String uidSinc = "AAA";

  UserApp player1 = UserApp.voidValues();
  UserApp player2 = UserApp.voidValues();

  Uint8List imageBytes = Uint8List(0);
}
