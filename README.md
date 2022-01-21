# approle.swift

![platform](https://img.shields.io/badge/platform-macOS-blue)

CLI to associate UTI and Extension to an application.

## Usage

```sh
NAME
    approle -- Set default applications for UTI / Extension.

USAGE
    approle id <Application Name>
    approle uti <Extension>...
    approle tree <Object Path>
    approle set <(Application Name | Bundle Identifier)> <(UTI | Extension)>...
    approle set <(Application Name | Bundle Identifier)> -
    approle help

COMMANDS
    id   <Application Name>
             Print bundle identifier for an Application Name.

    uti  <Extension>...
             Print UTIs associated to Extensions.

    tree <Object Path>
             Print UTI tree of Object Path.

             • This operation is dependant on Spotlight metadata database and
                 not always accurate, may return different results than 'approle uti'.

    set  <(Application Name | Bundle Identifier)> <(UTI | Extension)>...
             Set an identifier to UTIs / Extensions as default role handler (All Roles).

             • It's allowed to mix UTIs and Extensions.
             • Application Name will be conveted to bundle ID internally, same as 'approle id'.
             • Extensions will be conveted to UTIs internally, same as 'approle uti'.
             • The last parameter will be read from stdin if "-" is specified.
             • It's recommended to use UTI only if an operation has to be
                 UTI specific – some extensions have multiple UTIs associated.

    help
             Show this help.

EXAMPLES
    Get BundleIdentifier of an Application
        $ approle id TextEdit
        $ approle id Xcode

    Get UTIs from extensions
        $ approle uti sh
        $ approle uti sh py rb

    Print UTI tree of an object
        $ approle tree ./example.txt
        $ approle tree ./example.md

    Set default application for UTI / Extension
        $ approle set "com.apple.TextEdit" sh
        $ approle set "com.apple.TextEdit" sh public.python-script
        $ approle set "com.apple.TextEdit" sh public.python-script rb

    Read from stdin
        cat << EOF | approle set Xcode -
        c h hh m mm
        swift
        EOF

    Use UTI tree to set default application
        $ filetypes=$(approle tree ./example.md | grep -v -E 'public.(item|folder|directory|data|content)')
        $ approle set "com.apple.TextEdit" $filetypes

        • It's usually better to skip too generic UTIs.

```
