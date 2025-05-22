import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'commands/help_command.dart';
import 'commands/version_command.dart';
import 'utils/logger.dart';
import 'package:bipul_cli/commands/create/create_command.dart';
class BipulCli {
  final Logger _logger = Logger('BipulCli');

  void run(List<String> args) {
    setupLogger();

    try {
      final parser = ArgParser()
        ..addCommand('create')
        ..addCommand('help')
        ..addCommand('version');

      final results = parser.parse(args);

      if (results.command == null) {
        _showUsage();
        return;
      }

      switch (results.command!.name) {
        case 'create':
          CreateCommand().run(results.command!.arguments);
          break;
        case 'help':
          HelpCommand().run([]);
          break;
        case 'version':
          VersionCommand().run([]);
          break;
        default:
          _showUsage();
      }
    } catch (e, stackTrace) {
      _logger.severe('Error executing command: $e', e, stackTrace);
      print('\n🚨 Error: $e');
    }
  }

  void _showUsage() {
    print('''
Welcome to Bipul CLI 🎉
A smart, opinionated CLI for creating Flutter projects with clean architecture.

Usage: bipul <command> [arguments]

Available commands:
  create    Create new Flutter project or feature
  help      Display help information
  version   Show version information

Run "bipul help" for more details.
''');
  }
}