import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eye_tracker_app/functions/classifier_camera.dart';
import 'package:eye_tracker_app/riverpod/loading_controller.dart';
import 'package:eye_tracker_app/riverpod/result_controller.dart';
import 'package:path_provider/path_provider.dart';

///This riverpod provider is use to initialze the camera and pre load the model.
///model loading is happened only once
final cameraProvider = FutureProvider<CameraController>((ref) async {
  ///loading the model appropriate model.
  await ref.read(classifire).loadModel();

  ///initialize the camera
  final cameras = await availableCameras();

  ///use the front camera[1]. if needed, back camera[0]
  final camera = cameras[1];
  final controller = CameraController(
    camera,
    ResolutionPreset.low,
    enableAudio: false,
  );
  await controller.initialize();
  await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
  return CameraController(
    camera,

    ///the preset is set as low. app will run slower if the resolution is set to high or medium.
    ResolutionPreset.low,
  )..initialize();
});

///This riverpod provider provides the stream of data from the model.
final imageStreamProvider = StreamProvider.autoDispose<dynamic>((ref) async* {
  ///get the pre initialized model
  final classifireInstance = ref.read(classifire);

  ///get the pre initialized camera instance
  final camera = await ref.watch(cameraProvider.future);

  ///initializing path to save the data
  Directory? path;
  path = await getApplicationDocumentsDirectory();
  final savePath = '${path.path}/save_file.txt';
  final file = File(savePath);
  final sink = file.openWrite();
  sink.write(
      'id,pred_x,pred_y,frameReadTime,preProcessingTime,modelInferenceTime,faceDetectionTime\n');
  int i = 0;

  ///when app closes, dispose the model and the camera instance
  ref.onDispose(() async {
    classifireInstance.dispose();
    await camera.stopImageStream();
    await sink.close();
  });

  ///result preparation with image stream
  yield camera.startImageStream((image) async {
    ///if the model is not busy;
    if (!ref.read(loadingProvider)) {
      ///set => model is busy
      ref.read(loadingProvider.notifier).state = true;

      ///get the result from the model
      final resultNow = await classifireInstance.run(image: image);
      ref.read(resultProvider.notifier).state = resultNow;

      ///add the total time to the 'averageTimeProvider' and write the data to the file
      if (resultNow['totalTime'] != null) {
        ref.read(averageTimeProvider).add(resultNow['totalTime']);
        sink.write(
            '$i,${resultNow['label']},${resultNow['frameReadTime']},${resultNow['preProcessingTime']},${resultNow['modelInferenceTime']},${resultNow['faceDetectionTime']}\n');
        i++;
      }

      ///release the model
      ref.read(loadingProvider.notifier).state = false;
    }
  });
});
