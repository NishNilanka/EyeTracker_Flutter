import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

///this provider save the current frame total time result so it can output the average frame result.
final resultProvider = StateProvider.autoDispose<Map>((ref) => {});

class AverageTime extends StateNotifier<List<int>> {
  AverageTime() : super([]);

  void add(int item) {
    state = [...state, item]; // Add new item to the beginning for FIFO behavior
  }
}

final averageTimeProvider =
    StateNotifierProvider<AverageTime, List<int>>((ref) => AverageTime());

final endResult = StateProvider<bool>((ref) => false);

final resultSummery = FutureProvider<Map?>((ref) async {
  final end = ref.watch(endResult);
  List<double> frameRead = [];
  List<double> preProcessing = [];
  List<double> modelInference = [];
  List<double> faceDetection = [];

  if (end == true) {
    final appPath = await getApplicationDocumentsDirectory();
    final file = File('${appPath.path}/save_file.txt');
    if (file.existsSync()) {
      final string = await file.readAsString();
      final stringList = string.split('\n');
      stringList.removeAt(0);
      stringList.removeAt(stringList.length - 1);
      for (var item in stringList) {
        final data = item.split(',');
        frameRead.add(double.parse(data[3]));
        preProcessing.add(double.parse(data[4]));
        modelInference.add(double.parse(data[5]));
        faceDetection.add(double.parse(data[6]));
      }
      final frAvg = frameRead.average.floorToDouble();
      final proAvg = preProcessing.average.floorToDouble();
      final infAvg = modelInference.average.floorToDouble();
      final faceAvg = faceDetection.average.floorToDouble();
      final totalAverageTime = frAvg + proAvg + infAvg + faceAvg;

      return {
        'total': totalAverageTime,
        'frameRead': frAvg,
        'preProcessing': proAvg,
        'modelInference': infAvg,
        'faceDetection': faceAvg,
      };
    } else {
      return null;
    }
  } else {
    return null;
  }
});
