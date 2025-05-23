import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mustache_template/mustache_template.dart';
import 'package:recase/recase.dart';

class TemplateRenderer {
  /// Renders the full project architecture from templates
  static void renderProjectTemplates(String projectPath, Map<String, dynamic> context) {
    final templateDir = Directory('lib/templates/project/lib');

    if (!templateDir.existsSync()) {
      throw Exception("Project templates not found at ${templateDir.path}");
    }

    print('📦 Rendering project templates...');

    for (var entity in templateDir.listSync(recursive: true)) {
      // Skip home feature while rendering project
      if (entity.path.contains(p.join('features', 'home'))) continue;

      if (entity is File && entity.path.endsWith('.mustache')) {
        // Calculate relative path and remove .mustache extension
        final relativePath = p.relative(entity.path, from: templateDir.path);
        final targetPath =
            p.join(projectPath, relativePath.replaceAll('.mustache', ''));

        // Create parent directory if needed
        final targetFile = File(targetPath);
        targetFile.parent.createSync(recursive: true);

        // Render and write file
        try {
          final template = Template(entity.readAsStringSync());
          final rendered = template.renderString(context);
          targetFile.writeAsStringSync(rendered);

          print('📄 Created: $relativePath → ${p.basename(targetPath)}');
        } catch (e) {
          print('❌ Failed to render $relativePath: $e');
        }
      }
    }
  }

  /// Renders a new feature inside an existing project
  static void renderFeature(String featureName, String featurePath) {
    final pascalName = _toPascalCase(featureName);
    final snakeName = _toSnakeCase(featureName);

    final templateDir = Directory(p.join('lib', 'templates', 'project', 'lib', 'features', featureName));
    
    if (!templateDir.existsSync()) {
      throw Exception("Feature templates not found at $templateDir");
    }

    print('🧩 Generating feature "$featureName"...');

    for (var entity in templateDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.mustache')) {
        final relativePath = p.relative(entity.path, from: templateDir.path);
        final targetPath = p.join(featurePath, relativePath.replaceAll('.mustache', ''));

        final targetFile = File(targetPath)..parent.createSync(recursive: true);

        try {
          final template = Template(entity.readAsStringSync());
          final rendered = template.renderString({
            'FeatureName': pascalName,
            'feature_name': snakeName,
          });

          targetFile.writeAsStringSync(rendered);
        } catch (e) {
          print('❌ Failed to render $relativePath: $e');
        }
      }
    }

    print('✅ Feature "$featureName" generated successfully');
  }

  /// Internal method to render individual templates
  @Deprecated('Use renderFeature instead')
  static void _renderTemplate({
    required String templatePath,
    required String outputPath,
    required Map<String, String> context,
  }) {
    if (!File(templatePath).existsSync()) {
      throw Exception("Template file not found: $templatePath");
    }

    final templateContent = File(templatePath).readAsStringSync();
    final template = Template(templateContent);
    final renderedContent = template.renderString(context);

    File(outputPath).writeAsStringSync(renderedContent);
  }

  // Helper methods

  static String _toPascalCase(String text) {
    return ReCase(text).pascalCase;
  }

  static String _toSnakeCase(String text) {
    return ReCase(text).snakeCase;
  }
}