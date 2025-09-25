#!/usr/bin/env dart
// Comment Lint Tool - entry point
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

import 'lint_comments_impl.dart' as lint_impl;

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Print usage information',)
    ..addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output',)
    ..addFlag('set-exit-if-changed',
        negatable: false,
        help:
            'Return exit code 1 if comments would be changed (like dart format)',)
    ..addFlag('check',
        abbr: 'c',
        negatable: false,
        help:
            'Check comment style without fixing (same as --set-exit-if-changed)',)
    ..addFlag('dry-run', negatable: false, help: 'Same as --check',);

  try {
    final argResults = parser.parse(args);

    if (argResults['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }

    // Get paths from arguments, default to 'lib' if none provided.

    List<String> filePaths = argResults.rest;
    if (filePaths.isEmpty) {
      filePaths = ['lib'];
    }

    // Convert our simplified args to the implementation format.

    final newArgs = <String>[];

    if (argResults['verbose'] as bool) newArgs.add('--verbose');
    if (argResults['set-exit-if-changed'] as bool ||
        argResults['check'] as bool) {
      newArgs.add('--set-exit-if-changed');
    }
    if (argResults['dry-run'] as bool) {
      newArgs.add('--dry-run');
    }

    // Always recursive since we're defaulting to directories.
    newArgs.add('--recursive');

    // Add the paths.

    newArgs.addAll(filePaths);

    // Call the existing implementation.

    lint_impl.main(newArgs);
  } catch (e) {
    print('Error: $e');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('''
comment_lint - Check and fix comment style in Dart files.

Usage: dart run comment_lint [options] [paths]

If no paths are specified, defaults to checking the 'lib' directory.

${parser.usage}

Examples:
  # Check comment style in lib directory (default)
  dart run comment_lint --set-exit-if-changed

  # Check specific directories
  dart run comment_lint --set-exit-if-changed lib test

  # Fix comment style in lib directory
  dart run comment_lint

  # Check with verbose output
  dart run comment_lint --set-exit-if-changed -v

  # Preview changes without applying them
  dart run comment_lint --dry-run

CI/CD Usage:
  Similar to dart format --set-exit-if-changed, this tool returns:
  • Exit code 0: No changes needed (CI passes)
  • Exit code 1: Comment style issues found (CI fails)

Comment Style Rules:
  • Comments should end with periods (except uppercase headers)
  • Uppercase headers like "// MOVIE METHODS" should not have periods
  • No periods after colons or commas in comments
  • Blank lines should separate comments from code
  • Multi-line continuation comments handled intelligently
''');
}
