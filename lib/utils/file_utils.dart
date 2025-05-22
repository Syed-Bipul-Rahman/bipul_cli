import 'dart:io';
import 'package:path/path.dart' as p;

class FileUtils {
  static void copyDirectory(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    for (var entity in source.listSync()) {
      var relativePath = p.relative(entity.path, from: source.path);
      var destPath = p.join(destination.path, relativePath);

      if (entity is File) {
        var destFile = File(destPath);
        destFile.parent.createSync(recursive: true);
        entity.copySync(destFile.path);
      } else if (entity is Directory) {
        var destDir = Directory(destPath);
        destDir.createSync(recursive: true);
        copyDirectory(entity, destDir);
      }
    }
  }
}