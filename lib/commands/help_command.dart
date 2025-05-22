import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';

class HelpCommand {
  final Logger _logger = Logger('HelpCommand');

  void run(List<String> args) {
    AnsiPen pen = AnsiPen()..white(bold: true);

    print(pen('''
Welcome to Bipul CLI 🛠️
A smart, opinionated CLI for creating Flutter projects with clean architecture.
'''));

    print('''
${_highlight('USAGE')}
  bipul <command> [arguments]

${_highlight('AVAILABLE COMMANDS')}
  create    Create new Flutter project or feature
  help      Display help information
  version   Show version information

${_highlight('CREATE COMMAND USAGE')}
  bipul create project:project_name
  bipul create feature:feature_name

${_highlight('EXAMPLES')}
  bipul create project:my_app
  bipul create feature:product_details
  bipul help
  bipul version
''');
  }

  String _highlight(String text) {
    final pen = AnsiPen()..blue(bold: true);
    return pen(text);
  }
}