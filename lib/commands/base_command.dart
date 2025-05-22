import 'dart:io'; // ← Add this line
import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';

abstract class BaseCommand {
  bool validateArgs(List<String> args) {
    if (args.isEmpty) {
      print('\n❌ Please provide a name for the item you want to create.');
      print('Example: bipul create project:my_app');
      return false;
    }
    return true;
  }

  String formatName(String name) {
    return name
        .split(RegExp(r'[_-]'))
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join();
  }

  bool isInteractive() {
    return stdin.hasTerminal; // Now this works!
  }

  /// Validates if a project name is valid according to Dart package rules
  bool isValidProjectName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }

  /// Formats project name to be Dart-compliant
  String formatProjectName(String name) {
    // Replace hyphens with underscores
    var formatted = name.replaceAll('-', '_');

    // Remove any invalid characters
    formatted = formatted.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Ensure starts with a letter
    if (formatted.isEmpty || !RegExp(r'[a-z]').hasMatch(formatted[0])) {
      formatted = 'app_$formatted';
    }

    return formatted;
  }
}
