import 'dart:io';

import 'functions.dart';
import 'vars.dart';

void main(List<String> arguments) async {
  exitCode = 0;
  //log('Hello world!');

  stdout.write("\nchecking for debian 📦 in root project...");
  try {
    await Vars.parseDebianYaml();
  } catch (e) {
    exitCode = 2;
    rethrow;
  }
  stdout.writeln("  ✅\n");
  stdout.writeln("start building debian package... ♻️  ♻️  ♻️\n");
  try {
    final String execPath = await flutterToDebian(arguments);

    stdout.writeln("🔥🔥🔥 (debian 📦) build done successfully  ✅\n");
    stdout.writeln("😎 find your .deb at\n$execPath");
  } catch (e) {
    exitCode = 2;
    rethrow;
  }
}
