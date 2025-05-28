import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ansicolor/ansicolor.dart';
import 'package:bipul_cli/utils/file_utils.dart';
import 'package:bipul_cli/utils/template_renderer.dart';
import 'package:bipul_cli/utils/validator.dart';
import 'package:bipul_cli/commands/base_command.dart';
import 'package:recase/recase.dart';

class CreateCommand extends BaseCommand {
  final String templatePath = 'lib/templates/project';

  void run(List<String> args) {
    if (args.isEmpty || !args[0].contains(':')) {
      _showUsage();
      return;
    }

    final parts = args[0].split(':');
    if (parts.length != 2) {
      _showUsage();
      return;
    }

    final type = parts[0]; // "project" or "feature"
    final name = parts[1]; // "test_app" or "login"

    // Route to appropriate handler
    switch (type) {
      case 'project':
        _createProject(name, args);
        break;
      case 'feature':
        _createFeature(name, args);
        break;
      default:
        print('\n❌ Unsupported type: "$type"');
        print('Supported types: project, feature');
        _showUsage();
        return;
    }
  }

  void _createProject(String rawProjectName, List<String> args) {
    // Format and validate project name
    String projectName = formatProjectName(rawProjectName);

    if (!Validator.isValidProjectName(projectName)) {
      print('\n❌ Invalid project name: "$rawProjectName"');
      print(
          'After formatting, name became "$projectName", which is still invalid.');
      print('Project name must:');
      print('  ✓ Start with lowercase letter');
      print('  ✓ Use only lowercase letters, numbers, and underscores');
      print('  ✓ Not contain special characters or spaces');
      print('Example: bipul create project:my_cool_app');
      return;
    }

    // Safely handle extra args
    final List<String> extraArgs = args.length > 1 ? args.sublist(1) : [];
    final Map<String, dynamic> options = _parseOptions(extraArgs);

    final projectPath = p.join(Directory.current.path, projectName);

    if (Directory(projectPath).existsSync()) {
      print('\n❌ A directory named "$projectName" already exists!');
      return;
    }

    _askConfigurationOptions(options);
    final companyDomain = _askCompanyDomain();
    options['company_domain'] = companyDomain;

    _createFlutterProject(projectName, projectPath, options);
    _applyBipulStructure(projectPath, projectName, options);
    _showSuccessMessage(projectName, projectPath, options);
  }

  void _createFeature(String featureName, List<String> args) {
    // Validate feature name
    if (!Validator.isValidFeatureName(featureName)) {
      print('\n❌ Invalid feature name: "$featureName"');
      print('Feature name must:');
      print('  ✓ Start with lowercase letter');
      print('  ✓ Use only lowercase letters, numbers, and underscores');
      print('  ✓ Not contain special characters or spaces');
      print('Example: bipul create feature:user_profile');
      return;
    }

    // Find Flutter project directory
    final projectDir = _findFlutterProjectDirectory();
    if (projectDir == null) {
      print('\n❌ No Flutter project found!');
      print('Please run this command from:');
      print('  1. Inside a Flutter project directory, or');
      print('  2. From the bipul_cli directory with Flutter projects nearby');
      return;
    }

    print('📁 Found Flutter project at: ${projectDir.path}');

    // Check if feature already exists
    final featuresPath = p.join(projectDir.path, 'lib', 'features');
    final featurePath = p.join(featuresPath, featureName);

    if (Directory(featurePath).existsSync()) {
      print('\n❌ Feature "$featureName" already exists!');
      return;
    }

    // Create the feature
    print('\n🧩 Creating feature "$featureName"...');

    try {
      // Get project name from pubspec.yaml
      final projectName = _getProjectNameFromPubspec(projectDir.path);

      TemplateRenderer.renderFeature(
        featureName, // Added as the first argument (template name)
        featurePath, // Second argument (target path)
        {
          'project_name': projectName,
          'ProjectName': formatName(projectName),
          'feature_name': featureName,
          'FeatureName': formatName(featureName),
        },
      );

      _showFeatureSuccessMessage(featureName, projectDir.path);
    } catch (e) {
      print('\n❌ Failed to create feature: $e');
    }
  }

  Directory? _findFlutterProjectDirectory() {
    // First check if current directory is a Flutter project
    if (_isInFlutterProject(Directory.current.path)) {
      return Directory.current;
    }

    // If not, look for Flutter projects in current directory
    final currentDir = Directory.current;
    for (var entity in currentDir.listSync()) {
      if (entity is Directory) {
        if (_isInFlutterProject(entity.path)) {
          return entity;
        }
      }
    }

    return null;
  }

  bool _isInFlutterProject([String? path]) {
    final targetPath = path ?? Directory.current.path;
    final pubspecFile = File(p.join(targetPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return false;

    final content = pubspecFile.readAsStringSync();
    return content.contains('flutter:') && content.contains('sdk: flutter');
  }

  String _getProjectNameFromPubspec([String? projectPath]) {
    final targetPath = projectPath ?? Directory.current.path;
    final pubspecFile = File(p.join(targetPath, 'pubspec.yaml'));
    final content = pubspecFile.readAsStringSync();
    final nameRegex = RegExp(r'^name:\s*(.+)$', multiLine: true);
    final match = nameRegex.firstMatch(content);
    return match?.group(1)?.trim() ?? 'unknown_project';
  }

  String formatName(String name) {
    return ReCase(name).pascalCase;
  }

  Map<String, dynamic> _parseOptions(List<String> args) {
    final options = <String, dynamic>{
      'android_language': null,
      'ios_language': null,
      'include_linter': null,
    };

    // Parse options from command line if provided
    for (var arg in args) {
      if (arg.startsWith('--android=')) {
        final value = arg.substring('--android='.length).toLowerCase();
        if (value == 'java' || value == 'kotlin') {
          options['android_language'] = value;
        }
      } else if (arg.startsWith('--ios=')) {
        final value = arg.substring('--ios='.length).toLowerCase();
        if (value == 'objc' || value == 'swift') {
          options['ios_language'] = value;
        }
      } else if (arg == '--linter' || arg == '--with-linter') {
        options['include_linter'] = true;
      } else if (arg == '--no-linter') {
        options['include_linter'] = false;
      }
    }

    return options;
  }

  Future<void> _askConfigurationOptions(Map<String, dynamic> options) async {
    final pen = AnsiPen()..blue(bold: true);

    // Ask for Android language
    if (options['android_language'] == null) {
      print('\n${pen('Android Language')}');
      print('Select your preferred language for Android:');
      print('1. Kotlin (recommended)');
      print('2. Java');

      final choice = stdin.readLineSync()?.trim();
      options['android_language'] = choice == '1' ? 'kotlin' : 'java';
    }

    // Ask for iOS language
    if (options['ios_language'] == null) {
      print('\n${pen('iOS Language')}');
      print('Select your preferred language for iOS:');
      print('1. Swift (recommended)');
      print('2. Objective-C');

      final choice = stdin.readLineSync()?.trim();
      options['ios_language'] = choice == '1' ? 'swift' : 'objc';
    }

    // Ask about linter
    if (options['include_linter'] == null) {
      print('\n${pen('Linter')}');
      print('Would you like to include Flutter linter?');
      print('1. Yes (recommended)');
      print('2. No');

      final choice = stdin.readLineSync()?.trim();
      options['include_linter'] = choice == '1';
    }
  }

  String _askCompanyDomain() {
    print('\n🏢 What is your company\'s domain? Example: com.yourcompany');
    final domain = stdin.readLineSync()?.trim() ?? 'yourcompany';
    return domain;
  }

  void _createFlutterProject(
      String projectName, String projectPath, Map<String, dynamic> options) {
    final androidLanguage =
        options['android_language'] == 'java' ? 'java' : 'kotlin';
    final iosLanguage = options['ios_language'] == 'objc' ? 'objc' : 'swift';
    final orgName =
        "com.${options['company_domain']}.${projectName.toLowerCase()}";

    print('\n🏃‍♂️ Running flutter create...');

    final flutterCreateProcess = Process.runSync(
      'flutter',
      [
        'create',
        '--no-pub',
        '-a',
        androidLanguage,
        '--org',
        orgName,
        '--platforms',
        'android,ios',
        projectPath
      ],
      runInShell: true,
    );

    if (flutterCreateProcess.exitCode != 0) {
      throw Exception('Flutter create failed: ${flutterCreateProcess.stderr}');
    }

    print(flutterCreateProcess.stdout);

    // Run pub get
    print('\n📦 Running flutter pub get...');
    final pubGetProcess = Process.runSync(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectPath,
    );

    if (pubGetProcess.exitCode != 0) {
      throw Exception('Pub get failed: ${pubGetProcess.stderr}');
    }

    print(pubGetProcess.stdout);

    // Add linter if needed
    if (options['include_linter'] == true) {
      _addLinter(projectPath);
    }
  }

  void _replacePlaceholdersInAllFiles(
      String folderPath, Map<String, dynamic> context) {
    final dir = Directory(folderPath);

    if (!dir.existsSync()) return;

    for (var entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File &&
          (entity.path.endsWith('.dart') || entity.path.endsWith('.yaml'))) {
        var content = entity.readAsStringSync();

        context.forEach((key, value) {
          content = content.replaceAll('{{$key}}', '$value');
          content = content.replaceAll(
              '{{${key}_snake}}', ReCase('$value').snakeCase);
          content = content.replaceAll(
              '{{${key}_pascal}}', ReCase('$value').pascalCase);
        });

        entity.writeAsStringSync(content);
      }
    }
  }

  void _applyBipulStructure(
      String projectPath, String projectName, Map<String, dynamic> options) {
    print('\n🏗️ Applying Bipul Architecture...');

    final projectLibPath = p.join(projectPath, 'lib');

    // Delete default lib content
    final libDir = Directory(projectLibPath);
    if (libDir.existsSync()) {
      libDir.deleteSync(recursive: true);
    }
    libDir.createSync();

    // Copy full architecture structure from template
    final templateLibDir = Directory('lib/templates/project/lib');

    if (templateLibDir.existsSync()) {
      print('📦 Rendering template files...');
      TemplateRenderer.renderProjectTemplates(projectLibPath, {
        'project_name': projectName,
        'ProjectName': formatName(projectName),
        'android_language': options['android_language'],
        'ios_language': options['ios_language'],
        'include_linter': options['include_linter'] == true ? true : false,
      });
    } else {
      throw Exception(
          'Template not found at $templateLibDir\nPlease make sure the template folder exists with all required files');
    }

    // Create home feature last
    final featurePath = p.join(projectPath, 'lib', 'features', 'home');

    print('\n🧩 Generating feature "home"...');
    TemplateRenderer.renderFeature(
      'home', // Added as the first argument (template name)
      featurePath, // Second argument (target path)
      {
        'project_name': projectName,
        'ProjectName': formatName(projectName),
        'feature_name': 'home',
        'FeatureName': 'Home',
      },
    );
  }

  void _addLinter(String projectPath) {
    print('\n🧼 Adding Flutter Linter...');

    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    var content = pubspecFile.readAsStringSync();

    if (!content.contains('flutter_lints')) {
      content = content.replaceFirst(
          'dev_dependencies:',
          'dev_dependencies:\n  flutter_lints: ^2.0.0',
          content.indexOf('dev_dependencies:'));
    }

    pubspecFile.writeAsStringSync(content);

    // Add analysis_options.yaml
    final analysisOptions = '''
include: package:flutter_lints/flutter.yaml

analyzer:
  enable-experiment:
    - const-candidates-2022
    - pattern-type-nulls
''';

    File(p.join(projectPath, 'analysis_options.yaml'))
        .writeAsStringSync(analysisOptions);

    // Run pub add for flutter_lints
    final pubAddProcess = Process.runSync(
      'flutter',
      ['pub', 'add', 'flutter_lints'],
      workingDirectory: projectPath,
    );

    print(pubAddProcess.stdout);
  }

  void _showSuccessMessage(
      String projectName, String projectPath, Map<String, dynamic> options) {
    final pen = AnsiPen()..green(bold: true);
    print('\n✅ Successfully created Flutter project "$projectName"');
    print('\n👉 Next steps:');
    print('  cd $projectName');
    print('  flutter pub get');
    print('\n✨ Your project is now ready with:');
    print('  ✓ Clean Architecture Structure');
    print('  ✓ DRY & SOLID Principles');
    print('  ✓ Scalable Feature Organization');
    print('  ✓ Home Feature Pre-Installed');
    print('  ✓ Android language: ${options['android_language'].toUpperCase()}');
    print('  ✓ iOS language: ${options['ios_language'].toUpperCase()}');
    print(
        '  ✓ Linter: ${options['include_linter'] ? 'Included' : 'Not included'}');
    print('  ✓ Created using official flutter create');
    print('  ✓ Fully compatible with Flutter ecosystem');
  }

  void _showFeatureSuccessMessage(String featureName, [String? projectPath]) {
    final pen = AnsiPen()..green(bold: true);
    print('\n✅ Successfully created feature "$featureName"');
    if (projectPath != null) {
      print('📍 Location: $projectPath/lib/features/$featureName');
    }
    print('\n📁 Created files:');
    print('  lib/features/$featureName/');
    print('    ├── data/');
    print('    │   ├── datasources/');
    print('    │   ├── models/');
    print('    │   └── repositories/');
    print('    ├── domain/');
    print('    │   ├── entities/');
    print('    │   ├── repositories/');
    print('    │   └── usecases/');
    print('    └── presentation/');
    print('        ├── bloc/');
    print('        ├── pages/');
    print('        └── widgets/');
    print('\n👉 Next steps:');
    print('  1. Implement your feature logic in the generated files');
    print('  2. Add your feature route to the app router');
    print('  3. Import and use your feature widgets/pages');
  }

  void _showUsage() {
    final pen = AnsiPen()..red(bold: true);
    print('\n${pen('ERROR')}: Invalid create command format');
    print('''
Usage:
  bipul create project:project_name     Create a new Flutter project
  bipul create feature:feature_name     Create a new feature in existing project

Examples:
  bipul create project:my_cool_app
  bipul create feature:login
  bipul create feature:user_profile
''');
  }

  String formatProjectName(String rawName) {
    // Replace invalid characters and ensure lowercase
    String formatted = rawName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    // Ensure it starts with a letter
    if (formatted.isNotEmpty && !RegExp(r'^[a-z]').hasMatch(formatted)) {
      formatted = 'app_$formatted';
    }

    return formatted.isEmpty ? 'my_app' : formatted;
  }
}
