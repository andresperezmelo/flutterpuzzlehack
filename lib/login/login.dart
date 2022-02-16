import 'package:flutter/material.dart';
import 'package:puzzleapp/home/home.dart';
import 'package:puzzleapp/home/traduction_home.dart';

import '../db/hive_dao_local.dart';
import '../db/realtime_db.dart';
import '../model/info.dart';
import '../model/user.dart';
import '../repository/repository.dart';
import '../static/val_statics.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _txtname = TextEditingController();

  bool isLoading = false;
  bool validateUser = true;

  late TraductionHome _traductionHome;

  @override
  void initState() {
    _initUsuer();
    super.initState();
  }

  @override
  void dispose() {
    _txtname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _traductionHome = Localizations.of<TraductionHome>(context, TraductionHome)!;
    return Scaffold(
      backgroundColor: ValStatics.colorPrimary,
      body: SafeArea(
        child: Center(
          child: _welcome(),
        ),
      ),
    );
  }

  Widget _welcome() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: validateUser,
            child: _loading(),
          ),
          Visibility(
            visible: !validateUser,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      "Puzzle",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                    ),
                    child: TextField(
                      controller: _txtname,
                      decoration: InputDecoration(
                        label: Text(_traductionHome.translate("escribasunombre")),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.5),
                        suffixIcon: IconButton(
                          icon: isLoading ? CircularProgressIndicator(strokeWidth: 1) : Icon(Icons.send),
                          splashColor: ValStatics.colorSecondary,
                          onPressed: () {
                            saveUser();
                          },
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      _traductionHome.translate("mensajejuego"),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 1,
              color: Colors.white,
            ),
            Text(
              "looking for user...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  //init user
  Future<void> _initUsuer() async {
    //await HiveDaoLocal.clearData();
    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");
    //print("user: $user");
    if (user.isEmpty) {
      //view new name
      setState(() {
        validateUser = false;
      });
    } else {
      //usuer correct
      Repository().player1 = UserApp.fromJson(user);
      toHome();
    }
  }

  void saveUser() async {
    String name = _txtname.text.trim().toUpperCase();
    if (name.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      UserApp userApp = UserApp(
        uid: UserApp.generateUid(),
        name: name,
        level: 0,
        points: 0,
        createdAt: DateTime.now(),
      );
      Info info = await RealtimeDB.createUser(data: userApp.toJson());

      if (info.status) {
        Repository().player1 = userApp;
        await HiveDaoLocal.setData(id: "user", data: userApp.toJson());

        SnackBar snackBar = SnackBar(
          content: Text("User created successfully"),
          backgroundColor: Colors.green,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.pop(context);
        toHome();
      } else {
        SnackBar snackBar = SnackBar(
          content: Text("Error creating user"),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void toHome() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home()), (route) => false);
  }
}
