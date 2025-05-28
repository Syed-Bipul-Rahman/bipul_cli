import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:mustache_template/mustache_template.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:bipul_cli/utils/file_utils.dart';
import 'package:bipul_cli/utils/template_renderer.dart';
import 'package:bipul_cli/utils/validator.dart';
import 'package:bipul_cli/commands/base_command.dart';
import 'package:recase/recase.dart';

class ProjectCommand extends BaseCommand {
  final String templatePath = 'lib/templates/project';

  @override
  void run(List<String> args) {
    if (!validateArgs(args)) return;

    final projectName = args[0];
    final Map<String, dynamic> options = _parseOptions(args);

    final projectPath = p.join(Directory.current.path, projectName);

    if (Directory(projectPath).existsSync()) {
      print('\n❌ A directory named "$projectName" already exists!');
      return;
    }

    _askConfigurationOptions(options);

    _createProject(projectName, projectPath, options);
    _createHomeFeature(projectName, projectPath);
    _showSuccessMessage(projectName, projectPath, options);
  }

  Map<String, dynamic> _parseOptions(List<String> args) {
    final options = <String, dynamic>{
      'android_language': null,
      'ios_language': null,
      'include_linter': null,
    };

    // Parse options from command line if provided
    for (final arg in args.sublist(1)) {
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
      ..blue(bold: true)
      ..bgBlack();

    // Ask for Android language
    if (options['android_language'] == null) {
      print('\n${pen("Android Language")}');
      print('Select your preferred language for Android:');
      print('1. Kotlin (recommended)');
      print('2. Java');

      final choice = stdin.readLineSync()?.trim();
      options['android_language'] = choice == '1' ? 'kotlin' : 'java';
    }

    // Ask for iOS language
    if (options['ios_language'] == null) {
      print('\n${pen("iOS Language")}');
      print('Select your preferred language for iOS:');
      print('1. Swift (recommended)');
      print('2. Objective-C');

      final choice = stdin.readLineSync()?.trim();
      options['ios_language'] = choice == '1' ? 'swift' : 'objc';
    }

    // Ask about linter
    if (options['include_linter'] == null) {
      print('\n${pen("Linter")}');
      print('Would you like to include Flutter linter?');
      print('1. Yes (recommended)');
      print('2. No');

      final choice = stdin.readLineSync()?.trim();
      options['include_linter'] = choice == '1';
    }
  }

  void _createProject(
      String projectName, String projectPath, Map<String, dynamic> options) {
    final templateDir = Directory(templatePath);
    if (!templateDir.existsSync()) {
      throw Exception('Template directory not found at $templatePath');
    }

    FileUtils.copyDirectory(templateDir, Directory(projectPath));
    _replacePlaceholders(projectPath, projectName, options);

    // Configure platform-specific settings
    _configurePlatformLanguages(projectPath, options);

    // Add or remove linter based on user preference
    _configureLinter(projectPath, options);
  }

  void _replacePlaceholders(
      String projectPath, String projectName, Map<String, dynamic> options) {
    final filesToProcess = [
      p.join(projectPath, 'pubspec.yaml'),
      p.join(projectPath, 'lib', 'main.dart'),
      p.join(projectPath, 'README.md'),
    ];

    for (final filePath in filesToProcess) {
      if (File(filePath).existsSync()) {
        var content = File(filePath).readAsStringSync();
        content = content
            .replaceAll('{{project_name}}', projectName)
            .replaceAll('{{ProjectName}}', formatName(projectName))
            .replaceAll('{{android_language}}', options['android_language'])
            .replaceAll('{{ios_language}}', options['ios_language']);

        File(filePath).writeAsStringSync(content);
      }
    }
  }

  void _configurePlatformLanguages(
      String projectPath, Map<String, dynamic> options) {
    // Remove unwanted platform languages
    final androidPath = p.join(projectPath, 'android');
    final iosPath = p.join(projectPath, 'ios');

    // For Android
    if (options['android_language'] == 'kotlin') {
      // Remove Java files
      final javaDir = p.join(androidPath, 'app', 'src', 'main', 'java');
      if (Directory(javaDir).existsSync()) {
        Directory(javaDir).deleteSync(recursive: true);
      }
    } else {
      // Remove Kotlin files
      final kotlinDir = p.join(androidPath, 'app', 'src', 'main', 'kotlin');
      if (Directory(kotlinDir).existsSync()) {
        Directory(kotlinDir).deleteSync(recursive: true);
      }
    }

    // For iOS
    if (options['ios_language'] == 'swift') {
      // Remove Objective-C files
      final objcFiles = [
        p.join(iosPath, 'Runner', 'AppDelegate.m'),
        p.join(iosPath, 'Runner', 'main.m'),
      ];

      for (final file in objcFiles) {
        if (File(file).existsSync()) {
          File(file).deleteSync();
        }
      }
    } else {
      // Remove Swift files
      final swiftFiles = [
        p.join(iosPath, 'Runner', 'AppDelegate.swift'),
        p.join(iosPath, 'Runner', 'Runner-Bridging-Header.h'),
      ];

      for (final file in swiftFiles) {
        if (File(file).existsSync()) {
          File(file).deleteSync();
        }
      }
    }
  }

  void _configureLinter(String projectPath, Map<String, dynamic> options) {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    var content = pubspecFile.readAsStringSync();

    if (options['include_linter'] == true) {
      // Add flutter_lints dependency
      if (!content.contains('flutter_lints')) {
        content = content.replaceFirst(
            'dev_dependencies:',
            'dev_dependencies:\n  flutter_lints: ^2.0.0',
            content.indexOf('dev_dependencies:'));
      }

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
    } else {
      // Remove flutter_lints if present
      content = content.replaceAll(
          RegExp(r'\s+flutter_lints: ^.*$', multiLine: true), '');

      // Remove analysis_options.yaml if exists
      final analysisFile = File(p.join(projectPath, 'analysis_options.yaml'));
      if (analysisFile.existsSync()) {
        analysisFile.deleteSync();
      }
    }

    pubspecFile.writeAsStringSync(content);
  }

  void _createHomeFeature(String projectName, String projectPath) {
    final featurePath = p.join(projectPath, 'lib', 'features', 'home');
    Directory(featurePath).createSync(recursive: true);

    // Generate home feature files from templates
    TemplateRenderer.renderFeature(
      'home',
      featurePath,
      {
        'project_name': projectName,
        'ProjectName': formatName(projectName),
        'feature_name': 'home',
        'FeatureName': 'Home',
      },
    );
  }

  void _showSuccessMessage(
      String projectName, String projectPath, Map<String, dynamic> options) {
    final pen = AnsiPen()
      ..green(bold: true)
      ..bgBlack();
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
  }

  String formatName(String name) {
    return ReCase(name).pascalCase;
  }
}
