import 'dart:io';

import 'package:flutter_to_debian/vars.dart';
import 'package:path/path.dart' as path;

class DebianControl {
  final String version;
  final String package;
  final String debArch;
  final String maintainer;
  final String description;
  final String priority;
  final String depends;
  final String essential;

  DebianControl({
    required this.package,
    this.version = '0.0.1',
    this.debArch = 'amd64',
    this.maintainer = '',
    this.description = '',
    this.priority = 'optional',
    this.depends = 'optional',
    this.essential = 'no',
  });

  DebianControl copyWith({
    String? package,
    String? version,
    String? debArch,
    String? maintainer,
    String? description,
    String? priority,
    String? depends,
    String? essential,
  }) {
    return DebianControl(
      package: package ?? this.package,
      version: version ?? this.version,
      debArch: debArch ?? this.debArch,
      maintainer: maintainer ?? this.maintainer,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      depends: depends ?? this.depends,
      essential: essential ?? this.essential,
    );
  }

  Future<void> addDesktopDebianControl() async {
    // print("controls from debian.yaml: $control");
    String newControl = "";
    File controlFile = File(
      path.join(
        Vars.pathToDebianControl,
        "control",
      ),
    );

    newControl += "Version:$version\n";
    newControl += "Package:$package\n";
    newControl += "Architecture:$debArch\n";
    newControl += "Maintainer:$maintainer\n";
    newControl += "Priority:$priority\n";
    newControl += "Description:$description\n";
    newControl += "Depends:$depends\n";
    newControl += "Essential: $essential\n";

    await controlFile.writeAsString(newControl);
  }
}
