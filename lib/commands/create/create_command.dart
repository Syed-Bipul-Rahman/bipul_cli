import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:bipul_cli/commands/base_command.dart';

class CreateCommand extends BaseCommand {
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

    final type = parts[0];
    final name = parts[1];

    switch (type) {
      case 'project':
        print('Creating project: $name');
        // We'll add project creation logic soon!
        break;
      case 'feature':
        print('Creating feature: $name');
        // We'll add feature creation logic soon!
        break;
      default:
        print('\n❌ Unknown create type: "$type"');
        _showUsage();
    }
  }

  void _showUsage() {
    final pen = AnsiPen()..red(bold: true);
    print('\n${pen('ERROR')}: Invalid create command format');
    print('''
Usage:
  bipul create project:project_name
  bipul create feature:feature_name

Example:
  bipul create project:my_cool_app
  bipul create feature:product_details
''');
  }
}