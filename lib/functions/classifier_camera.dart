import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

///this provider provides the entire business logic for the face detection. preprocessing and model inference.
final classifire = StateProvider<Classifier>((ref) => Classifier());

class Classifier {
  ///initialization of default values for time measurment for each task.
  dynamic session;
  final shape = [1, 128, 128, 1];
  int frameReadTime = 0;
  int faceDetectionTime = 0;
  int preProcessingTime = 0;
  int modelInferenceTime = 0;
  int totalTime = 0;

  Future<void> loadModel() async {
    ///initializing the runtime and loading the model
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();

    ///if model needs to be changes, make sure to add the model to the assets folder
    ///and add the assests in the pubspec.yaml
    ///finally change the assest path to the new model.
    const assetFileName = 'assets/model/onnxmodel.onnx';
    final rawAssetFile = await rootBundle.load(assetFileName);
    final bytes = rawAssetFile.buffer.asUint8List();
    session = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  Future<Map<String, dynamic>> run({required CameraImage image}) async {
    ///start the stopwatch to get the total time
    final stopwatch = Stopwatch()..start();

    ///get the face detection
    final faces = await getFace(image);

    ///if any face is detected;
    if (faces.isNotEmpty) {
      final Rect faceBox = faces[0].boundingBox;
      faceDetectionTime = stopwatch.elapsedMilliseconds;

      ///image pre-processing step start
      final stopwatchPreProcessing = Stopwatch()..start();

      ///convert the camera image to image that is readable by the Image package
      final decodedImage = await convertCameraImageToImage(image);

      ///cropout the detected face
      final croppedImage = img.copyCrop(
        decodedImage!,
        x: faceBox.top.toInt(),
        y: faceBox.left.toInt(),
        width: faceBox.width.toInt(),
        height: faceBox.height.toInt(),
      );

      ///camera images are rotated 90 degrees. So the rotation needed to be fixed.
      final correctedImage = img.copyRotate(croppedImage, angle: -90);

      ///get the gray image
      final grayImage = img.grayscale(correctedImage);

      ///resized in to 128x128 image for the model
      final resizedImage = img.copyResize(
        grayImage,
        width: 128,
        height: 128,
      );
      stopwatchPreProcessing.stop();
      preProcessingTime = stopwatchPreProcessing.elapsedMilliseconds;

      ///start preparing the model for inference
      final stopwatchInference = Stopwatch()..start();

      ///preparing the input for the model
      final imageBuffer =
          await _imageToByteListFloat32(resizedImage, 128, 127.5, 127.5);
      final inputOrt =
          OrtValueTensor.createTensorWithDataList(imageBuffer, shape);
      final inputs = {'conv2d_47_input': inputOrt};

      ///running the model on inputs
      final runOptions = OrtRunOptions();
      final outputs = await session.runAsync(runOptions, inputs);
      final result = outputs![0]?.value as List;

      ///resetting the inputs and outputs

      await inputOrt.release();
      await runOptions.release();
      await outputs?.forEach((element) async {
        await element?.release();
      });
      stopwatchInference.stop();
      modelInferenceTime = stopwatchInference.elapsedMilliseconds;

      ///prepare the output data to return
      final label = "${result[0][0].toString()} , ${result[0][1].toString()}";
      final resultImage = img.encodeJpg(grayImage);
      stopwatch.stop();
      totalTime = stopwatch.elapsedMilliseconds;
      return {
        'image': resultImage,
        'label': label,
        'totalTime': totalTime,
        'modelInferenceTime': modelInferenceTime,
        'faceDetectionTime': faceDetectionTime,
        'preProcessingTime': preProcessingTime,
        'frameReadTime': frameReadTime,
      };
    } else {
      return {};
    }
  }

  ///dispose method
  void dispose() {
    OrtEnv.instance.release();
  }

  ///this function helps to decode image into UintBytes. This will be the input buffer of the ML model.
  Future<Float32List> _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) async {
    var convertedBytes = Float32List(inputSize * inputSize);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getLuminance(pixel) / 255.0;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  Future<img.Image?> convertCameraImageToImage(CameraImage cameraImage) async {
    img.Image image;

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      image = convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      image = convertBGRA8888ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.jpeg) {
      image = convertJPEGToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
      image = convertNV21ToImage(cameraImage);
    } else {
      return null;
    }

    return image;
  }

  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final image = img.Image(width: width, height: height);

    var uvIndex = 0;

    for (var y = 0; y < height; y++) {
      var pY = y * width;
      var pUV = uvIndex;

      for (var x = 0; x < width; x++) {
        final yValue = yPlane[pY];
        final uValue = uPlane[pUV];
        final vValue = vPlane[pUV];

        final r = yValue + 1.402 * (vValue - 128);
        final g =
            yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
        final b = yValue + 1.772 * (uValue - 128);

        image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);

        pY++;
        if (x % 2 == 1 && uvPixelStride == 2) {
          pUV += uvPixelStride;
        } else if (x % 2 == 1 && uvPixelStride == 1) {
          pUV++;
        }
      }

      if (y % 2 == 1) {
        uvIndex += uvRowStride;
      }
    }
    return image;
  }

  img.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final bytes = cameraImage.planes[0].bytes;

    // Create a new Image instance
    final image = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.rgba,
    );

    return image;
  }

  img.Image convertJPEGToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final bytes = cameraImage.planes[0].bytes;

    // Create a new Image instance from the JPEG bytes
    final image = img.decodeImage(bytes);

    return image!;
  }

  img.Image convertNV21ToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final yuvBytes = cameraImage.planes[0].bytes;
    final vuBytes = cameraImage.planes[1].bytes;

    // Create a new Image instance
    final image = img.Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );

    // Convert NV21 to RGB
    convertNV21ToRGB(
      yuvBytes,
      vuBytes,
      cameraImage.width,
      cameraImage.height,
      image,
    );

    return image;
  }

  void convertNV21ToRGB(Uint8List yuvBytes, Uint8List vuBytes, int width,
      int height, img.Image image) {
    // Conversion logic from NV21 to RGB
    // ...

    // Example conversion logic using the `imageLib` package
    // This is just a placeholder and may not be the most efficient method
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final yValue = yuvBytes[yIndex];
        final uValue = vuBytes[uvIndex * 2];
        final vValue = vuBytes[uvIndex * 2 + 1];

        // Convert YUV to RGB
        final r = yValue + 1.402 * (vValue - 128);
        final g =
            yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
        final b = yValue + 1.772 * (uValue - 128);

        // Set the RGB pixel values in the Image instance
        image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
      }
    }
  }

  ///getting the faces in the image
  ///this method use the google_ml_kit_facedetection package
  Future<List<Face>> getFace(CameraImage cameraImage) async {
    final stopwatch = Stopwatch()..start();

    ///preparing the image for the face detection
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final options = FaceDetectorOptions();
    final faceDetector = FaceDetector(options: options);
    final imageInput = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
            bytesPerRow: cameraImage.planes[0].bytesPerRow,
            size: Size(
                cameraImage.width.toDouble(), cameraImage.height.toDouble()),
            rotation: InputImageRotation.rotation270deg,
            format: InputImageFormat.yuv420));
    stopwatch.stop();
    frameReadTime = stopwatch.elapsedMilliseconds;

    ///getting the face detection
    final List<Face> faces = await faceDetector.processImage(imageInput);
    await faceDetector.close();
    return faces;
  }
}
