import 'dart:io';

import 'package:eye_tracker_app/screens/result_page_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eye_tracker_app/enums/image_source.dart';
import 'package:eye_tracker_app/functions/image_source_selector.dart';
import 'package:eye_tracker_app/screens/result_page_camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../functions/pick_camera_imagestream.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ///read teh camera provider to make sure it is initialized.
    ref.read(cameraProvider);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          ///title of the main page
          title: const Text('Eye Tracker App'),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  ref.read(selectedImageSource.notifier).state =
                      ImageSourceSelector.camera;

                  ///go to the result page with the selected source
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ResultPage(),
                    ),
                  );
                },
                child: const Text('Camera'),
              ),
              const SizedBox(
                height: 20.0,
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(selectedImageSource.notifier).state =
                      ImageSourceSelector.gallery;

                  ///go to the result page with the selected source
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ResultPageVideo(),
                    ),
                  );
                },
                child: const Text('Gallery'),
              ),
              const SizedBox(
                height: 20.0,
              ),
              ElevatedButton(
                onPressed: () async {
                  ///Share the data from the previous save.
                  ///make sure that the files are shared brfore running another test. Otherwise the file will be overwritten.
                  final directory = await getApplicationDocumentsDirectory();
                  final path = '${directory.path}/save_file.txt';
                  if (File(path).existsSync()) {
                    await Share.shareXFiles([XFile(path)]);
                  } else {
                    ///toast if the file does not found.
                    Fluttertoast.showToast(msg: 'No file to share');
                  }
                },
                child: const Text('Share Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
