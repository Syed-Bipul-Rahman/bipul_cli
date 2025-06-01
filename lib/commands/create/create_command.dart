import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ansicolor/ansicolor.dart';
import 'package:bipul_cli/utils/template_renderer.dart';
import 'package:bipul_cli/utils/validator.dart';
import 'package:bipul_cli/commands/base_command.dart';
import 'package:recase/recase.dart';

class CreateCommand extends BaseCommand {
  final String templatePath = 'lib/templates/project';

  Future<void> run(List<String> args) async {
    print('📥 Preparing Bipul Templates...');
    await TemplateDownloader.ensureTemplatesExist();

    if (args.isEmpty || !args[0].contains(':')) {
      _showUsage();
      return;
    }

    final parts = args[0].split(':');
    if (parts.length != 2) {
      _showUsage();
      return;
    }

    final type = parts[0];
    final name = parts[1];

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

  void _createProject(String projectName, List<String> args) {
    projectName = formatProjectName(projectName);

    if (!Validator.isValidProjectName(projectName)) {
      print('\n❌ Invalid project name: "$projectName"');
      print('Project name must:');
      print('  ✓ Start with lowercase letter');
      print('  ✓ Use only lowercase letters, numbers, and underscores');
      print('  ✓ Not contain special characters or spaces');
      print('Example: bipul create project:my_cool_app');
      return;
    }

    final extraArgs = args.length > 1 ? args.sublist(1) : <String>[];
    final options = _parseOptions(extraArgs);

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
    if (!Validator.isValidFeatureName(featureName)) {
      print('\n❌ Invalid feature name: "$featureName"');
      print('Feature name must:');
      print('  ✓ Start with lowercase letter');
      print('  ✓ Use only lowercase letters, numbers, and underscores');
      print('  ✓ Not contain special characters or spaces');
      print('Example: bipul create feature:user_profile');
      return;
    }

    final projectDir = _findFlutterProjectDirectory();
    if (projectDir == null) {
      print('\n❌ No Flutter project found!');
      print('Please run this command from:');
      print('  1. Inside a Flutter project directory, or');
      print('  2. From the bipul_cli directory with Flutter projects nearby');
      return;
    }

    print('📁 Found Flutter project at: ${projectDir.path}');

    final featuresPath = p.join(projectDir.path, 'lib', 'features');
    final featurePath = p.join(featuresPath, featureName);

    if (Directory(featurePath).existsSync()) {
      print('\n❌ Feature "$featureName" already exists!');
      return;
    }

    print('\n🧩 Creating feature "$featureName"...');

    try {
      final projectName = _getProjectNameFromPubspec(projectDir.path);

      // Fixed: Use renderAllTemplates instead of renderFeature
      final featureTemplateDir = 'lib/templates/project/lib/features/home'; // Use home as template

      TemplateRenderer.renderAllTemplates(
        featureTemplateDir,
        featurePath,
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
    if (_isInFlutterProject(Directory.current.path)) {
      return Directory.current;
    }

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

  @override
  String formatName(String name) {
    return ReCase(name).pascalCase;
  }

  Map<String, dynamic> _parseOptions(List<String> args) {
    final options = <String, dynamic>{
      'android_language': null,
      'ios_language': null,
      'include_linter': null,
    };

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
    final pen = AnsiPen()
      ..blue(bold: true);

    if (options['android_language'] == null) {
      print('\n${pen('Android Language')}');
      print('Select your preferred language for Android:');
      print('1. Kotlin (recommended)');
      print('2. Java');

      final choice = stdin.readLineSync()?.trim();
      options['android_language'] = choice == '1' ? 'kotlin' : 'java';
    }

    if (options['ios_language'] == null) {
      print('\n${pen('iOS Language')}');
      print('Select your preferred language for iOS:');
      print('1. Swift (recommended)');
      print('2. Objective-C');

      final choice = stdin.readLineSync()?.trim();
      options['ios_language'] = choice == '1' ? 'swift' : 'objc';
    }

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

  void _createFlutterProject(String projectName, String projectPath,
      Map<String, dynamic> options) {
    final androidLanguage = options['android_language'] ?? 'kotlin';
    final orgName = "com.${options['company_domain']}.$projectName";

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
        projectPath,
      ],
      runInShell: true,
    );

    if (flutterCreateProcess.exitCode != 0) {
      throw Exception('Flutter create failed: ${flutterCreateProcess.stderr}');
    }

    print(flutterCreateProcess.stdout);

    if (options['include_linter'] == true) {
      _addLinter(projectPath);
    }

    // Add Bipul dependencies to pubspec.yaml
    _addBipulDependencies(projectPath);
  }


  void _applyBipulStructure(String projectPath, String projectName,
      Map<String, dynamic> options) {
    print('\n🏗️ Applying Bipul Architecture...');

    final projectLibPath = p.join(projectPath, 'lib');
    final templatesProjectDir = Directory('lib/templates/project/lib');

    if (!templatesProjectDir.existsSync()) {
      throw Exception(
          "Cloned templates not found at ${templatesProjectDir.path}");
    }

    // Copy and render all `.mustache` files in lib/
    TemplateRenderer.renderAllTemplates(
      templatesProjectDir.path,
      projectLibPath,
      {
        'project_name': projectName,
        'ProjectName': formatName(projectName),
        'android_language': options['android_language'] ?? 'kotlin',
        'ios_language': options['ios_language'] ?? 'swift',
        'include_linter': options['include_linter'] == true ? true : false,
      },
    );

    // Generate home feature
    final featureSourceDir = 'lib/templates/project/lib/features/home';
    final featureTargetDir = p.join(projectPath, 'lib', 'features', 'home');

    print('\n🧩 Generating feature "home"...');
    TemplateRenderer.renderAllTemplates(
      featureSourceDir,
      featureTargetDir,
      {
        'project_name': projectName,
        'ProjectName': formatName(projectName),
        'feature_name': 'home',
        'FeatureName': 'Home',
      },
    );

    // Run flutter pub get and dart format after applying templates
    _runPostSetupCommands(projectPath);
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

    final analysisOptions = '''
include: package:flutter_lints/flutter.yaml

analyzer:
  enable-experiment:
    - const-candidates-2022
    - pattern-type-nulls
''';

    File(p.join(projectPath, 'analysis_options.yaml'))
        .writeAsStringSync(analysisOptions);

    final pubAddProcess = Process.runSync(
      'flutter',
      ['pub', 'add', 'flutter_lints'],
      workingDirectory: projectPath,
    );

    print(pubAddProcess.stdout);
  }
  void _addBipulDependencies(String projectPath) {
    print('\n📦 Adding Bipul dependencies...');

    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    var content = pubspecFile.readAsStringSync();

    // Map of dependencies with their version constraints
    final dependencies = {
      'flutter_cache_manager': '^3.3.1',
      'get': '^4.6.6',
      'shared_preferences': '^2.2.2',
      'logging': '^1.2.0',
      'get_it': '^7.6.4',
      'shimmer': '^3.0.0',
      'flutter_riverpod': '^2.4.9',
      'connectivity_plus': '^5.0.2',
    };

    // Find the dependencies section
    final dependenciesIndex = content.indexOf('dependencies:');
    if (dependenciesIndex == -1) {
      throw Exception('Could not find dependencies section in pubspec.yaml');
    }

    // Find the flutter dependency
    final flutterIndex = content.indexOf('flutter:', dependenciesIndex);
    if (flutterIndex == -1) {
      throw Exception('Could not find flutter dependency in pubspec.yaml');
    }

    // Find the end of the flutter dependency block (after sdk: flutter)
    final sdkIndex = content.indexOf('sdk: flutter', flutterIndex);
    if (sdkIndex == -1) {
      throw Exception('Could not find sdk: flutter in pubspec.yaml');
    }

    // Find the next line after sdk: flutter
    final sdkLineEnd = content.indexOf('\n', sdkIndex);
    if (sdkLineEnd == -1) {
      throw Exception('Could not find end of sdk: flutter line');
    }

    // Insertion point is after the sdk: flutter line
    final insertionPoint = sdkLineEnd + 1;

    // Create the dependencies string with proper indentation
    final dependenciesString = dependencies.entries
        .map((entry) => '  ${entry.key}: ${entry.value}')
        .join('\n') + '\n';

    // Insert the dependencies after the flutter block
    content = content.substring(0, insertionPoint) +
        '\n' +
        dependenciesString +
        content.substring(insertionPoint);

    pubspecFile.writeAsStringSync(content);
    print('✅ Added Bipul dependencies with version constraints to pubspec.yaml');
  }

  void _runPostSetupCommands(String projectPath) {
    print('\n📦 Running flutter pub get...');
    final pubGetProcess = Process.runSync(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectPath,
    );

    if (pubGetProcess.exitCode != 0) {
      print('❌ Flutter pub get failed: ${pubGetProcess.stderr}');
    } else {
      print('✅ Flutter pub get completed successfully');
    }

    print('\n🎨 Running dart format...');
    final formatProcess = Process.runSync(
      'dart',
      ['format', '.'],
      workingDirectory: projectPath,
    );

    if (formatProcess.exitCode != 0) {
      print('❌ Dart format failed: ${formatProcess.stderr}');
    } else {
      print('✅ Code formatting completed successfully');
    }
  }

  void _showSuccessMessage(String projectName, String projectPath,
      Map<String, dynamic> options) {
    print('\n✅ Successfully created Flutter project "$projectName"');
    print('\n👉 Next steps:');
    print('  cd $projectName');
    print('  flutter run');
    print('\n✨ Your project is now ready with:');
    print('  ✓ Clean Architecture Structure');
    print('  ✓ DRY & SOLID Principles');
    print('  ✓ Scalable Feature Organization');
    print('  ✓ Home Feature Pre-Installed');
    print('  ✓ Bipul Dependencies Added');
    print('  ✓ Code Formatted');
    print(
        '  ✓ Android language: ${(options['android_language'] ?? 'kotlin')
            .toUpperCase()}');
    print(
        '  ✓ iOS language: ${(options['ios_language'] ?? 'swift')
            .toUpperCase()}');
    print(
        '  ✓ Linter: ${options['include_linter']
            ? 'Included'
            : 'Not included'}');
    print('  ✓ Created using official flutter create');
    print('  ✓ Fully compatible with Flutter ecosystem');

    print('\n📦 Included dependencies:');
    print('  ✓ flutter_cache_manager - For caching');
    print('  ✓ get - For navigation & state management');
    print('  ✓ shared_preferences - For local storage');
    print('  ✓ logging - For logging');
    print('  ✓ get_it - For dependency injection');
    print('  ✓ shimmer - For loading animations');
    print('  ✓ flutter_riverpod - For state management');
    print('  ✓ connectivity_plus - For network connectivity');
  }

  void _showFeatureSuccessMessage(String featureName, [String? projectPath]) {
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
    final pen = AnsiPen()
      ..red(bold: true);
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

  @override
  String formatProjectName(String name) {
    String formatted = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    if (formatted.isNotEmpty && !RegExp(r'^[a-z]').hasMatch(formatted)) {
      formatted = 'app_$formatted';
    }

    return formatted.isEmpty ? 'my_app' : formatted;
  }
}