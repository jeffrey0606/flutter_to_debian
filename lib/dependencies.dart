import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

const optExcludedLibs = 'excluded-libraries';
const optExcludedPackages = 'excluded-libraries';

/// Finds the dependencies of some library files.
Future<bool> dependencies(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(optExcludedLibs)
    ..addOption(optExcludedPackages);

  ArgResults argResults = parser.parse(arguments);
  final restArgs = argResults.rest;

  bool rc = false;
  final checker = DependencyFinder();
  if (await checker.prepare(
    excludedLibs: argResults[optExcludedLibs],
    excludedPackages: argResults[optExcludedPackages],
  )) {
    final files = await checker.findFiles(restArgs);
    rc = await checker.detect(files);
  }
  return rc;
}

/// A manager for detecting library dependencies in a Debian environment.
class DependencyFinder {
  final libDirectory = './build/linux/x64/release/bundle/lib';
  final dependencyOptions = ['excluded-libraries', 'excluded-packages'];
  String preferredArchitecture = 'amd64';
  final libFiles = <String>{};
  RegExp? excludedArchitecture;
  RegExp? excludedLibs;
  List<String> excludedPackages = [];

  /// Detects the dependencies of a list of [files].
  Future<bool> detect(List<String> files) async {
    var rc = false;
    log('Inspecting ${files.length} file(s): be patient');
    for (var file in files) {
      await getDependencies(file);
    }
    await findPackages();
    return rc;
  }

  /// Logs an error [message].
  void error(String message) {
    print('+++ $message');
  }

  /// Executes an external command and returns the output lines.
  ///
  /// [command] the external command, e.g. "apt-get"
  /// [arguments] the program arguments, e.g. ['show', 'my-package']
  Future<List<String>> executeResult(
      String command, List<String> arguments) async {
    var rc = <String>[];
    var result = await Process.run(command, arguments);
    final data = result.stdout;
    if (data is String) {
      rc = data.split('\n');
    } else {
      rc = data;
    }
    return rc;
  }

  /// Detects the list of library files to inspect from the program [arguments].
  Future<List<String>> findFiles(List<String> arguments) async {
    final rc = <String>[];
    if (arguments.isEmpty) {
      arguments = [libDirectory];
    }
    for (var arg in arguments) {
      if (await FileSystemEntity.isDirectory(arg)) {
        final directory = Directory(arg);
        if (await directory.exists()) {
          final files = await directory.list().toList();
          for (var file in files) {
            if (file.path.endsWith('.so')) {
              rc.add(file.path);
            }
          }
        }
      } else if (await FileSystemEntity.isFile(arg)) {
        final file = File(arg);
        if (arg.endsWith('.so') && await file.exists()) {
          rc.add(arg);
        }
      }
    }
    return rc;
  }

  /// Finds the packages referred from the files in [libFiles].
  Future<void> findPackages() async {
    final packages = <String>{};
    RegExp regExp = RegExp(r'^([^:]+(:([^:]+))?):\s');
    for (var file in libFiles) {
      final lines = await executeResult('dpkg', ['-S', file]);
      final packages2 = <String, String>{};
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          final matcher = regExp.firstMatch(line);
          if (matcher != null) {
            packages2[matcher.group(1)!] = matcher.group(3) ?? '';
          }
        }
      }
      final keys = packages2.keys.toList();
      String? toAdd;
      switch (keys.length) {
        case 0:
          break;
        case 1:
          toAdd = keys[0];
          break;
        case 2:
        case 3:
          if (packages2[keys[0]] == preferredArchitecture) {
            toAdd = keys[0];
          } else if (packages2[keys[1]] == preferredArchitecture) {
            toAdd = keys[1];
          } else {
            toAdd = keys.join('|');
          }
          break;
        default:
          error('too many alternatives: ${keys.join("|")}');
          break;
      }
      if (toAdd != null) {
        packages.add(toAdd);
      }
    }
    if (packages.isEmpty) {
      log('No dependencies found');
    } else {
      final packages3 = await reduceDoubles(packages);
      final sorted = packages3.toList();
      sorted.sort();
      log('Dependencies: ${sorted.length}');
      for (var package in sorted) {
        log(package.replaceFirst(':$preferredArchitecture', ''));
      }
    }
  }

  /// Detects the packages of the library file [libFile].
  ///
  /// The found packages will be stored in [libFiles].
  Future<void> getDependencies(String libFile) async {
    final lines = await executeResult('ldd', [libFile]);
    RegExp regExp = RegExp(r'^\s+(\S+)');
    int ix = 1;
    for (var line in lines) {
      if (!line.contains('statically linked')) {
        final matcher = regExp.firstMatch(line);
        if (matcher != null) {
          final package = matcher.group(1)!;
          libFiles.add(package);
        }
      }
      if (++ix % 10 == 0 && ix > 1) {
        log('${ix} of ${lines.length} lines processed...');
      }
    }
  }

  /// Logs a [message].
  void log(String message) {
    print(message);
  }

  /// Fetches the needed info of the yaml file and the program [arguments].
  ///
  /// Returns false on error.
  Future<bool> prepare({
    String? excludedLibs,
    String? excludedPackages,
  }) async {
    bool rc = true;
    File yaml = File("debian/debian.yaml");

    if (await yaml.exists()) {
      try {
        final debianYaml = loadYaml(await yaml.readAsString());
        if (debianYaml.containsKey('control')) {
          if (debianYaml['control'].containsKey('Architecture')) {
            preferredArchitecture = debianYaml['control']['Architecture'];
          }
          if (debianYaml['control'].containsKey('Package')) {
            this.excludedPackages.add(debianYaml['control']['Package']);
          }
        }
        if (preferredArchitecture != 'amd64') {
          excludedArchitecture = RegExp(r'-i386$');
        }
      } catch (e) {
        rethrow;
      }
    }
    if (excludedLibs != null) this.excludedLibs = RegExp(excludedLibs);
    if (excludedPackages != null)
      this.excludedPackages = excludedPackages.split(',');
    return rc;
  }

  /// Reduces the amount of dependencies:
  /// If a packages A is part of the dependencies of another package B
  /// it is enough to remember B.
  Future<List<String>> reduceDoubles(Iterable<String> packages) async {
    final rc = packages.map((e) => e.split(':')[0]).toList();
    for (var package in excludedPackages) {
      rc.remove(package);
    }
    log('Packages: ${rc.length}');
    final count = rc.length;
    int ix = 0;
    for (var package in packages) {
      if (!excludedPackages.contains(package.split(':')[0])) {
        final lines = await executeResult('apt-cache', ['show', package]);
        for (var line in lines) {
          if (line.startsWith('Depends:')) {
            final items = line.substring(8).trim().split(',');
            for (var item in items) {
              final name2 = item.trim().split(' ')[0];
              rc.remove(name2);
            }
            break;
          }
        }
      }
      if (++ix % 10 == 0) {
        log('$ix of ${packages.length} packages processed...');
      }
    }
    final count2 = rc.length;
    if (count2 < count) {
      log('Packages reduced from $count to $count2');
    }
    return rc;
  }
}
