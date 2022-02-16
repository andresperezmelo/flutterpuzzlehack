import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:puzzleapp/home/traduction_home.dart';
import 'firebase_options.dart';
import 'package:puzzleapp/login/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle app',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        // ... delegado[s] de localización específicos de la app aquí
        TraductionHome.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'), // Inglés
        const Locale('es'), // Español
        //const Locale.fromSubtags(languageCode: 'zh'), // Chino *Mira Localizaciones avanzadas más abajo*
        // ... otras regiones que la app soporte
      ],
      //locale: Locale('en'),
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: const Login(),
    );
  }
}
