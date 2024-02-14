// import 'dart:ui';

// import 'package:collection/collection.dart' as p;

// import 'recognitions.dart';

// //var labels;

// List<Recognition> nms(List<Recognition> list, var labels,
//     double ioU) // Turned from Java's ArrayList to Dart's List.
// {
//   List<Recognition> nmsList = List<Recognition>.empty(growable: true);

//   for (int k = 0; k < labels.length; k++) {
//     // 1.find max confidence per class
//     p.PriorityQueue<Recognition> pq = p.HeapPriorityQueue<Recognition>();
//     for (int i = 0; i < list.length; ++i) {
//       if (list[i].label == labels[k]) {
//         // Changed from comparing #th class to class to string to string
//         pq.add(list[i]);
//       }
//     }

//     // 2.do non maximum suppression
//     while (pq.length > 0) {
//       // insert detection with max confidence
//       List<Recognition> detections = pq.toList(); //In Java: pq.toArray(a)
//       Recognition max = detections[0];
//       nmsList.add(max);
//       pq.clear();
//       for (int j = 1; j < detections.length; j++) {
//         Recognition detection = detections[j];
//         Rect b = detection.location!;
//         Rect x = max.location!;
//         if (boxIou(x, b) < ioU) {
//           pq.add(detection);
//         }
//       }
//     }
//   }

//   return nmsList;
// }

// double boxIou(Rect a, Rect b) {
//   return boxIntersection(a, b) / boxUnion(a, b);
// }

// double boxIntersection(Rect a, Rect b) {
//   double w = overlap((a.left + a.right) / 2, a.right - a.left,
//       (b.left + b.right) / 2, b.right - b.left);
//   double h = overlap((a.top + a.bottom) / 2, a.bottom - a.top,
//       (b.top + b.bottom) / 2, b.bottom - b.top);
//   if ((w < 0) || (h < 0)) {
//     return 0;
//   }
//   double area = (w * h);
//   return area;
// }

// double boxUnion(Rect a, Rect b) {
//   double i = boxIntersection(a, b);
//   double u = ((((a.right - a.left) * (a.bottom - a.top)) +
//           ((b.right - b.left) * (b.bottom - b.top))) -
//       i);
//   return u;
// }

// double overlap(double x1, double w1, double x2, double w2) {
//   double l1 = (x1 - (w1 / 2));
//   double l2 = (x2 - (w2 / 2));
//   double left = ((l1 > l2) ? l1 : l2);
//   double r1 = (x1 + (w1 / 2));
//   double r2 = (x2 + (w2 / 2));
//   double right = ((r1 < r2) ? r1 : r2);
//   return right - left;
// }

import 'dart:math';
import 'dart:ui';

import 'package:eye_tracker_app/functions/recognitions.dart';

// class Recognition {
//   Rect boundingBox;
//   double confidence;

//   Recognition(this.boundingBox, this.confidence);
// }

// class Rect {
//   double left, top, right, bottom;

//   Rect(this.left, this.top, this.right, this.bottom);
// }

List<Recognition> nms(List<Recognition> recognitions, double iouThreshold) {
  List<Recognition> result = [];

  // Sort recognitions by confidence in descending order
  recognitions.sort((a, b) => b.score.compareTo(a.score));

  for (int i = 0; i < recognitions.length; i++) {
    Recognition current = recognitions[i];
    bool keep = true;

    for (int j = 0; j < result.length; j++) {
      Recognition previous = result[j];

      double intersection =
          calculateIntersection(current.location!, previous.location!);
      double union =
          calculateUnion(current.location!, previous.location!, intersection);
      double iou = intersection / union;

      if (iou > iouThreshold) {
        keep = false;
        break;
      }
    }

    if (keep) {
      result.add(current);
    }
  }

  return result;
}

double calculateIntersection(Rect a, Rect b) {
  double left = max(a.left, b.left);
  double top = max(a.top, b.top);
  double right = min(a.right, b.right);
  double bottom = min(a.bottom, b.bottom);

  if (left >= right || top >= bottom) {
    return 0.0;
  }

  return (right - left) * (bottom - top);
}

double calculateUnion(Rect a, Rect b, double intersection) {
  double areaA = (a.right - a.left) * (a.bottom - a.top);
  double areaB = (b.right - b.left) * (b.bottom - b.top);

  return areaA + areaB - intersection;
}
