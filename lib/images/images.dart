import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzleapp/home/traduction_home.dart';
import 'package:puzzleapp/repository/repository.dart';
import 'package:puzzleapp/static/val_statics.dart';

class Images extends StatefulWidget {
  const Images({Key? key}) : super(key: key);

  @override
  _ImagesState createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  List<String> imagesAssets = [];
  Uint8List imageSelected = Uint8List(0);
  String imageSelectedName = '';

  late TraductionHome traductionHome;

  @override
  void initState() {
    getImagesAssets();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    traductionHome = Localizations.of<TraductionHome>(context, TraductionHome)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text("${traductionHome.translate("imagenes")}", style: TextStyle(color: Colors.white)),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
            imageSelectedName.length > 0
                ? Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: MemoryImage(imageSelected),
                        fit: BoxFit.cover,
                        isAntiAlias: false,
                      ),
                    ),
                    //child: Image.memory(imageSelected),
                  )
                : Container(),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ValStatics.colorAccent,
                  ValStatics.colorPrimary,
                ],
              ),
            ),
            child: Wrap(
              children: [
                for (String image in imagesAssets) imageView(image),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget imageView(String imagePath) {
    double size = MediaQuery.of(context).size.width * 0.5;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: imagePath == imageSelectedName ? size - 10 : size,
      height: imagePath == imageSelectedName ? size - 10 : size,
      padding: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final ByteData bytes = await rootBundle.load(imagePath);
              Repository().imageBytes = bytes.buffer.asUint8List();
              setState(() {
                imageSelected = bytes.buffer.asUint8List();
                imageSelectedName = imagePath;
              });
            },
            splashColor: ValStatics.colorPrimary.withOpacity(0.5),
            child: Ink.image(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              width: size,
              child: Visibility(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
                visible: imagePath == imageSelectedName,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getImagesAssets() async {
    //List<Uint8List> imagesOfline = <Uint8List>[];
    Repository().imageBytes = Uint8List(0);
    List<String> imagesOfline = <String>[];
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifest = json.decode(manifestContent);
    //print("manifest: $manifest");
    final Map<String, dynamic> imageNames = manifest;
    for (List imageName in imageNames.values) {
      String folder = imageName[0].split('/')[1];
      //print("folder: $folder imagename: $imageName");
      if (folder == 'images') {
        imagesOfline.add(imageName[0].toString());
      }
      //final ByteData bytes = await rootBundle.load(imageName[0]);
      //final Uint8List image = bytes.buffer.asUint8List();
      //imagesOfline.add(image);
    }

    setState(() {
      imagesAssets = imagesOfline;
    });
  }
}
