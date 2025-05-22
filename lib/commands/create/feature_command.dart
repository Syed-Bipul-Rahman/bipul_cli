import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ansicolor/ansicolor.dart';
import 'package:bipul_cli/utils/template_renderer.dart';
import 'package:bipul_cli/commands/base_command.dart';
import 'package:bipul_cli/utils/validator.dart';

class FeatureCommand extends BaseCommand {
  @override
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

    _generateFeature(featureName, featurePath);
    _updateRoutes(projectPath, featureName);
    _updateDI(projectPath, featureName);
    _showSuccessMessage(featureName);
  }

  void _generateFeature(String featureName, String featurePath) {
    Directory(featurePath).createSync(recursive: true);

    // Create feature structure
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

    // Generate files from templates
    TemplateRenderer.renderFeature(featureName, featurePath);
  }

  void _updateRoutes(String projectPath, String featureName) {
    final routesFile = p.join(projectPath, 'lib', 'config', 'routes', 'route_names.dart.mustache');
    if (!File(routesFile).existsSync()) return;

    var content = File(routesFile).readAsStringSync();
    final routeConstant = "  static const String ${featureName} = '/${featureName}';";

    if (!content.contains(routeConstant)) {
      content = content.replaceFirst(
        '} \n// END',
        '  static const String ${featureName} = \'/${featureName}\';\n} \n// END',
        content.indexOf('} \n// END'),
      );

      File(routesFile).writeAsStringSync(content);
    }
  }

  void _updateDI(String projectPath, String featureName) {
    final injectorFile = p.join(projectPath, 'lib', 'config', 'di', 'injector.dart.mustache');
    if (!File(injectorFile).existsSync()) return;

    var content = File(injectorFile).readAsStringSync();
    final pascalName = formatName(featureName);

    // Add imports
    final importLine = "import 'package:your_project/features/${featureName}/presentation/viewmodels/${featureName}_viewmodel.dart';";
    if (!content.contains(importLine)) {
      content = content.replaceFirst(
        '// Features imports',
        '// Features imports\nimport \'package:your_project/features/${featureName}/presentation/viewmodels/${featureName}_viewmodel.dart\';',
        content.indexOf('// Features imports'),
      );

      // Add viewmodel registration
      content = content.replaceFirst(
        '// Features dependencies',
        '// Features dependencies\n  injector.registerLazySingleton(() => ${pascalName}ViewModel(injector()));',
        content.indexOf('// Features dependencies'),
      );

      File(injectorFile).writeAsStringSync(content);
    }
  }

  void _showSuccessMessage(String featureName) {
    final pen = AnsiPen()..green(bold: true)..bgBlack();
    print('\n✅ Successfully created feature "$featureName"');
    print('\n✨ The feature includes:');
    print('  ✓ Data Layer (Models, DataSources, Repositories)');
    print('  ✓ Domain Layer (Entities, UseCases)');
    print('  ✓ Presentation Layer (ViewModels, Pages, Views, Widgets)');
    print('  ✓ Automatic Route Configuration');
    print('  ✓ DI Integration');
  }
}