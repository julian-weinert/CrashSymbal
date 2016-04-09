# CrashSymbal
An Xcode plugin for manually symbolicating crash logs

## Install

1. Build the project to install the plugin. The plugin gets installed in `/Library/Application Support/Developer/Shared/Xcode/Plug-ins/CrashSymbal.xcplugin`.
2. Restart Xcode for the plugin to be activated.

**Alternatively, install it using [Alcatraz plugin manager](https://github.com/supermarin/Alcatraz).**


## Usage

Once installed and Xcode relaunched, the `Debug` menu will contain a new menu item labled "Symbolicate Crashlog...".
It will open a dialog that allows you to select or drop a crashlog and smbolicate it. After the process you can export the symbolicated crash to your disk.


## Screenshot

![LinkedLog](https://raw.githubusercontent.com/julian-weinert/CrashSymbal/master/Screenshots/CrashSymbal.png)


## Bugs and limitations

...


## Contribution

If you want to contribute, feel free to send me pull requests! But lease follow these simple rules:

- Double-check your code before sending a pull request
- Pull requests should always be made agains `develop`
- Always use tab-indentation!
- Indent properly!
