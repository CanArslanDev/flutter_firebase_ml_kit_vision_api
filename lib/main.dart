import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' as mat show Image;
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:google_vision/google_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Vision Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Google Vision Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _image = '';
  String text = "";

  Future<String> getFileFromAsset(String assetFileName,
      {String? temporaryFileName}) async {
    final byteData = await rootBundle.load('assets/$assetFileName');

    final buffer = byteData.buffer;

    final fileName = temporaryFileName ?? assetFileName;

    final filePath = await getTempFile(fileName);

    try {
      await File(filePath).delete();
    } catch (e) {
      // ignore
    }

    await File(filePath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return filePath;
  }

  Future<String> getTempFile([String? fileName]) async {
    final tempDir = await getTemporaryDirectory();

    return '${tempDir.path}${Platform.pathSeparator}${fileName ?? const Uuid().v4()}';
  }

  void _processText() async {
    text = "";
    final jwtFromAsset = await DefaultAssetBundle.of(context)
        .loadString("assets/service_credentials.json");
    final googleVision = await GoogleVision.withJwt(jwtFromAsset);
    final imageFile = await getFileFromAsset('paragraf.jpg',
        temporaryFileName: 'paragraf.jpg');

    final painter = Painter.fromFilePath(imageFile);

    final requests = AnnotationRequests(requests: [
      AnnotationRequest(
          image: Image(painter: painter),
          features: [Feature(maxResults: 10, type: 'TEXT_DETECTION')])
    ]);

    print('checking...');

    AnnotatedResponses annotatedResponses =
        await googleVision.annotate(requests: requests);

    print('done.\n');
    for (var annotatedResponse in annotatedResponses.responses) {
      for (var textAnnotation in annotatedResponse.textAnnotations) {
        text += '${textAnnotation.description} ';
        GoogleVision.drawText(
            painter,
            textAnnotation.boundingPoly!.vertices.first.x + 2,
            textAnnotation.boundingPoly!.vertices.first.y + 2,
            textAnnotation.description);

        GoogleVision.drawAnnotations(
            painter, textAnnotation.boundingPoly!.vertices);
      }
    }
    print(text);

    final filePath = await getTempFile('paragraf.jpg');
    // await painter.writeAsJpeg('example/debugImage.jpg');
    await painter.writeAsJpeg(filePath);

    setState(() {
      _image = filePath;
    });
  }

  void _processImage() async {
    final jwtFromAsset = await DefaultAssetBundle.of(context)
        .loadString("assets/service_credentials.json");
    final googleVision = await GoogleVision.withJwt(jwtFromAsset);

    final imageFile = await getFileFromAsset(
        'young-man-smiling-and-thumbs-up.jpg',
        temporaryFileName: 'young-man-smiling-and-thumbs-up.jpg');

    final image = Painter.fromFilePath(imageFile);

    final cropped = image.copyCrop(70, 30, 640, 480);

    final filePath =
        await getTempFile('young-man-smiling-and-thumbs-up_cropped.jpg');

    final requests = AnnotationRequests(requests: [
      AnnotationRequest(image: Image(painter: image), features: [
        Feature(maxResults: 10, type: 'FACE_DETECTION'),
        Feature(maxResults: 10, type: 'OBJECT_LOCALIZATION')
      ])
    ]);

    final annotatedResponses = await googleVision.annotate(requests: requests);

    for (var annotatedResponse in annotatedResponses.responses) {
      for (var faceAnnotation in annotatedResponse.faceAnnotations) {
        GoogleVision.drawText(
            cropped,
            faceAnnotation.boundingPoly.vertices.first.x + 2,
            faceAnnotation.boundingPoly.vertices.first.y + 2,
            'Face - ${faceAnnotation.detectionConfidence}');

        GoogleVision.drawAnnotations(
            cropped, faceAnnotation.boundingPoly.vertices);
      }
    }

    for (var annotatedResponse in annotatedResponses.responses) {
      annotatedResponse.localizedObjectAnnotations
          .where((localizedObjectAnnotation) =>
              localizedObjectAnnotation.name == 'Person')
          .toList()
          .forEach((localizedObjectAnnotation) {
        GoogleVision.drawText(
            cropped,
            (localizedObjectAnnotation.boundingPoly.normalizedVertices.first.x *
                    image.width)
                .toInt(),
            (localizedObjectAnnotation.boundingPoly.normalizedVertices.first.y *
                        image.height)
                    .toInt() -
                16,
            'Person - ${localizedObjectAnnotation.score}');

        GoogleVision.drawAnnotationsNormalized(
            cropped, localizedObjectAnnotation.boundingPoly.normalizedVertices);
      });
    }

    await cropped.writeAsJpeg(filePath);

    setState(() {
      text = "";
      _image = filePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Processed image will appear below:\n $text',
              ),
              _image == ''
                  ? const CircularProgressIndicator()
                  : mat.Image.file(
                      File(_image),
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey,
                        width: 100,
                        height: 100,
                        child: const Center(
                          child: Text('Error load image',
                              textAlign: TextAlign.center),
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _processText,
            tooltip: 'Process Image',
            child: const Icon(Icons.text_fields_sharp),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _processImage,
            tooltip: 'Process Image',
            child: const Icon(Icons.image_outlined),
          ),
        ],
      ),
    );
  }
}
