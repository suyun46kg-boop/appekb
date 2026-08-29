import 'dart:io';

void main(List<String> args) {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found.');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(
    r'^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+([0-9]+))?',
    multiLine: true,
  );

  final match = versionRegex.firstMatch(content);
  if (match == null) {
    stderr.writeln('Error: Could not find version in pubspec.yaml');
    exit(1);
  }

  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(2)!);
  var patch = int.parse(match.group(3)!);
  var build = match.group(4) != null ? int.parse(match.group(4)!) : 1;

  final currentVersion = '$major.$minor.$patch+$build';

  if (args.isEmpty || args[0] == 'get' || args[0] == 'current') {
    stdout.writeln('Current version: $currentVersion');
    return;
  }

  final command = args[0].toLowerCase();
  String newVersion;

  switch (command) {
    case 'build':
      build += 1;
      newVersion = '$major.$minor.$patch+$build';
      break;

    case 'patch':
      patch += 1;
      build += 1;
      newVersion = '$major.$minor.$patch+$build';
      break;

    case 'minor':
      minor += 1;
      patch = 0;
      build += 1;
      newVersion = '$major.$minor.$patch+$build';
      break;

    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      build += 1;
      newVersion = '$major.$minor.$patch+$build';
      break;

    case 'set':
      if (args.length < 2 || args[1].trim().isEmpty) {
        stderr.writeln('Error: Please provide a version to set (e.g. dart run tool/bump_version.dart set 1.2.0+5)');
        exit(1);
      }
      final target = args[1].trim();
      final validFormat = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$');
      if (!validFormat.hasMatch(target)) {
        stderr.writeln('Error: Invalid version format "$target". Expected format: X.Y.Z or X.Y.Z+N');
        exit(1);
      }
      newVersion = target.contains('+') ? target : '$target+$build';
      break;

    default:
      stderr.writeln('Unknown command: "$command"');
      stderr.writeln('Usage: dart run tool/bump_version.dart [build|patch|minor|major|set <version>|get]');
      exit(1);
  }

  final newContent = content.replaceFirst(
    versionRegex,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(newContent);
  stdout.writeln('Version updated: $currentVersion -> $newVersion');
}
