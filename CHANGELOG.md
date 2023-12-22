## 2.0.2

- DOCS: Rework Changelog
- TEST: Add test environment

## 2.0.1

- DEPS: Support Dart SDK 3.x.x
- REFACTOR: Support using as direct dependency (#26)

## 2.0.0

- BREAKING REFACTOR: Rework package (#21)
  - Read properties from `pubspec.yaml`
  - `flutter_to_debian create` becomes `flutter_to_debian build`
  - `flutter_to_debian create` only creates the `debian` folder and files
  - Option `--build-version` for `flutter_to_debian create` and `flutter_to_debian build`
  - Refactor command line arguments to use `ArgParser`
  - Adapt common folder structure and naming conventions
- FEAT: Option to change the output path via `exec_out_dir` (#19)

## 1.0.4

- the command understands now modes:
  - **help**: prints an usage message
  - **create** : creates the Debian package
  - **dependencies**: finds dependencies of library files
- adapted README

## 1.0.3

- the parent directory is now configurable (instead of /opt)
- the files in debian/skeleton will be copied: used for configuration files, documentation...

## 1.0.2+1

- add clarity about the Depends attribute in the debian.yaml file

## 1.0.2

- Fixed readme

## 1.0.1

- Improved the package with some changes to increase it readability

## 1.0.0

- Initial version.









