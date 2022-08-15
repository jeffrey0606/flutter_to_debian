A simple command-line application to help you easily bundle your flutter app build into a debian package ready for production.

# Overview of our debian packaging 📦

This plugin is a tool that builds **debian** package based on the instructions listed in a **debian.yaml** file. To get a basic understanding and its core concepts, take a look at the [debian documentation](https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html). Additional links and information are listed at the bottom of this page.

# Flutter debian.yaml example

Place the YMAL file in your Flutter project under ****<*project root*>*/debian/debian.yaml***. (And remember the YMAL files are sensitive to white space!) For example:
```yaml
flutter_app: 
  command: mega_cool_app
  arch: x64
  parent: /usr/local/lib

control:
  Package: Mega Cool App
  Version: 1.0.0
  Architecture: amd64
  Essential: no
  Priority: optional
  Depends:
  Maintainer:
  Description: Mega Cool App that does everything!
```
The following sections explain the various pieces of the YAML file.

## Flutter app
This section of the **debain.yaml** file defines the application that will be packaged into a debian.
```yaml
flutter_app: 
  command: mega_cool_app
  arch: x64
  parent: /usr/local/lib
```
#### Command
Points to the binary at your project's linux release bundle, and runs when debian package is invoked.
#### arch
the build architecture of your app.
#### parent
the app will be installed in a subdirectory <command> (like mega_cool_app) in this 
directory.

***default***: /opt


***Example:***

parent: /usr/local/lib

the target directory is: /usr/local/lib/mega_cool_app

## Additional files:
If a directory debian/skeleton exists that files will be copied into the package. 

This can be used for default configuration files.

**Example:**
The file debian/skeleton/etc/megacool/main.conf will be installed as /etc/megacool/main.conf

## Control
This is what describes to the apt package manager or what ever piece of software you are using to install your app what it's all about.
#### Depends
List the libraries your project depends on and they will be installed by the apt package manager before your app in installed on the system.
For example:
<br>
the pub.dev package [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) linux version depends on
```
libsecret-1-0 and libjsoncpp1
```
#### NB: more than one Depends are separated by " , " .

# Desktop file and icon 🖥️
Desktop entry files are used to add an application to the desktop menu. These files specify the name and icon of your application, the categories it belongs to, related search keywords and more. These files have the extension .desktop and follow the XDG Desktop Entry Specification.
## Flutter mega-cool-app.desktop example
Place the .desktop file in your Flutter project under ****<*project root*>*/debian/gui/mega-cool-app.desktop***.<br>

**Notice**: icon and .desktop file name must be the same as your app name in yaml file!<br>

For example:
```
[Desktop Entry]
Version=1.0
Name=Mega Cool App
GenericName=Mega Cool App
Comment=A Mega Cool App that does everything
Terminal=false
Type=Application
Categories=Utility
Keywords=Flutter;share;files;
```
Place your icon with .png extension in your Flutter project under ****<*project root*>*/debian/gui/mega-cool-app.png***.

# Build the debian package 📦
Once the gui/ folder and debian.yaml file are complete. Run **flutter_to_debian** as follows from the root directory of the project.<br>

first build your project<br>
```console
$ flutter build linux
```
install **flutter_to_debian** if not done yet.
```console
$ dart pub global activate flutter_to_debian
```
Run **flutter_to_debian** as follows.
```console
$ flutter_to_debian
```

# Locate and install your .deb app's package 📦
From the root directory of the project, Find it at.
```console
$ cd debian/packages && ls
```
Install
```console
$ sudo dpkg -i [package_name].deb
```

# Dependency Finder
The command flutter_to_debian can be used to find the dependencies of an amount of library files.

Call ```flutter_to_debian help``` to see this description:
```
Usage: flutter_to_debian [<mode> [<options>] ]
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
```
# Contributions 🤝
Please all PR's and found issues are highly welcome at [flutter_to_debian](https://github.com/jeffrey0606/flutter_to_debian)
# Additional resources
You can learn more from the following links:<br>
* [This youtube video](https://www.youtube.com/watch?v=ep88vVfzDAo)
* [Debian documentation](https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html)
* [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)

# Support 🤗
Please download, install, use and share our cross platform Local File sharing app [WhoShares](https://whoshares.hooreo.com/downloads) with your friends 💙 💙 💙.
