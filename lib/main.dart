import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ImagePicker picker;
  dynamic faceDetector;
  File? img;
  dynamic image;
  late List<Face> faces;
  String result = '';

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableContours: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    );
    faceDetector = FaceDetector(options: options);
  }

  @override
  void dispose() {
    super.dispose();
  }

  imgFromGallery() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      img = File(image.path);
      doFaceDetection();
    }
  }

  imgFromCamera() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      img = File(image.path);
      doFaceDetection();
    }
  }

  doFaceDetection() async {
    InputImage inputImage = InputImage.fromFile(img!);
    faces = await faceDetector.processImage(inputImage);
    print('length: ${faces.length.toString()} 💥💥💥');
    result = '';

    for (Face f in faces) {
      if (f.smilingProbability! > 0.5) {
        result += 'Smiling';
      } else {
        result += 'Serious';
      }
    }
    setState(() {
      img;
      result;
    });
    drawRectangelAroundFaces();
  }

  drawRectangelAroundFaces() async {
    image = await img!.readAsBytes();
    image = await decodeImageFromList(image);
    setState(() {
      image;
      result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: double.infinity,
              ),
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: imgFromGallery,
                        onLongPress: imgFromCamera,
                        /* child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: img != null
                              ? Image.file(
                                  img!,
                                  height: 440,
                                  width: 340,
                                )
                              : Container(
                                  height: 330,
                                  width: 340,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 100,
                                  ),
                                ),
                        ),*/
                        child: Container(
                          width: 335,
                          height: 450,
                          margin: const EdgeInsets.only(top: 30),
                          child: image != null
                              ? Center(
                                  child: FittedBox(
                                    child: SizedBox(
                                      width: image.width.toDouble(),
                                      height: image.height.toDouble(),
                                      child: CustomPaint(
                                        painter: FacePainter(
                                          faceList: faces,
                                          imageFile: image,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  width: 340,
                                  height: 330,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 100,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Text(
                  result,
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Face> faceList;
  dynamic imageFile;
  FacePainter({required this.faceList, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    //For drawing the Rectangle in Faces
    Paint p = Paint();
    p.color = Colors.green;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 10;
    for (Face face in faceList) {
      canvas.drawRect(face.boundingBox, p);
    }

    //For Drawing the point in face contours like eye, mouth etc...
    Paint p2 = Paint();
    p2.color = Colors.green;
    p2.style = PaintingStyle.stroke;
    p2.strokeWidth = 6;
    for (Face face in faceList) {
      Map<FaceContourType, FaceContour?> con = face.contours;
      List<Offset> offsetPoints = <Offset>[];
      con.forEach((key, value) {
        if (value != null) {
          List<Point<int>>? points = value.points;
          for (Point p in points) {
            Offset offset = Offset(p.x.toDouble(), p.y.toDouble());
            offsetPoints.add(offset);
          }
          canvas.drawPoints(PointMode.points, offsetPoints, p2);
        }
      });

      //For Drawing the Rectangle on the left ear.
      Paint p3 = Paint();
      p3.color = Colors.yellow;
      p3.style = PaintingStyle.stroke;
      p3.strokeWidth = 6;
      final FaceLandmark leftEar = face.landmarks[FaceLandmarkType.leftEar]!;
      final Point<int> leftEarPos = leftEar.position;
      canvas.drawRect(
          Rect.fromLTWH(
              leftEarPos.x.toDouble() - 5, leftEarPos.y.toDouble() - 5, 30, 30),
          p3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
