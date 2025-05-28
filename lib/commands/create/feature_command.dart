import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:bipul_cli/utils/template_renderer.dart';
import 'package:bipul_cli/commands/base_command.dart';
import 'package:bipul_cli/utils/validator.dart';
import 'package:recase/recase.dart';

class FeatureCommand extends BaseCommand {
  void run(List<String> args) {
    if (!validateArgs(args)) return;

    final featureName = args[0];
    final projectPath = Directory.current.path;

    if (!Validator.isFlutterProject(projectPath)) {
      print('\n❌ Current directory is not a Flutter project!');
      print('Please navigate to your Flutter project directory first.');
      return;
    }

    final featurePath = p.join(projectPath, 'lib', 'features', featureName);

    if (Directory(featurePath).existsSync()) {
      print('\n❌ Feature "$featureName" already exists!');
      return;
    }

    _generateFeature(featureName, featurePath, projectPath);
    _updateRoutes(projectPath, featureName);
    _updateDI(projectPath, featureName);
    _showSuccessMessage(featureName);
  }

  void _generateFeature(
      String featureName, String featurePath, String projectPath) {
    Directory(featurePath).createSync(recursive: true);

    final directories = [
      p.join(featurePath, 'data', 'models'),
      p.join(featurePath, 'data', 'datasources'),
      p.join(featurePath, 'data', 'repositories'),
      p.join(featurePath, 'domain', 'entities'),
      p.join(featurePath, 'domain', 'repositories'),
      p.join(featurePath, 'domain', 'usecases'),
      p.join(featurePath, 'presentation', 'pages'),
      p.join(featurePath, 'presentation', 'widgets'),
      p.join(featurePath, 'presentation', 'viewmodels'),
      p.join(featurePath, 'presentation', 'views'),
    ];

    for (final dir in directories) {
      Directory(dir).createSync();
    }

    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    final projectName = pubspecFile.existsSync()
        ? (RegExp(r'^name:\s*(.+)$', multiLine: true)
                .firstMatch(pubspecFile.readAsStringSync())
                ?.group(1)
                ?.trim() ??
            'my_app')
        : 'my_app';

    TemplateRenderer.renderFeature(
      'feature',
      featurePath,
      {
        'project_name': projectName,
        'ProjectName': formatName(projectName),
        'feature_name': featureName,
        'FeatureName': formatName(featureName),
      },
    );
  }

  void _updateRoutes(String projectPath, String featureName) {
    final routesFile =
        p.join(projectPath, 'lib', 'config', 'routes', 'route_names.dart');
    if (!File(routesFile).existsSync()) return;

    var content = File(routesFile).readAsStringSync();
    final routeConstant =
        "  static const String $featureName = '/$featureName';";

    if (!content.contains(routeConstant)) {
      content = content.replaceFirst(
        '}\n// END',
        '$routeConstant\n}\n// END',
      );
      File(routesFile).writeAsStringSync(content);
    }
  }

  void _updateDI(String projectPath, String featureName) {
    final injectorFile =
        p.join(projectPath, 'lib', 'config', 'di', 'injector.dart');
    if (!File(injectorFile).existsSync()) return;

    var content = File(injectorFile).readAsStringSync();
    final pascalName = formatName(featureName);

    final importLine =
        "import 'package:${projectPath.split('/').last}/features/$featureName/presentation/viewmodels/${featureName}_viewmodel.dart';";
    if (!content.contains(importLine)) {
      content = content.replaceFirst(
        '// Features imports',
        '// Features imports\n$importLine',
      );

      content = content.replaceFirst(
        '// Features dependencies',
        '// Features dependencies\n  injector.registerLazySingleton(() => ${pascalName}ViewModel(injector()));',
      );

      File(injectorFile).writeAsStringSync(content);
    }
  }

  void _showSuccessMessage(String featureName) {
    print('\n✅ Successfully created feature "$featureName"');
    print('\n✨ The feature includes:');
    print('  ✓ Data Layer (Models, DataSources, Repositories)');
    print('  ✓ Domain Layer (Entities, UseCases)');
    print('  ✓ Presentation Layer (ViewModels, Pages, Views, Widgets)');
    print('  ✓ Automatic Route Configuration');
    print('  ✓ DI Integration');
  }

  @override
  String formatName(String name) {
    return ReCase(name).pascalCase;
  }
}
