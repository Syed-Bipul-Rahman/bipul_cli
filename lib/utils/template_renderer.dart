import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mustache_template/mustache_template.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:process/process.dart';

class TemplateRenderer {
  /// Renders all .mustache files in a folder using context
  static void renderAllTemplates(String sourcePath, String targetPath, Map<String, dynamic> context) {
    final templateDir = Directory(sourcePath);
    final outputDir = Directory(targetPath)..createSync(recursive: true);

    if (!templateDir.existsSync()) {
      throw Exception("Template folder not found at $sourcePath");
    }

    print('🧩 Rendering templates from $sourcePath → $targetPath');

    for (var entity in templateDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.mustache')) {
        final relativePath = p.relative(entity.path, from: sourcePath);
        final targetFile = File(p.join(targetPath, relativePath.replaceAll('.mustache', '')))
          ..parent.createSync(recursive: true);

        try {
          final template = Template(entity.readAsStringSync());
          final rendered = template.renderString(context);

          targetFile.writeAsStringSync(rendered);
          print('📄 Created: $relativePath → ${p.basename(targetFile.path)}');
        } catch (e) {
          print('❌ Failed to render $relativePath: $e');
        }
      }
    }
  }
}

class TemplateDownloader {
  static Future<void> ensureTemplatesExist() async {
    final templatesDir = Directory('lib/templates');

    if (templatesDir.existsSync()) {
      print('🗑️ Removing old templates...');
      templatesDir.deleteSync(recursive: true);
    }

    print('📥 Downloading latest templates...');
    final result = await Process.run(
      'git',
      [
        'clone',
        'https://github.com/Syed-Bipul-Rahman/bipul_templates.git',
        'lib/templates'
      ],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to download templates:\n${result.stderr}');
    }

    print('✅ Templates downloaded successfully!');
  }
}