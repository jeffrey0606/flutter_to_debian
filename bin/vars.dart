import 'dart:io';

import 'package:yaml/yaml.dart';

class Vars {
  static Future<void> parseDebianYaml() async {
    File yaml = File("debian/debian.yaml");

    if (!(await yaml.exists())) {
      throw Exception("Couldn't find debian.yaml in dedian/ folder");
    }

    try {
      debianYaml = loadYaml(await yaml.readAsString());
    } catch (e) {
      rethrow;
    }
  }

  static late YamlMap debianYaml;

  static late String pathToIcons;

  static late String pathToAplications;

  static late String pathToFinalAppLocation;

  static late String pathToDedianControl;

  static late String newDebPackageDirPath;
}
