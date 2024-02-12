import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eye_tracker_app/functions/pick_camera_imagestream.dart';
import 'package:eye_tracker_app/riverpod/result_controller.dart';

import '../functions/screen_location.dart';

class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ///get the screens size (this is used to translate the results into the appropriate screen sizes)
    final screenSize = MediaQuery.of(context).size;

    ///riverpod
    final imageStream = ref.watch(imageStreamProvider);
    final result = ref.watch(resultProvider);
    final controller = ref.watch(cameraProvider);
    final avgTime = ref.watch(averageTimeProvider);
    //final resource = ref.watch(resourceMonitor);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Result",
          ),
        ),
        body: imageStream.when(data: (data) {
          ///if results are availabele, get the location of the pointer
          Alignment alignment = const Alignment(0.0, 0.0);
          if (result['label'] != null) {
            alignment = screenLocation(screenSize, result['label']);
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Center(
                        child: result['image'] != null
                            ? controller.when(
                                data: (ctrl) {
                                  return CameraPreview(ctrl);
                                },
                                error: (error, stack) {
                                  return Text(error.toString());
                                },
                                loading: () {
                                  return const CircularProgressIndicator();
                                },
                              )
                            : const SizedBox(),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    result['label'] != null
                        ? Table(
                            children: [
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text("Average Total Time:")),
                                  TableCell(
                                    child: avgTime.isNotEmpty
                                        ? Text(
                                            '${(avgTime.reduce((sum, number) => sum + number) ~/ avgTime.length).toString()}ms')
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(child: Text("Frame Read:")),
                                  TableCell(
                                      child: Text(
                                          '${result['frameReadTime'].toString()}ms'))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text("Face Detection:")),
                                  TableCell(
                                      child: Text(
                                          '${result['faceDetectionTime'].toString()}ms'))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text("Pre-Processing:")),
                                  TableCell(
                                      child: Text(
                                          '${result['preProcessingTime'].toString()}ms'))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text("Model Inference:")),
                                  TableCell(
                                      child: Text(
                                          '${result['modelInferenceTime'].toString()}ms'))
                                ],
                              ),
                              // TableRow(
                              //   children: [
                              //     const TableCell(child: Text("CPU Usage:")),
                              //     TableCell(
                              //       child: Text(
                              //           '${(resource['cpu']! * 100).toInt()}%'),
                              //     ),
                              //   ],
                              // ),
                              // TableRow(
                              //   children: [
                              //     const TableCell(child: Text("Mem Usage:")),
                              //     TableCell(
                              //       child: Text(
                              //           '${(resource['mem']! * 100).toInt()}%'),
                              //     ),
                              //   ],
                              // ),
                            ],
                          )
                        : const SizedBox(),
                    const SizedBox(
                      height: 10.0,
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                  ],
                ),
                Positioned(
                  left: alignment.x,
                  top: alignment.y,
                  child: Container(
                    color: Colors.red,
                    width: 10.0,
                    height: 10.0,
                  ),
                ),
              ],
            ),
          );
        }, error: (error, stack) {
          return Center(
            child: Text(
              stack.toString(),
            ),
          );
        }, loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }),
      ),
    );
  }
}
