# Flutter Firebase ML Kit Vision Api Usage

In this project, firebase machine learning API was used to synthesize images and faces and detect text in the image.

There are no local ml_kit files in the application, all operations occur via API.

# Guide to Obtain JSON Credentials for Firebase Vision API on Google Cloud Platform

You can find detailed instructions on obtaining the credential JSON file [here](https://daminion.net/docs/how-to-get-google-cloud-vision-api-key/).

### Usage of the Cloud Vision API

```dart
final googleVision =
    await GoogleVision.withJwt('my_jwt_credentials.json');

final image =
    Image.fromFilePath('example/young-man-smiling-and-thumbs-up.jpg');

// cropping an image can save time uploading the image to Google
final cropped = painter.copyCrop(70, 30, 640, 480);

// to see the cropped image
await cropped.writeAsJpeg('example/cropped.jpg');

final requests = AnnotationRequests(requests: [
  AnnotationRequest(image: cropped, features: [
    Feature(maxResults: 10, type: 'FACE_DETECTION'),
    Feature(maxResults: 10, type: 'OBJECT_LOCALIZATION')
  ])
]);

final annotatedResponses =
    await googleVision.annotate(requests: requests);

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
                cropped.width)
            .toInt(),
        (localizedObjectAnnotation.boundingPoly.normalizedVertices.first.y *
                    cropped.height)
                .toInt() -
            16,
        'Person - ${localizedObjectAnnotation.score}');

    GoogleVision.drawAnnotationsNormalized(
        cropped, localizedObjectAnnotation.boundingPoly.normalizedVertices);
  });
}

// output the results as a new image file
await cropped.writeAsJpeg('resulting_image.jpg');
```