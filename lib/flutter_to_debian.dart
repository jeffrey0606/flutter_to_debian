import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_to_debian/debian_control.dart';
import 'package:flutter_to_debian/vars.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

const optBuildVersion = 'build-version';

class FlutterToDebian {
  String appExecutableName = '';
  String flutterArch = 'x64';
  bool isNonInteractive = false;
  String execFieldCodes = '';
  String base = "opt";
  Directory gui = Directory('debian/gui/');
  DebianControl debianControl = DebianControl(package: '');

  String execOutDirPath = 'build/linux/x64/release/debian';

  static ArgParser getArgParser() {
    return ArgParser()..addOption(optBuildVersion);
  }

  FlutterToDebian.fromPubspec(YamlMap yamlMap) {
    appExecutableName = yamlMap['name'] as String;
    debianControl = debianControl.copyWith(
      package: (yamlMap['name'] as String).replaceAll('_', '-'),
      version: ((yamlMap['version'] ?? '') as String).split('+').first,
      description: yamlMap['description'] as String?,
      maintainer: (yamlMap['authors'] as List<String>?)?[0],
    );
  }

  FlutterToDebian.fromYaml(YamlMap yamlMap) {
    if (yamlMap.containsKey('flutter_app')) {
      appExecutableName = yamlMap["flutter_app"]["command"];
      flutterArch = yamlMap["flutter_app"]["arch"];
      isNonInteractive = yamlMap["flutter_app"]["nonInteractive"] ?? false;
      execFieldCodes = yamlMap["flutter_app"]["execFieldCodes"] ?? "";
      base = yamlMap["flutter_app"].containsKey('parent')
          ? yamlMap["flutter_app"]["parent"]
          : "opt";
      if (base.startsWith('/')) {
        base = base.substring(1);
      }
    }
    if (yamlMap.containsKey('control')) {
      final control = yamlMap["control"];
      debianControl = debianControl.copyWith(
        version: control["Version"],
        package: control["Package"],
        debArch: control["Architecture"],
        maintainer: control["Maintainer"],
        description: control["Description"],
      );
    }
    if (yamlMap.containsKey('options')) {
      execOutDirPath = yamlMap['options']['exec_out_dir'];
    }
  }

  Future<String> build() async {
    final Directory tempDir = Directory(
      path.join(
        Directory.systemTemp.path,
        "flutter_debian",
      ),
    );

    if (!(await tempDir.exists())) {
      await tempDir.create(
        recursive: true,
      );
    }

    final String newPackageName =
        "${debianControl.package}_${debianControl.version}_${debianControl.debArch}";
    final Directory newDebPackageDir = Directory(
      path.join(
        tempDir.path,
        newPackageName,
      ),
    );

    if (await newDebPackageDir.exists()) {
      await newDebPackageDir.delete(
        recursive: true,
      );
    }
    await newDebPackageDir.create(
      recursive: true,
    );

    Vars.newDebPackageDirPath = newDebPackageDir.path;

    // print("new debian package location: ${Vars.newDebPackageDirPath}");

    //Prepare Debian File Structure
    await createFileStructure();

    await addDesktopBuildBundle(
      debianControl.package,
    );

    await addDesktopDataFiles(
      debianControl.package,
    );

    await debianControl.addDesktopDebianControl();
    await addDebianPreInstall();
    await addPackageMaintainerScripts();

    await buildDebianPackage();

    return copyBuildToRootProject(
      tempDir.path,
      newPackageName,
    );
  }

  String getBuildBundlePath() {
    // build/linux/x64/release/bundle
    return path.join("build/linux/", flutterArch, "release/bundle");
  }

  Future<String> copyBuildToRootProject(
    String tempDir,
    String newPackageName,
  ) async {
    Directory finalExecDir = Directory(execOutDirPath);
    if (!(await finalExecDir.exists())) {
      await finalExecDir.create(
        recursive: true,
      );
    }
    return (await File(path.join(
      tempDir,
      newPackageName + ".deb",
    )).copy(
      path.join(
        finalExecDir.path,
        newPackageName + ".deb",
      ),
    ))
        .path;
  }

  Future<void> buildDebianPackage() async {
    final ProcessResult result = await Process.run(
      "dpkg-deb",
      [
        "--build",
        Vars.newDebPackageDirPath,
      ],
    );

    if (result.exitCode == 0) {
      return;
    } else {
      throw Exception(result.stderr.toString());
    }
  }

  Future<void> addPackageMaintainerScripts() async {
    Directory scriptsDir = Directory("debian/scripts");
    if (!await scriptsDir.exists() || await scriptsDir.list().isEmpty) return;

    for (var script in ["preinst", "postinst", "prerm", "postrm"]) {
      final scriptFile = File(path.join("debian/scripts", script));
      if (await scriptFile.exists()) {
        scriptFile.copy(path.join(Vars.pathToDebianControl, script));
      }
    }
  }

  Future<void> addDebianPreInstall() async {
    if (isNonInteractive) {
      // package is intended for automated install, don't add
      // the preinst file asking for confirmation
      return;
    }

    final String preInstScript = '''
#!/bin/bash
echo "\n⚠️  ⚠️  ⚠️  Warning!"
echo "\nThe creator of a debian package has 100% access to every parts of the system it's installed"
echo "\nMaintainer: ${debianControl.maintainer}"
echo "\nDescription: ${debianControl.description}"

echo "\nSure you want to proceed with the installation of this package (yes/no) ?:"
read choice

if [[ "\$choice" != "yes" ]]; then
  #pwd # /home/user/foo
  exit 1
else
  echo "proceeding..."
fi
''';

    File preinstFile = File(
      path.join(
        Vars.pathToDebianControl,
        "preinst",
      ),
    );

    if (!(await preinstFile.exists())) {
      await preinstFile.create();
    }

    await preinstFile.writeAsString(preInstScript);
    final ProcessResult result = await Process.run(
      "sudo",
      [
        "chmod",
        "755",
        preinstFile.path,
      ],
    );

    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString());
    }
  }

  Future<void> addDesktopBuildBundle(String package) async {
    // cp -R <source_folder>/* <destination_folder>

    final ProcessResult result = await Process.run(
      'cp',
      [
        '-R',
        getBuildBundlePath(),
        Vars.pathToFinalAppLocation,
      ],
    );

    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString());
    }

    final ProcessResult result1 = await Process.run(
      "mv",
      [
        path.join(Vars.pathToFinalAppLocation, "bundle"),
        path.join(Vars.pathToFinalAppLocation, package),
      ],
    );

    if (result1.exitCode != 0) {
      throw Exception(result.stderr.toString());
    }

    Directory skeleton = Directory("debian/skeleton");
    if (!await skeleton.exists()) {
      print("No skeleton found");
    } else {
      final ProcessResult result = await Process.run(
        "rsync",
        [
          "-a",
          '${skeleton.absolute.path}/',
          Vars.newDebPackageDirPath,
        ],
      );

      if (result.exitCode != 0) {
        throw Exception(result.stderr.toString());
      }
    }
  }

  String getMimeType(FileSystemEntity entity) {
    final String fileName = path.basename(entity.path);
    return mime(fileName) ?? path.extension(entity.path);
  }

  Future<void> createDesktopDataFiles({bool isOverride = false}) async {
    if (!await gui.exists()) await gui.create(recursive: true);

    final files = gui.listSync();
    final mimeTypes = files.map((file) => getMimeType(file));
    if (isOverride ||
        !mimeTypes.any((element) => element.contains('desktop'))) {
      print("Desktop file missing or overriding, creating...");
      final appName = appExecutableName.replaceAll('_', ' ');
      final contents = """
[Desktop Entry]
Version=${debianControl.version}
Name=$appName
GenericName=$appName
Comment=${debianControl.description}
Terminal=false
Type=Application
Categories=Utility;
Keywords=Flutter;
Icon=${appExecutableName}
""";
      await File(
        path.join(
          gui.path,
          '$appExecutableName.desktop',
        ),
      ).writeAsString(contents);
    }

    if (isOverride || !mimeTypes.any((element) => element.contains('image'))) {
      print("Launcher icon missing or overriding, creating...");
      final defaultLauncherImg =
          'https://storage.googleapis.com/cms-storage-bucket/4fd5520fe28ebf839174.svg';
      final request = await HttpClient().getUrl(Uri.parse(defaultLauncherImg));
      final response = await request.close();
      await response.pipe(File(path.join(
        gui.path,
        '$appExecutableName.svg',
      )).openWrite());
    }
  }

  Future<void> addDesktopDataFiles(String package) async {
    await createDesktopDataFiles();

    late String desktopFileName;
    String desktop = "";
    for (var data in gui.listSync()) {
      final String fileName = path.basename(data.path);
      final mimeType = getMimeType(data);
      // print("file : $fileName | mimeType: $mimeType");
      if (mimeType.contains("image")) {
        if (desktop.isNotEmpty) {
          desktop += "\n";
        }
        final String icon = path.join(
          Vars.pathToIcons,
          fileName,
        );
        desktop += "Icon=${icon.replaceFirst(
          Vars.newDebPackageDirPath,
          "",
        )}";

        await File(data.path).copy(icon);
      } else if (mimeType.contains("desktop")) {
        desktop = await File(data.path).readAsString();
        desktop.trim();

        // Override file from command line options without changing the file
        desktop = desktop.replaceFirst(
            RegExp(r'Version.*\n'), 'Version=${debianControl.version}\n');

        final String execPath = path.join(
          Vars.pathToFinalAppLocation.replaceFirst(
            Vars.newDebPackageDirPath,
            "",
          ),
          package,
          appExecutableName,
        );
        if (!desktop.endsWith("\n")) {
          desktop += "\n";
        }

        final fieldCodes = formatFieldCodes();
        desktop +=
            fieldCodes == "" ? "Exec=$execPath" : "Exec=$execPath $fieldCodes";
        desktop += "\nTryExec=$execPath";
        desktopFileName = fileName;
      }
    }

    await File(
      path.join(
        Vars.pathToApplications,
        desktopFileName,
      ),
    ).writeAsString(desktop);
  }

  String formatFieldCodes() {
    if (execFieldCodes == "") {
      return "";
    }

    var fieldCodes = '';

    final formattedFieldCodes =
        execFieldCodes.trim().replaceAll(' ', '').split(',');

    for (final fieldCode in formattedFieldCodes) {
      if (Vars.allowedExecFieldCodes.contains(fieldCode)) {
        fieldCodes += '%$fieldCode ';
      } else {
        throw Exception("Field code %$fieldCode is not allowed");
      }
    }

    return fieldCodes;
  }

  Future<void> createFileStructure() async {
    ///Create Path to your app's desktop configs. they will
    ///point to this location /usr/share/ after installation
    final List<String> pathsToShare = ["usr", "share"];
    String sharePath = await createFolders(
      pathsToShare,
      Vars.newDebPackageDirPath,
    );

    ///Create applications and icons Folder
    Vars.pathToApplications = (await createAFolder(
      path.join(
        sharePath,
        "applications",
      ),
    ));
    Vars.pathToIcons = (await createAFolder(
      path.join(
        sharePath,
        "icons",
      ),
    ));

    ///Create Path to app build bundle for debian. this means your app will be
    ///point to this location /opt/[package] after installation
    final List<String> pathsToApp = [base];

    Vars.pathToFinalAppLocation = await createFolders(
      pathsToApp,
      Vars.newDebPackageDirPath,
    );

    ///Create path to the debian control file
    Vars.pathToDebianControl = (await createAFolder(
      path.join(
        Vars.newDebPackageDirPath,
        "DEBIAN",
      ),
    ));
  }

  Future<String> createFolders(List<String> paths, String root) async {
    String currentPath = root;

    for (var to in paths) {
      Directory directory = Directory(
        path.join(currentPath, to),
      );
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
      currentPath = directory.path;
    }

    return currentPath;
  }

  Future<String> createAFolder(String pathTo) async {
    Directory directory = Directory(
      pathTo,
    );
    if (!(await directory.exists())) {
      await directory.create();
    }

    return directory.path;
  }
}
