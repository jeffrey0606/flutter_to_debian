A simple command-line application to help you easily bundle your flutter app build into a debian package ready for production.

# Overview of our debian packaging 📦

This plugin is a tool that builds **debian** package based on the instructions listed in a **debian.yaml** file. To get a basic understanding and its core concepts, take a look at the [debian documentation](https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html). Additional links and information are listed at the bottom of this page.

# Flutter debian.yaml example

Place the YMAL file in your Flutter project under ****<*project root*>*/debian/debian.yaml***. (And remember the YMAL files are sensitive to white space!) For example:
```yaml
flutter_app: 
  command: mega_cool_app
  arch: x64

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
```
#### Command
Points to the binary at your project's linux release bundle, and runs when snap is invoked.
#### arch
the build architecture of your app.

## Control
This is what describes to the apt package manager or what ever piece of software you are using to install your app what it's all about.

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

# Contributions 🤝
Please all PR's and found issues are highly welcome at [flutter_to_debian](https://github.com/jeffrey0606/flutter_to_debian)
# Additional resources
You can learn more from the following links:<br>
* [This youtube video](https://www.youtube.com/watch?v=ep88vVfzDAo)
* [Debian documentation](https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html)
* [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)

# Support 🤗
Please download, install, use and share our cross platform Local File sharing app [WhoShares](https://whoshares.hooreo.com/downloads) with your friends 💙 💙 💙.