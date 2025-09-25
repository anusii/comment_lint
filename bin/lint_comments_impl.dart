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
      print('Debug: check=${argResults['check']}, set-exit-if-changed=${argResults['set-exit-if-changed']}, dry-run=${argResults['dry-run']}');
      print('Debug: checkOnly=$checkOnly, dryRun=$dryRun');
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
  // Start from the current script location and work upward.
  var current = Directory(Platform.script.toFilePath()).parent;

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

  return null;
}

/// Process a single path (file or directory).
Future<int> _processPath(
  String targetPath,
  String scriptsDir,
  String packageRoot,
  {required bool checkOnly,
  required bool dryRun,
  required bool verbose}) async {
  // Determine which script to use.
  final scriptName = checkOnly ? 'lint_comments.sh' : 'fix_comments.sh';
  final scriptPath = path.join(scriptsDir, scriptName);

  // Verify the script exists.
  final scriptFile = File(scriptPath);
  if (!scriptFile.existsSync()) {
    print('Error: Script not found: $scriptPath');
    return 1;
  }

  if (verbose) {
    print('Script path: $scriptPath');
    print('Script exists: ${scriptFile.existsSync()}');
  }

  // Prepare arguments for the script.
  final scriptArgs = <String>[targetPath];
  if (dryRun && !checkOnly) {
    scriptArgs.add('--dry-run');
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
        print('Running: bash $bashScriptPath ${scriptArgs.join(' ')} (from $packageRoot)');
      }
      try {
        // Set working directory to the package root when running the script
        result = await Process.run('bash', [bashScriptPath, ...scriptArgs],
            workingDirectory: packageRoot);
      } catch (e) {
        print('Error: bash not found on Windows. Please install Git Bash or WSL.');
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