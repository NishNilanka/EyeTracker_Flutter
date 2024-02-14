///Same as the result_page_camera.dart. This page is serving video
import 'package:eye_tracker_app/functions/pick_video_imagestream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../riverpod/result_controller.dart';

class ResultPageVideo extends ConsumerWidget {
  const ResultPageVideo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final screenSize = MediaQuery.of(context).size;
    //ref.read(videoController);
    final result = ref.watch(resultProvider);
    final avgTime = ref.watch(averageTimeProvider);
    final videoStream = ref.watch(videoImageProvider);
    final end = ref.watch(endResult);
    final summery = ref.watch(resultSummery);
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Result'),
            ),
            body: end
                ? summery.when(data: (data) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Result Summery'),
                          const SizedBox(
                            height: 20.0,
                          ),
                          Table(children: [
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Center(
                                        child: Text("Average Total Time:"))),
                                TableCell(
                                  child: avgTime.isNotEmpty
                                      ? Center(
                                          child: Text(
                                              '${(avgTime.reduce((sum, number) => sum + number) ~/ avgTime.length).toString()}ms'),
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Center(child: Text("Frame Read:"))),
                                TableCell(
                                    child: Center(
                                  child: Text(
                                      '${data!['frameRead'].toString()}ms'),
                                ))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child:
                                        Center(child: Text("Face Detection:"))),
                                TableCell(
                                    child: Center(
                                  child: Text(
                                      '${data['faceDetection'].toString()}ms'),
                                ))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child:
                                        Center(child: Text("Pre-Processing:"))),
                                TableCell(
                                    child: Center(
                                  child: Text(
                                      '${data['preProcessing'].toString()}ms'),
                                ))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Center(
                                        child: Text("Model Inference:"))),
                                TableCell(
                                    child: Center(
                                  child: Text(
                                      '${data['modelInference'].toString()}ms'),
                                ))
                              ],
                            ),
                          ]),
                        ],
                      ),
                    );
                  }, error: (error, stack) {
                    print(stack);
                    return Text(error.toString());
                  }, loading: () {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  })
                : videoStream.when(data: (data) {
                    // Alignment alignment = const Alignment(0.0, 0.0);
                    // if (result['label'] != null) {
                    //   alignment = screenLocation(screenSize, result['label']);
                    // }
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
                                      ? Image.memory(result['image'])
                                      : const SizedBox(),
                                  //     // child: video.when(
                                  //     //   data: (ctrl) {
                                  //     //     return Video(
                                  //     //       controller: ctrl!,
                                  //     //     );
                                  //     //   },
                                  //     //   error: (error, stack) {
                                  //     //     return Text(error.toString());
                                  //     //   },
                                  //     //   loading: () {
                                  //     //     return const CircularProgressIndicator();
                                  //     //   },
                                  //     // ),
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
                                                child: Text(
                                                    "Average Total Time:")),
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
                                            const TableCell(
                                                child: Text("Frame Read:")),
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
                                                child:
                                                    Text("Model Inference:")),
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
                          // Positioned(
                          //   left: alignment.x,
                          //   top: alignment.y,
                          //   child: Container(
                          //     color: Colors.red,
                          //     width: 10.0,
                          //     height: 10.0,
                          //   ),
                          // ),
                        ],
                      ),
                    );
                  }, error: (error, stack) {
                    print(stack);
                    return Text(error.toString());
                  }, loading: () {
                    return const Center(child: CircularProgressIndicator());
                  })));
  }
}
