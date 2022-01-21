# approle.swift

![platform](https://img.shields.io/badge/platform-macOS-blue)

CLI to associate UTI and Extension to an application.

## Usage

#### Print bundle identifier for an Application Name.

```sh
approle id <Application Name>
```

#### Print UTIs associated to Extensions.

```sh
approle uti <Extension>...
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
com.apple.TextEdit
```

```sh
> approle id Xcode
com.apple.dt.Xcode
```

#### Get UTIs from extensions

```sh
> approle uti sh py rb
public.shell-script # .sh
public.python-script # .py
public.ruby-script # .rb
```

#### Print UTI tree of an object

```sh
> approle tree ./example.txt
public.plain-text
public.text
public.data
public.item
public.content
```

```sh
> approle tree ./example.md
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
Succeeded: com.apple.dt.Xcode -> public.shell-script (.sh)
Succeeded: com.apple.dt.Xcode -> public.python-script
Succeeded: com.apple.dt.Xcode -> public.ruby-script (.rb)
```

#### Read from stdin

```sh
cat << EOF | approle set Xcode -
c h hh m mm
swift
EOF

Succeeded: com.apple.dt.Xcode -> public.c-source (.c)
Succeeded: com.apple.dt.Xcode -> public.c-header (.h)
Succeeded: com.apple.dt.Xcode -> public.c-plus-plus-header (.hh)
Succeeded: com.apple.dt.Xcode -> public.objective-c-source (.m)
Succeeded: com.apple.dt.Xcode -> public.objective-c-plus-plus-source (.mm)
Succeeded: com.apple.dt.Xcode -> public.swift-source (.swift)
```

#### Use UTI tree to set default application

```sh
# It's usually better to skip too generic UTIs.
approle tree ./example.md |
    grep -v -E 'public.(item|folder|directory|data|content)' |
    approle set Xcode -
```
