import 'dart:io';  // ← Add this line
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
    return name.split(RegExp(r'[_-]')).map((s) => s[0].toUpperCase() + s.substring(1)).join();
  }

  bool isInteractive() {
    return stdin.hasTerminal;  // Now this works!
  }
}