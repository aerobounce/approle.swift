# approle.swift

[![][bagde-swift-versions]][swiftpackageindex]
[![][bagde-platforms]][swiftpackageindex]
[![][bagde-tag]][tags]

CLI to associate UTI and Extension to an application.\
Stand alone executable Swift program.

## Install

```sh
brew install aerobounce/tap/approle
```

## Usage

#### Print bundle identifier for an Application Name.

```sh
approle id <Application Name>
```

#### Print UTIs associated to Extensions.

```sh
approle uti <Extension>...
```

#### Print filtered list of UTIs declared in system.

```sh
approle list [Conforming UTI...] [!Non-Conforming UTI...]
```

#### Print UTI tree of Object Path.

```sh
approle tree <Object Path>
```

#### Set an identifier to UTIs / Extensions as default role handler (All Roles).

```sh
approle set <(Application Name | Bundle Identifier)> <(UTI | Extension)>...
```

#### Show help.

```sh
approle help
```

## Examples

#### Get BundleIdentifier of an Application

```sh
> approle id TextEdit
```

```sh
com.apple.TextEdit
```

```sh
> approle id Xcode
```

```sh
com.apple.dt.Xcode
```

#### Get UTIs from extensions

```sh
> approle uti sh py rb
```

```sh
public.shell-script # .sh
public.python-script # .py
public.ruby-script # .rb
```

#### List all UTIs matching

```sh
# List all UTIs which conform to `public.archive` excluding UTIs conform to `public.disk-image`.
> approle list "public.archive" "!public.disk-image"
```

```sh
com.winzip.zipx-archive
org.tukaani.lzma-archive
public.lzip-archive
public.lzip-tar-archive
public.lzop-archive
public.lzop-tar-archive
public.lrzip-archive
public.lrzip-tar-archive
...
```

#### Print UTI tree of an object

```sh
> approle tree ./example.txt
```

```sh
public.plain-text
public.text
public.data
public.item
public.content
```

```sh
> approle tree ./example.md
```

```sh
net.daringfireball.markdown
public.plain-text
public.text
public.data
public.item
public.content
```

#### Set default application for UTI / Extension

```sh
> approle set Xcode sh public.python-script rb
```

```sh
Succeeded: com.apple.dt.Xcode -> public.shell-script (.sh)
Succeeded: com.apple.dt.Xcode -> public.python-script
Succeeded: com.apple.dt.Xcode -> public.ruby-script (.rb)
```

#### Read from stdin

```sh
approle set Xcode << EOF
c h hh m mm
swift
EOF
```

```sh
Succeeded: com.apple.dt.Xcode -> public.c-source (.c)
Succeeded: com.apple.dt.Xcode -> public.c-header (.h)
Succeeded: com.apple.dt.Xcode -> public.c-plus-plus-header (.hh)
Succeeded: com.apple.dt.Xcode -> public.objective-c-source (.m)
Succeeded: com.apple.dt.Xcode -> public.objective-c-plus-plus-source (.mm)
Succeeded: com.apple.dt.Xcode -> public.swift-source (.swift)
```

#### Use UTI list to set default application

```sh
# Set Xcode as default application for all the UTIs conform to `public.source-code`.
approle list "public.source-code" | approle set Xcode
```

#### Use UTI tree to set default application

```sh
# Better to skip too generic UTIs.
approle tree ./example.md |
    grep -v -E 'public.(item|folder|directory|data|content)' |
    approle set Xcode
```


[tags]: https://github.com/aerobounce/approle.swift/tags
[swiftpackageindex]: https://swiftpackageindex.com/aerobounce/approle.swift

[bagde-swift-versions]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faerobounce%2Fapprole.swift%2Fbadge%3Ftype%3Dswift-versions
[bagde-platforms]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faerobounce%2Fapprole.swift%2Fbadge%3Ftype%3Dplatforms
[bagde-tag]: https://img.shields.io/github/v/tag/aerobounce/approle.swift?display_name=tag
