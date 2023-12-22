import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_to_debian/dependencies.dart';
import 'package:flutter_to_debian/flutter_to_debian.dart';
import 'package:flutter_to_debian/usage.dart';

const cmdDependencies = 'dependencies';
const cmdHelp = 'help';
const cmdCreate = 'create';
const cmdBuild = 'build';

void main(List<String> arguments) async {
  exitCode = 0;

  final parser = ArgParser()
    ..addCommand(cmdDependencies, DependencyFinderArgParser.createParser())
    ..addCommand(cmdHelp)
    ..addCommand(cmdCreate, BuildArgParser.createParser())
    ..addCommand(cmdBuild, BuildArgParser.createParser());

  ArgResults argResults = parser.parse(arguments);
  final restArgs = argResults.rest;

  final command = argResults.command;

  if (command == null || command.name == cmdBuild) {
    try {
      await BuildArgParser.run(command);
    } catch (e) {
      exitCode = 2;
      rethrow;
    }
  } else if (command.name == cmdCreate) {
    try {
      await CreateDirsArgParser.run(command);
    } catch (e) {
      exitCode = 2;
      rethrow;
    }
  } else if (command.name == cmdDependencies) {
    await DependencyFinderArgParser.run(command);
  } else if (command.name == cmdHelp) {
    usage(null); // TODO: use built in help function from ArgParser
  } else {
    usage('Unknown arguments: $restArgs');
  }
}

class BuildArgParser {
  static const optBuildVersion = 'build-version';
  static const optArchitecture = 'arch';

  static ArgParser createParser() {
    return ArgParser()
      ..addOption(optBuildVersion)
      ..addOption(optArchitecture);
  }

  static Future<void> run(ArgResults? argResults) async {
    await FlutterToDebian.runBuild(
        version: argResults?[optBuildVersion],
        arch: argResults?[optArchitecture]);
  }
}

class CreateDirsArgParser {
  static const optBuildVersion = 'build-version';

  static ArgParser createParser() {
    return ArgParser()..addOption(optBuildVersion);
  }

  static Future<void> run(ArgResults argResults) async {
    await FlutterToDebian.runCreate(
      version: argResults[optBuildVersion],
    );
  }
}

class DependencyFinderArgParser {
  static const optExcludedLibs = 'excluded-libraries';
  static const optExcludedPackages = 'excluded-packages';

  static ArgParser createParser() {
    return ArgParser()
      ..addOption(optExcludedLibs)
      ..addOption(optExcludedPackages);
  }

  /// Finds the dependencies of some library files.
  static Future<void> run(ArgResults argResults) async {
    final restArgs = argResults.rest;

    final checker = DependencyFinder();
    await checker.run(
      excludedLibs: argResults[optExcludedLibs],
      excludedPackages: argResults[optExcludedPackages],
      fileArgs: restArgs,
    );
  }
}
