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
    if (state.length > 10) {
      state = state.sublist(1); // Remove the first item if list exceeds 10
    }
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
      print(stringList.length);
      stringList.removeAt(0);
      stringList.removeAt(stringList.length - 1);
      for (var item in stringList) {
        final data = item.split(',');
        frameRead.add(double.parse(data[3]));
        preProcessing.add(double.parse(data[4]));
        modelInference.add(double.parse(data[5]));
        faceDetection.add(double.parse(data[6]));
      }

      return {
        'frameRead': frameRead.average.floorToDouble(),
        'preProcessing': preProcessing.average.floorToDouble(),
        'modelInference': modelInference.average.floorToDouble(),
        'faceDetection': faceDetection.average.floorToDouble(),
      };
    } else {
      return null;
    }
  } else {
    return null;
  }
});
