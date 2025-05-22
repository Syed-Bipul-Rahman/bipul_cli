import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mustache_template/mustache_template.dart';
import 'package:recase/recase.dart';

class TemplateRenderer {
  /// Renders the full project architecture from templates
  static void renderProjectTemplates(
      String projectPath, Map<String, dynamic> context) {
    final templateDir = Directory('lib/templates/project');

    if (!templateDir.existsSync()) {
      throw Exception("Project templates not found at ${templateDir.path}");
    }

    print('📦 Rendering project templates...');

    for (var entity in templateDir.listSync(recursive: true)) {
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

    print('\n🧩 Generating feature "$featureName"...');

    // Make sure feature folder exists
    final featureDir = Directory(featurePath)..createSync(recursive: true);

    // Render domain files
    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'domain', 'entity',
          'entity.dart.mustache'),
      outputPath:
          p.join(featurePath, 'domain', 'entities', '${snakeName}_entity.dart'),
      context: {'FeatureName': pascalName},
    );

    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'domain',
          'repository', 'repository.dart.mustache'),
      outputPath: p.join(featurePath, 'domain', 'repositories',
          '${snakeName}_repository.dart'),
      context: {'FeatureName': pascalName},
    );

    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'domain', 'usecase',
          'usecase.dart.mustache'),
      outputPath: p.join(
          featurePath, 'domain', 'usecases', '${snakeName}_usecase.dart'),
      context: {'FeatureName': pascalName},
    );

    // Render presentation files
    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'presentation',
          'viewmodels', 'viewmodel.dart.mustache'),
      outputPath: p.join(featurePath, 'presentation', 'viewmodels',
          '${snakeName}_viewmodel.dart'),
      context: {'FeatureName': pascalName},
    );

    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'presentation',
          'pages', 'page.dart.mustache'),
      outputPath: p.join(
          featurePath, 'presentation', 'pages', '${snakeName}_page.dart'),
      context: {'FeatureName': pascalName},
    );

    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'presentation',
          'views', 'view.dart.mustache'),
      outputPath: p.join(
          featurePath, 'presentation', 'views', '${snakeName}_view.dart'),
      context: {'FeatureName': pascalName},
    );

    _renderTemplate(
      templatePath: p.join('lib', 'templates', 'feature', 'presentation',
          'widgets', 'widget.dart.mustache'),
      outputPath: p.join(
          featurePath, 'presentation', 'widgets', '${snakeName}_widget.dart'),
      context: {'FeatureName': pascalName},
    );
  }

  /// Internal method to render individual templates
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
