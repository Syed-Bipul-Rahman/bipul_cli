import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mustache_template/mustache_template.dart';

class TemplateRenderer {
  static final String templateBasePath = p.join('templates', 'feature');

  static void renderFeature(String featureName, String featurePath) {
    final pascalName = _toPascalCase(featureName);
    final snakeName = _toSnakeCase(featureName);

    // Render domain files
    _renderTemplate(
      templatePath: p.join(templateBasePath, 'domain', 'entity', 'entity.dart.mustache'),
      outputPath: p.join(featurePath, 'domain', 'entities', '${snakeName}_entity.dart'),
      context: {'FeatureName': pascalName},
    );

    _renderTemplate(
      templatePath: p.join(templateBasePath, 'domain', 'repository', 'repository.dart.mustache'),
      outputPath: p.join(featurePath, 'domain', 'repositories', '${snakeName}_repository.dart'),
      context: {'FeatureName': pascalName},
    );

    // Repeat for other files...
  }

  static void _renderTemplate({required String templatePath, required String outputPath, required Map<String, String> context}) {
    if (!File(templatePath).existsSync()) return;

    final templateContent = File(templatePath).readAsStringSync();
    final template = Template(templateContent);
    final renderedContent = template.renderString(context);

    File(outputPath).writeAsStringSync(renderedContent);
  }

  static String _toPascalCase(String text) {
    return text.split(RegExp(r'[._-]')).map((s) => s[0].toUpperCase() + s.substring(1)).join();
  }

  static String _toSnakeCase(String text) {
    return ReCase(text).snakeCase;
  }
}