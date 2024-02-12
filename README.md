# eye_tracker_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# How to modify with a new tansorflow model
- you need to findout the input dimensions of your model.
- you need to findout the output dimensions of your model.
- then change the model.tflite in the assets folder. be sure to rename your new model as "model.tflite"
- change the labels.txt on the same directory with your labels. rename as "labels.txt"
- change the image input size in the classifire.dart. look for comments.
- change the output as appropriate in the classifire.dart.
