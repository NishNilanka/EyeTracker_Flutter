///This is same as pick_camera_imagestream.dart and this is used for running the model from video file.
import 'dart:io';
import 'package:eye_tracker_app/functions/classifier_video.dart';
import 'package:eye_tracker_app/riverpod/loading_controller.dart';
import 'package:eye_tracker_app/riverpod/result_controller.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final videoController = FutureProvider.autoDispose(
  (ref) async {
    await ref.read(classifireVideo).loadModel();
  },
);

final videoImageProvider = StreamProvider.autoDispose((ref) async* {
  final classifire = ref.read(classifireVideo);
  ref.read(endResult.notifier).state = false;
  classifire.loadModel();
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.video,
  );
  String videoPath = '';
  if (result != null) {
    final file = result.files.first;
    videoPath = file.path!;
  } else {
    yield null;
  }
  Directory? path;
  path = await getApplicationDocumentsDirectory();
  String command = '-i $videoPath -f image2 ${path.path}/%4d.png';
  final savePath = '${path.path}/save_file.txt';
  await FFmpegKit.execute(command).then((session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      print('========================${path!.path}');
    } else {
      print('=========================$returnCode');
    }
  });
  await FFmpegKit.cancel();
  final file = File(savePath);
  final sink = file.openWrite();
  sink.write(
      'id,pred_x,pred_y,frameReadTime,preProcessingTime,modelInferenceTime,faceDetectionTime\n');

  ref.onDispose(() async {
    await sink.close();
    int j = 1;
    while (File('${path!.path}/${j.toString().padLeft(4, '0')}.png')
        .existsSync()) {
      final deleteFile =
          File('${path.path}/${j.toString().padLeft(4, '0')}.png');
      await deleteFile.delete();
      j++;
    }
  });
  int i = 1;
  while (
      File('${path.path}/${i.toString().padLeft(4, '0')}.png').existsSync()) {
    if (!ref.read(loadingProvider)) {
      ref.read(loadingProvider.notifier).state = true;
      imageCache.clear();
      imageCache.clearLiveImages();
      // if (i % 50 == 0) {
      //   await classifire.dispose();
      //   Future.delayed(const Duration(seconds: 1), () async {
      //     await classifire.loadModel();
      //   });
      // }
      final resultNow = await classifire.run(
          link: '${path.path}/${i.toString().padLeft(4, '0')}.png');
      yield ref.read(resultProvider.notifier).state = resultNow;
      if (resultNow['totalTime'] != null) {
        ref.read(averageTimeProvider).add(resultNow['totalTime']);
        sink.write(
            '$i,${resultNow['label']},${resultNow['frameReadTime']},${resultNow['preProcessingTime']},${resultNow['modelInferenceTime']},${resultNow['faceDetectionTime']}\n');
        i++;
      }
      ref.read(loadingProvider.notifier).state = false;
    }
  }
  await sink.close();
  ref.read(endResult.notifier).state = true;
});
