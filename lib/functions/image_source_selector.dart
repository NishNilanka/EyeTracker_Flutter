import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eye_tracker_app/enums/image_source.dart';

///image source selecter. camera/gallery
final selectedImageSource =
    StateProvider<ImageSourceSelector>((ref) => ImageSourceSelector.gallery);
