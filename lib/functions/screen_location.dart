import 'package:flutter/widgets.dart';

///translate the pointer location results to the appropriate screen size.
///this may needed to be changed.
Alignment screenLocation(Size screenSize, String location) {
  final parts = location.split(",");

  ///the result that is getting from the model is devided by 3 and 5 for with and heigth.
  ///this may be not the actual translation method.
  ///this is a guesswork.
  final num1 = double.parse(parts[0]) / 3.0; //x
  final num2 = double.parse(parts[1]) / 5.0; //y
  return Alignment(num1 * screenSize.width, num2 * screenSize.height);
}
