# bipul_cli

A Dart-based Command Line Interface (CLI) tool to streamline Flutter project and feature creation with a clean, scalable architecture following DRY and SOLID principles.

## Features

- **Project Creation**: Generate a new Flutter project with a pre-configured clean architecture structure.
- **Feature Generation**: Add modular, organized features to existing Flutter projects.
- **Customizable Options**:
    - Choose Android language (Kotlin or Java)
    - Select iOS language (Swift or Objective-C)
    - Optionally include Flutter linter for code quality
- **Template-Based**: Uses predefined templates for consistency and rapid setup.
- **Scalable Design**: Organizes code into data, domain, and presentation layers.

## Installation

Add `bipul_cli` to your development dependencies via pub.dev:

```bash
dart pub global activate bipul_cli
```

This installs the CLI globally, allowing you to run `bipul` commands from any terminal.

### Prerequisites
- **Dart SDK**: Version 2.12.0 or higher
- **Flutter SDK**: Version 3.0.0 or higher
- Ensure `flutter` and `dart` are in your system's PATH

## Usage

Run the CLI using the `bipul` command. The primary command is `create`, which supports two types: `project` and `feature`.

### Create a New Flutter Project
Generate a new Flutter project with a clean architecture structure:

```bash
bipul create project:my_cool_app
```

**Options**:
- `--android=java|kotlin`: Set the Android language (default: kotlin)
- `--ios=objc|swift`: Set the iOS language (default: swift)
- `--linter` or `--with-linter`: Include Flutter linter
- `--no-linter`: Skip linter setup

**Example**:
```bash
bipul create project:my_cool_app --android=kotlin --ios=swift --linter
```
- Prompts for company domain (e.g., `com.yourcompany`)
- Creates a project in `./my_cool_app` with a `lib` folder structured for clean architecture
- Includes a pre-installed `home` feature

### Create a New Feature
Add a feature to an existing Flutter project:

```bash
bipul create feature:user_profile
```
- Run this from within a Flutter project directory
- Creates a `lib/features/user_profile` folder with:
    - `data/` (datasources, models, repositories)
    - `domain/` (entities, repositories, usecases)
    - `presentation/` (bloc, pages, widgets)

**Example**:
```bash
bipul create feature:login
```
- Generates a `login` feature with all necessary layers
- Ready for routing and logic implementation

### Project Structure
After running `bipul create project:my_cool_app`, your project will have:
```
my_cool_app/
├── lib/
│   ├── features/
│   │   ├── home/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── pages/
│   │   │       └── widgets/
│   └── main.dart
├── pubspec.yaml
└── analysis_options.yaml (if linter included)
```

## Configuration
- **Templates**: The CLI uses templates from `lib/templates/project` for projects and features. Customize these to fit your needs.
- **Validation**: Project and feature names must:
    - Start with a lowercase letter
    - Use only lowercase letters, numbers, and underscores
    - Avoid special characters or spaces

## Example Workflow
1. **Create a Project**:
   ```bash
   bipul create project:my_cool_app --android=kotlin --ios=swift --linter
   ```
2. **Navigate to Project**:
   ```bash
   cd my_cool_app
   ```
3. **Run Pub Get**:
   ```bash
   flutter pub get
   ```
4. **Add a Feature**:
   ```bash
   bipul create feature:login
   ```
5. **Implement Logic**:
    - Add business logic in `lib/features/login/domain/usecases`
    - Update UI in `lib/features/login/presentation/pages`

## Contributing
We welcome contributions! To get started:
1. Fork the repository
2. Clone your fork: `git clone https://github.com/syed-Bipul-Rahman/bipul_cli.git`
3. Create a branch: `git checkout -b my-feature`
4. Make changes and test
5. Submit a pull request

## Issues
Report bugs or suggest features via the [GitHub Issues page](https://github.com/syed-Bipul-Rahman/bipul_cli/issues).

## License
This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments
- Built with Dart and Flutter
- Uses packages: `path`, `ansicolor`, `recase`
- Inspired by clean architecture principles

---
Happy coding with `bipul_cli`! 