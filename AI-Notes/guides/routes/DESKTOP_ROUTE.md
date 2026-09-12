# The desktop route: for a person following directions

This route assumes nothing beyond a computer running Ubuntu or Debian and the ability to download a file and double-click it. Every step has a screen that says what to do next.

## 1. Get the installer

Download `polari-complete` from the Download page of any Polari server, or from the [releases](https://github.com/dausume/polari-suite/releases) page. It is one file. Its checksum is published next to it.

## 2. Install it

Double-click the file, or in a terminal:

```
sudo apt install ./polari-complete_<version>_amd64.deb
```

The all-in-one package installs the `isle` command, the App Store, the native app shells and the Polari isle package. On a machine with the internet it fetches the container images from the public registry. On a machine without, use the offline flavor, which carries them.

## 3. Open the App Store

The App Store is a normal desktop application. It lists the apps and modules that are available, shows which are installed, and installs or removes one with a click. Underneath it uses the same admission path as everything else, so what the store installs is what the console would install.

## 4. Follow the screens

The first run asks the few things a person has to decide: whether this computer joins an isle or stands alone, and which apps to start with. Everything technical is chosen for you and can be changed later from the Settings app.

## What happens when something goes wrong

Every screen that fails says why, in words, and what to do. The `isle` command's `status` verb prints the same in a terminal. Nothing is ever half-installed: an app that fails to admit is put away again.

## What is still being finished

The desktop route's screens are the App Store and the shells; the guided first-run screens described above are the same Textual guide the server route uses, adapted for a desktop, and that adaptation is in progress. The installer, the store and the admission path are real today.
