import 'dart:io';
import 'package:path/path.dart' as p;

class Validator {
  static bool isValidProjectName(String name) {
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_\-]+$');
    return regex.hasMatch(name);
  }

  static bool isFlutterProject(String path) {
    final pubspecPath = p.join(path, 'pubspec.yaml');
    return File(pubspecPath).existsSync();
  }

  static bool isValidFeatureName(String name) {
    final regex = RegExp(r'^[a-z][a-zA-Z0-9_\-]+$');
    return regex.hasMatch(name);
  }
}