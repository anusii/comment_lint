#!/usr/bin/env dart
// Comment Lint Implementation - bridges Dart CLI with bash scripts
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Print usage information')
    ..addFlag('recursive',
        abbr: 'r',
        negatable: false,
        help: 'Recursively search for Dart files in directories')
    ..addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output')
    ..addFlag('check',
        abbr: 'c',
        negatable: false,
        help: 'Check comment style without fixing (useful for CI/CD)')
    ..addFlag('set-exit-if-changed',
        negatable: false,
        help:
            'Return exit code 1 if comments would be changed (like dart format)')
    ..addFlag('dry-run',
        negatable: false,
        help: 'Same as --check, show what would be fixed without fixing');

  try {
    final argResults = parser.parse(args);

    if (argResults['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }

    // Get paths from arguments.
    List<String> filePaths = argResults.rest;
    if (filePaths.isEmpty) {
      print('Error: No paths provided');
      exit(1);
    }

    final verbose = argResults['verbose'] as bool;
    final checkOnly = argResults['check'] as bool ||
        argResults['set-exit-if-changed'] as bool;
    final dryRun = argResults['dry-run'] as bool;

    if (verbose) {
      print(
          'Debug: check=${argResults['check']}, set-exit-if-changed=${argResults['set-exit-if-changed']}, dry-run=${argResults['dry-run']}');
      print('Debug: checkOnly=$checkOnly, dryRun=$dryRun');
      print('Debug: Platform.script = ${Platform.script}');
      print(
          'Debug: Platform.script.toFilePath() = ${Platform.script.toFilePath()}');
    }

    // Find the package root directory to locate scripts.
    final packageRoot = _findPackageRoot();
    if (packageRoot == null) {
      print('Error: Could not find comment_lint package root');
      exit(1);
    }

    final scriptsDir = path.join(packageRoot, 'scripts');
    if (verbose) {
      print('Package root: $packageRoot');
      print('Scripts directory: $scriptsDir');
    }

    // Process each path.
    var totalExitCode = 0;
    for (final filePath in filePaths) {
      final exitCode = await _processPath(
        filePath,
        scriptsDir,
        packageRoot,
        checkOnly: checkOnly,
        dryRun: dryRun,
        verbose: verbose,
      );
      if (exitCode != 0) {
        totalExitCode = exitCode;
      }
    }

    exit(totalExitCode);
  } catch (e) {
    print('Error: $e');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('''
comment_lint implementation - Check and fix comment style in Dart files.

Usage: dart run comment_lint:lint_comments_impl [options] [paths]

${parser.usage}
''');
}

/// Find the comment_lint package root directory.
String? _findPackageRoot() {
  final scriptPath = Platform.script.toFilePath();

  // Check if we're running from a snapshot (dependency scenario)
  if (scriptPath
          .contains('.dart_tool${path.separator}pub${path.separator}bin') &&
      scriptPath.endsWith('.snapshot')) {
    // Running from snapshot, need to find the actual package in pub cache
    // Get the current working directory (should be the consuming project)
    final workingDir = Directory.current.path;

    // Try to find the package in the local .dart_tool/package_config.json
    final packageConfigPath =
        path.join(workingDir, '.dart_tool', 'package_config.json');
    final packageConfigFile = File(packageConfigPath);

    if (packageConfigFile.existsSync()) {
      try {
        final configContent = packageConfigFile.readAsStringSync();
        // Look for comment_lint package entry
        final regex = RegExp(r'"comment_lint"[^}]*"rootUri"\s*:\s*"([^"]+)"',
            dotAll: true);
        final match = regex.firstMatch(configContent);

        if (match != null) {
          var packagePath = match.group(1)!;

          // Handle file:// URI prefix
          if (packagePath.startsWith('file://')) {
            packagePath = Uri.parse(packagePath).toFilePath();
          }

          // Handle relative paths starting with ../
          if (packagePath.startsWith('../')) {
            packagePath = path
                .normalize(path.join(workingDir, '.dart_tool', packagePath));
          }

          // Verify this is actually the comment_lint package
          final pubspec = File(path.join(packagePath, 'pubspec.yaml'));
          if (pubspec.existsSync()) {
            final content = pubspec.readAsStringSync();
            if (content.contains('name: comment_lint')) {
              return packagePath;
            }
          }
        }
      } catch (e) {
        // Continue with other methods
      }
    }
  }

  // First, try the development scenario - start from the current script location
  var current = Directory(scriptPath).parent;

  while (current.path != current.parent.path) {
    final pubspec = File(path.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      try {
        final content = pubspec.readAsStringSync();
        if (content.contains('name: comment_lint')) {
          return current.path;
        }
      } catch (e) {
        // Continue searching.
      }
    }
    current = current.parent;
  }

  // If not found in development scenario, try to find it in pub cache
  // This happens when the package is installed as a dependency
  if (scriptPath.contains(path.join('cache', 'git')) ||
      scriptPath.contains(path.join('cache', 'hosted'))) {
    // Extract the package directory from the script path
    final scriptDir = Directory(scriptPath).parent.parent;
    final pubspec = File(path.join(scriptDir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      try {
        final content = pubspec.readAsStringSync();
        if (content.contains('name: comment_lint')) {
          return scriptDir.path;
        }
      } catch (e) {
        // Continue to return null
      }
    }
  }

  return null;
}

/// Process a single path (file or directory).
Future<int> _processPath(
    String targetPath,
    String scriptsDir,
    String packageRoot, {
    required bool checkOnly,
    required bool dryRun,
    required bool verbose,
}) async {
  // Determine which script to use.
  final scriptName = checkOnly ? 'lint_comments.sh' : 'fix_comments.sh';
  final scriptPath = path.join(scriptsDir, scriptName);

  // Verify the script exists.
  final scriptFile = File(scriptPath);
  if (!scriptFile.existsSync()) {
    print('Error: Script not found: $scriptPath');
    return 1;
  }

  // Convert target path to absolute path if it's not already
  final absoluteTargetPath = path.isAbsolute(targetPath)
      ? targetPath
      : path.join(Directory.current.path, targetPath);

  // Prepare arguments for the script.
  // Convert Windows paths to Unix-style for bash compatibility
  final bashTargetPath = Platform.isWindows
      ? absoluteTargetPath.replaceAll('\\', '/')
      : absoluteTargetPath;

  if (verbose) {
    print('Script path: $scriptPath');
    print('Script exists: ${scriptFile.existsSync()}');
    print('Target path (original): $targetPath');
    print('Target path (absolute): $absoluteTargetPath');
    print('Target path (bash): $bashTargetPath');
  }

  final scriptArgs = <String>[bashTargetPath];
  if (dryRun && !checkOnly) {
    scriptArgs.add('--dry-run');
  }
  if (verbose) {
    scriptArgs.add('--verbose');
  }

  try {
    // Make the script executable (Unix/Linux/macOS).
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', scriptPath]);
    }

    // Execute the script.
    ProcessResult result;
    if (Platform.isWindows) {
      // On Windows, use relative path from package root
      final relativePath = path.relative(scriptPath, from: packageRoot);
      final bashScriptPath = relativePath.replaceAll('\\', '/');
      if (verbose) {
        print('Relative script path: $relativePath');
        print('Bash script path: $bashScriptPath');
        print('Script args: ${scriptArgs.join(' ')}');
        print(
            'Running: bash $bashScriptPath ${scriptArgs.join(' ')} (from $packageRoot)');
      }
      try {
        // First try using Git Bash explicitly
        String? gitBashPath;
        final possibleGitBashPaths = [
          'C:/Program Files/Git/bin/bash.exe',
          'C:/Program Files (x86)/Git/bin/bash.exe',
          'C:/Git/bin/bash.exe',
        ];

        for (final gitBashCandidate in possibleGitBashPaths) {
          if (File(gitBashCandidate).existsSync()) {
            gitBashPath = gitBashCandidate;
            break;
          }
        }

        if (gitBashPath != null) {
          if (verbose) {
            print('Using Git Bash at: $gitBashPath');
          }
          result = await Process.run(
              gitBashPath, [bashScriptPath, ...scriptArgs],
              workingDirectory: packageRoot);
        } else {
          // Fall back to system bash (might be WSL) - convert paths to WSL format
          final wslPackageRoot = _convertToWSLPath(packageRoot);
          final wslScriptArgs = scriptArgs.map(_convertToWSLPath).toList();

          if (verbose) {
            print('Using system bash (possibly WSL)');
            print('WSL package root: $wslPackageRoot');
            print('WSL script args: ${wslScriptArgs.join(' ')}');
          }

          result = await Process.run('bash', [bashScriptPath, ...wslScriptArgs],
              workingDirectory: wslPackageRoot);
        }
      } catch (e) {
        print(
            'Error: bash not found on Windows. Please install Git Bash or WSL.');
        return 1;
      }
    } else {
      result = await Process.run(scriptPath, scriptArgs);
    }

    // Print output.
    if (result.stdout.toString().isNotEmpty) {
      print(result.stdout.toString().trimRight());
    }
    if (result.stderr.toString().isNotEmpty) {
      stderr.write(result.stderr.toString());
    }

    return result.exitCode;
  } catch (e) {
    print('Error executing script: $e');
    return 1;
  }
}

/// Convert Windows path to WSL format
String _convertToWSLPath(String windowsPath) {
  if (!windowsPath.contains(':'))
    return windowsPath; // Already not a Windows path

  return windowsPath
      .replaceAll('\\', '/')
      .replaceFirstMapped(RegExp(r'^([A-Za-z]):'), (match) {
    return '/mnt/${match.group(1)!.toLowerCase()}';
  });
}
