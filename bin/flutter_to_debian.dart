import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_to_debian/dependencies.dart';
import 'package:flutter_to_debian/flutter_to_debian.dart';
import 'package:flutter_to_debian/usage.dart';
import 'package:flutter_to_debian/vars.dart';

const cmdDependencies = 'dependencies';
const cmdHelp = 'help';
const cmdCreate = 'create';
const cmdBuild = 'build';

void main(List<String> arguments) async {
  exitCode = 0;

  final parser = ArgParser()
    ..addCommand(cmdDependencies, DependencyFinder.getArgParser())
    ..addCommand(cmdHelp)
    ..addCommand(cmdCreate, FlutterToDebian.getArgParser())
    ..addCommand(cmdBuild, FlutterToDebian.getArgParser());

  ArgResults argResults = parser.parse(arguments);
  final restArgs = argResults.rest;

  if (argResults.command?.name == cmdDependencies) {
    await dependencies(argResults.command!);
  } else if (argResults.command?.name == cmdHelp) {
    usage(null); // TODO: use built in help function from ArgParser
  } else if (argResults.command == null ||
      argResults.command?.name == cmdBuild ||
      argResults.command?.name == cmdCreate) {
    stdout.write("\nchecking for debian 📦 in root project...");
    try {
      final flutterToDebian = await Vars.parseDebianYaml();

      if (argResults.command != null) {
        // Apply build args
        final buildArgResults = argResults.command!;
        // final buildRestArgs = buildArgResults.rest;
        flutterToDebian.debianControl = flutterToDebian.debianControl.copyWith(
          version: buildArgResults[optBuildVersion],
        );
      }

      stdout.writeln("  ✅\n");
      stdout.writeln("start building debian package... ♻️  ♻️  ♻️\n");
      try {
        final String execPath = await flutterToDebian.build();

        stdout.writeln("🔥🔥🔥 (debian 📦) build done successfully  ✅\n");
        stdout.writeln("😎 find your .deb at\n$execPath");
      } catch (e) {
        exitCode = 2;
        rethrow;
      }
    } catch (e) {
      exitCode = 2;
      rethrow;
    }
  } else {
    usage('Unknown arguments: $restArgs');
  }
}
