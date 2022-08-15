/// Writes a usage notice.
///
/// [message] is an error message.
void usage(String? message){
  print('''Usage: flutter_to_debian [<mode> [<options>] ]
<mode>:
  help
    Print this usage.
  create-deb
    Creates a Debian package file *.deb. This is the default mode.
  dependencies [<opts>] [<file1> [ <file2>...]]
    Detects the dependencies of a amount of library files.
    <fileX> can be a file or a directory.
<opts>:
   --excluded-packages=<comma-separated-list-of-names>
     That packages will be excluded from detection
   --excluded-libraries=<pattern>
     Excludes that library files from detection. <pattern> is a regular expr.
Examples:
flutter_to_debian
  Creates the Debian package described in ./debian/debian.yaml
flutter_to_debian dependencies
  Detects the dependencies of the files in ./build/linux/x64/release/bundle/lib
  and uses the information of debian/debian.yaml
flutter_to_debian dependencies --excl-lib=-dev|^my_lib release/libs
  Detects the dependencies of the files in release/libs without the excluded
  specified by "-dev|^my_lib":
  The file release/libs/our_lib-dev.2.so and release/libs/my_lib-dev.2.so
  will be excluded from detection.
flutter_to_debian dependencies --excluded-packages=lintian,my-project prod/libs
  Detects the dependencies of the files in prod/libs
  The packages lintian and my-project will be excluded from processing.
Note: modes and options can be abbreviated: --ex-pack means --excluded-packages
''');
  if (message != null){
    print('+++ $message');
  }
}
