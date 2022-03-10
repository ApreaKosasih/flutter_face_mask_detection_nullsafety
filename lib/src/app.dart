import 'package:deteksi_masker/main.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage? imgCamera;
  CameraController? cameraController;
  // bool isWorking = false;
  String result = "";

  initCamera() {
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }

      setState(() {
        cameraController!.startImageStream((imageFromStream) {
          imgCamera = imageFromStream;
          runModelOnFrame();
        });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  runModelOnFrame() async {
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );

    result = "";

    for (var response in recognitions!) {
      result = response["label"];
    }

    setState(() {
      result;
    });
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   centerTitle: true,
        //   title: const Text("Deteksi Masker"),
        // ),
        body: Stack(
          children: [
            SizedBox(
              child: (!cameraController!.value.isInitialized)
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Transform.scale(
                          scale: 1,
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 0,
              bottom: 200,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                          width: 4,
                          color: result == "without_mask"
                              ? Colors.red
                              : result == "with_mask"
                                  ? Colors.green
                                  : Colors.blue)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                child: result == "without_mask"
                    ? const Text(
                        "Masker tidak terdeteksi",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      )
                    : result == "with_mask"
                        ? const Text(
                            "Anda menggunakan masker, Terimakasih",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          )
                        : const Text(
                            "Scanning... \nPosisikan wajah Anda dengan benar",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
