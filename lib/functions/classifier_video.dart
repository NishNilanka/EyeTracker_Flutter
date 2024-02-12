///This is same as the classifier_camera.dart. This is used for the video image inference.
///This may be may be removed after some refactoring
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:eye_tracker_app/functions/nms.dart';
import 'package:eye_tracker_app/functions/recognitions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

final classifireVideo =
    StateProvider<ClassifierVideo>((ref) => ClassifierVideo());

class ClassifierVideo {
  dynamic session;
  dynamic faceSession;
  final shape = [1, 128, 128, 1];
  final faceShape = [1, 3, 240, 320];
  int frameReadTime = 0;
  int faceDetectionTime = 0;
  int preProcessingTime = 0;
  int modelInferenceTime = 0;
  int totalTime = 0;
  String path = '';

  Future<void> loadModel() async {
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    const assetFileName = 'assets/model/onnxmodel.onnx';
    final rawAssetFile = await rootBundle.load(assetFileName);
    final bytes = rawAssetFile.buffer.asUint8List();
    session = OrtSession.fromBuffer(bytes, sessionOptions);
    final directory = await getApplicationDocumentsDirectory();
    path = directory.path;

    final faceSessionOptions = OrtSessionOptions();
    const faceAssetFileName = 'assets/model/facemodel1.onnx';
    final faceRawAssetFile = await rootBundle.load(faceAssetFileName);
    final faceBytes = faceRawAssetFile.buffer.asUint8List();
    faceSession = OrtSession.fromBuffer(faceBytes, faceSessionOptions);
  }

  Future<Map<String, dynamic>> run({required String link}) async {
    final stopwatch = Stopwatch()..start();
    final imageI = await img.decodePngFile(link);

    ///for the video image, the image needed to be saved to get the face detection done.
    ///otherwise the faces are not detected for some unknown reason.
    //final file = File(link);

    // file.writeAsBytesSync(image);
    frameReadTime = stopwatch.elapsedMilliseconds;
    final faceImage = img.copyResize(
      imageI!,
      width: 240,
      height: 320,
    );

    ///get the face detection
    final List<Recognition> faces = await getFace(faceImage);

    if (faces.isNotEmpty) {
      //final Rect faceBox = faces[0].boundingBox;
      faceDetectionTime = stopwatch.elapsedMilliseconds;

      ///image pre-processing step
      final stopwatchPreProcessing = Stopwatch()..start();
      // final decodedImage = await convertCameraImageToImage(image);
      final croppedImage = img.copyCrop(
        imageI,
        x: (faces[0].location!.left * imageI.width).toInt(),
        y: (faces[0].location!.top * imageI.height).toInt(),
        width: (faces[0].location!.width * imageI.width).toInt(),
        height: (faces[0].location!.height * imageI.height).toInt(),
      );

      //final correctedImage = img.copyRotate(croppedImage, angle: -90);
      final grayImage = img.grayscale(croppedImage);
      final resizedImage = img.copyResize(
        grayImage,
        width: 128,
        height: 128,
      );
      stopwatchPreProcessing.stop();
      preProcessingTime = stopwatchPreProcessing.elapsedMilliseconds;

      ///start preparing the model for inference
      final stopwatchInference = Stopwatch()..start();
      final imageBuffer =
          await _imageToByteListFloat32(resizedImage, 128, 127.5, 127.5);

      final inputOrt =
          OrtValueTensor.createTensorWithDataList(imageBuffer, shape);

      final inputs = {'conv2d_47_input': inputOrt};
      final runOptions = OrtRunOptions();
      final outputs = await session.runAsync(runOptions, inputs);

      final result = outputs![0]?.value as List;
      await inputOrt.release();
      await runOptions.release();
      await outputs?.forEach((element) async {
        await element?.release();
      });
      stopwatchInference.stop();
      modelInferenceTime = stopwatchInference.elapsedMilliseconds;

      ///prepare the output data to return
      final label = "${result[0][0].toString()} , ${result[0][1].toString()}";
      final resultImage = img.encodeJpg(croppedImage);
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
      return {'image': img.encodePng(imageI)};
    }
  }

  Future<void> dispose() async {
    await OrtEnv.instance.release();
  }

  ///this function helps to decode image into UintBytes. This will be the input buffer of the ML model.
  Future<Float32List> _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) async {
    var convertedBytes = Float32List(inputSize * inputSize);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(i, j);
        buffer[pixelIndex++] = img.getLuminance(pixel) / 255;
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

  Future<List<Recognition>> getFace(img.Image cameraImage) async {
    // final input = InputImage.fromFile(cameraImage);
    // //   final bytes = Uint8List.fromList(img.encodePng(cameraImage));
    // final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.fast);
    // final faceDetector = FaceDetector(options: options);
    // final List<Face> faces = await faceDetector.processImage(input);
    // await faceDetector.close();
    // imageCache.clear();
    // imageCache.clearLiveImages();
    // return faces;

    ///this is with custom model

    final faceImageBuffer =
        await _imageToByteListFloat32Color(cameraImage, 240, 320, 127.5, 127.5);

    final inputOrt =
        OrtValueTensor.createTensorWithDataList(faceImageBuffer, faceShape);

    final inputs = {'input': inputOrt};
    final runOptions = OrtRunOptions();
    final outputs = await faceSession.runAsync(runOptions, inputs);

    final scores = outputs![0]?.value as List;
    final boxes = outputs![1]?.value as List;
    await inputOrt.release();
    await runOptions.release();
    await outputs?.forEach((element) async {
      await element?.release();
    });
    List<Recognition> recognitions = List.empty(growable: true);

    for (int i = 0; i < scores[0].length; i++) {
      // print(scores[0][i]);
      if (scores[0][i][1] > 0.1) {
        final recognition = Recognition(
            i,
            'face',
            scores[0][i][1],
            Rect.fromLTRB(boxes[0][i][0], boxes[0][i][1], boxes[0][i][2],
                boxes[0][i][3]));
        recognitions.add(recognition);
      }
    }
    final face = nms(recognitions, ['face'], 0.4);

    return face;
  }

  Future<Float32List> _imageToByteListFloat32Color(
      img.Image image, int width, int heigth, double mean, double std) async {
    var convertedBytes = Float32List(1 * width * heigth * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    final size = width * heigth;
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < heigth; j++) {
        var pixel = image.getPixel(i, j);
        buffer[pixelIndex] = (pixel.r - mean) / std;
        buffer[size + pixelIndex] = (pixel.g - mean) / std;
        buffer[(2 * size) + pixelIndex] = (pixel.b - mean) / std;
        pixelIndex++;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
