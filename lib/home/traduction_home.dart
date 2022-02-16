import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class TraductionHome {
  late final String localeName;
  TraductionHome(this.localeName);

  static const LocalizationsDelegate<TraductionHome> delegate = _TraductionDelegate();

  late Map<String, dynamic> _localizedStrings = {};

  Future load() async {
    String jsonString = await rootBundle.loadString('assets/locales/${localeName}.json');
    _localizedStrings = jsonString.isNotEmpty ? jsonDecode(jsonString) : {};
  }

  String translate(String key) {
    return _localizedStrings[key] ?? '** $key not found **';
  }
}

class _TraductionDelegate extends LocalizationsDelegate<TraductionHome> {
  const _TraductionDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<TraductionHome> load(Locale locale) async {
    var t = TraductionHome(locale.languageCode);
    await t.load();
    return t;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<TraductionHome> old) {
    //para ver que si hay que cargar el idioma
    return false;
  }
}
