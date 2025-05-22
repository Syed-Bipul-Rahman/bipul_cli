import 'dart:io';
import 'package:path/path.dart' as p;

class FileUtils {
  static void copyDirectory(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    for (var entity in source.listSync()) {
      var relativePath =
          p.relative(entity.path, from: source.path); // ← Fixed here
      var destPath = p.join(destination.path, relativePath);

      if (entity is File) {
        entity.copySync(destPath);
      } else if (entity is Directory) {
        copyDirectory(entity, Directory(destPath));
      }
    }
  }
}
