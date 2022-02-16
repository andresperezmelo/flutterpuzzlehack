import 'dart:math';

import 'package:flutter/rendering.dart';

class ValStatics {
  static const Color colorPrimary = Color(0xff219ebc); //Color(0xFF4361ee);
  static const Color colorSecondary = Color(0xff8ecae6); //Color(0xFFf72585);
  static const Color colorAccent = Color(0xffe2ece9); //Color(0xFFf72585);

  static get getRamdomId {
    return Random().nextInt(1000000) + 100;
  }
}
