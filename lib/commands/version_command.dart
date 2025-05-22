import 'package:ansicolor/ansicolor.dart';

class VersionCommand {
  static const String currentVersion = '0.1.0';

  void run(List<String> args) {
    final pen = AnsiPen()..green(bold: true);
    print('${pen('Bipul CLI')} version $currentVersion');
    print('Built with ❤️ for Flutter developers');
  }
}
