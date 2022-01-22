#!/usr/bin/env swift
//
// approle.swift
//
// AGPLv3 License
// Created by github.com/aerobounce on 2022/1/15.
// Copyright © 2022-present aerobounce. All rights reserved.
//

/*** Some Researches ***
 *
 * • New: macOS 12.0+ (AppKit - Unreliable. Not clear when changes will be in effect, not immediately at least.)
 *     NSWorkspace.shared.setDefaultApplication(at: URL, toOpen: UTType, completion: ((Error?) -> Void)?)
 *
 * • New: macOS 11.0+ (UniformTypeIdentifiers - Swifter UTType reimplementations at higher level.)
 *     UTType.types(tag: "FileExt", tagClass: .filenameExtension, conformingTo: nil).map(\.identifier)
 *         (Equivalent call to 'UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, "FileExt", nil)')
 *
 * • Deprecated: macOS 10.3–12.0 (CoreServices - Reliable.)
 *     LSSetDefaultRoleHandlerForContentType(:::)
 *     UTTypeCreateAllIdentifiersForTag(:::)
 *
 * • Notes:
 *     • UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, _, _)
 *       CFURLCopyResourcePropertyForKey(_, kCFURLTypeIdentifierKey, _, _)
 *         Methods return different dynamic association.
 *
 *     • MDItemCopyAttribute(_, kMDItemContentTypeTree) (== '$ mdls -name kMDItemContentTypeTree')
 *         is dependant to Spotlight metadata database, and not always accurate.
 *           1. It doesn't create dynamic association (data will be empty / nil).
 *           2. It can return infomation associated with removed application.
 *
 */

import CoreServices
import Foundation

///
/// MARK: Helpers
///
let isTERM: Bool = ProcessInfo.processInfo.environment["TERM"] != nil
let e: String = isTERM ? "\u{001B}[1;31m" : "" // Red Bold (for Error)
let g: String = isTERM ? "\u{001B}[0;32m" : "" // Green
let o: String = isTERM ? "\u{001B}[0;33m" : "" // Orange
let p: String = isTERM ? "\u{001B}[1;35m" : "" // Purple Bold
let c: String = isTERM ? "\u{001B}[4;36m" : "" // Cyan Underlined
let b: String = isTERM ? "\u{001B}[1m" : "" // Bold
let r: String = isTERM ? "\u{001B}[0m" : "" // Reset

func stdout(_ message: String) { fputs("\(message)\n", stdout) }
func stderr(_ message: String) { fputs("\(e)\(message)\(r)\n", stderr) }
func advise(_ message: String) -> Never { stderr(message); exit(EXIT_FAILURE) }

func asBundleIdentifier(_ applicationName: String) -> String {
    if let script: NSAppleScript = .init(source: #"id of app "\#(applicationName)""#),
       let bundleIdentifier: String = script.executeAndReturnError(nil).stringValue {
        return bundleIdentifier
    }
    return ""
}

///
/// MARK: Wrappers
///
struct UniformType {
    let filenameExtension: String
    let identifiers: [String]

    init(filenameExtension: String) {
        self.filenameExtension = filenameExtension
        self.identifiers = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension,
                                                            filenameExtension as CFString,
                                                            nil)?.takeUnretainedValue() as? [String] ?? []
    }

    init(identifiers: [String]) {
        self.filenameExtension = "" // Not in use
        self.identifiers = identifiers
    }
}

enum Command: String {
    case printBundleIdentifier = "id"
    case printUTIs = "uti"
    case printTypeTree = "tree"
    case setDefaultRoleHandler = "set"
    case printHelp = "help"
}

extension Command {
    private static func printBundleIdentifier(_ bundleIdentifier: String) {
        stdout(bundleIdentifier)
    }

    private static func printUTIs(_ uniformTypes: [UniformType]) {
        for uniformType in uniformTypes {
            for identifier in uniformType.identifiers {
                stdout("\(identifier) # .\(uniformType.filenameExtension)")
            }
        }
    }

    private static func printTypeTree(of fileURL: URL) {
        var error: Unmanaged<CFError>?
        _ = CFURLResourceIsReachable(fileURL as CFURL, &error)

        if case let error as Error = error?.takeUnretainedValue() {
            advise(error.localizedDescription)
        }
        guard let item: MDItem = MDItemCreateWithURL(nil, fileURL as CFURL),
              case let typeTree as [String] = MDItemCopyAttribute(item, kMDItemContentTypeTree) else {
            advise("Failed to obtain infomation from database.")
        }
        for identifier in typeTree {
            stdout(identifier)
        }
    }

    private static func setDefaultRoleHandler(to bundleIdentifier: String, _ uniformTypes: [UniformType]) {
        func asString(_ code: OSStatus) -> String {
            let errorCode: String = " (\(code))"
            /// Some too old codes are no longer in use since macOS 12.
            /// https://developer.apple.com/documentation/coreservices/launch_services
            switch code {
            case kLSAppInTrashErr: return "kLSAppInTrashErr" + errorCode
            case kLSUnknownErr: return "kLSUnknownErr" + errorCode
            case kLSNotAnApplicationErr: return "kLSNotAnApplicationErr" + errorCode
            case kLSDataUnavailableErr: return "kLSDataUnavailableErr" + errorCode
            case kLSApplicationNotFoundErr: return "kLSApplicationNotFoundErr" + errorCode
            case kLSDataErr: return "kLSDataErr" + errorCode
            case kLSLaunchInProgressErr: return "kLSLaunchInProgressErr" + errorCode
            case kLSServerCommunicationErr: return "kLSServerCommunicationErr" + errorCode
            case kLSCannotSetInfoErr: return "kLSCannotSetInfoErr" + errorCode
            case kLSIncompatibleSystemVersionErr: return "kLSIncompatibleSystemVersionErr" + errorCode
            case kLSNoLaunchPermissionErr: return "kLSNoLaunchPermissionErr" + errorCode
            case kLSNoExecutableErr: return "kLSNoExecutableErr" + errorCode
            case kLSMultipleSessionsNotSupportedErr: return "kLSMultipleSessionsNotSupportedErr" + errorCode
            default: return code == 0 ? "Succeeded" : "Error" + errorCode
            }
        }
        for uniformType in uniformTypes {
            for identifier in uniformType.identifiers {
                let status: OSStatus = LSSetDefaultRoleHandlerForContentType(identifier as CFString, .all, bundleIdentifier as CFString)
                let didSucceed: Bool = status == 0
                let message: String = {
                    let color: String = didSucceed ? g : e
                    var buffer: String = "\(color)\(asString(status))\(r): \(o)\(bundleIdentifier)\(r) -> \(o)\(identifier)\(r)"
                    if !uniformType.filenameExtension.isEmpty {
                        buffer += " (.\(uniformType.filenameExtension))"
                    }
                    return buffer
                }()
                didSucceed ? stdout(message) : stderr(message)
            }
        }
    }

    private static func printHelp() {
        stdout("""
        \(p)NAME\(r)
            \(p)approle\(r) -- Set default applications for UTI / Extension.

        \(p)USAGE\(r)
            \(p)approle id\(r) <\(c)Application Name\(r)>
            \(p)approle uti\(r) <\(c)Extension\(r)>...
            \(p)approle tree\(r) <\(c)Object Path\(r)>
            \(p)approle set\(r) <(\(c)Application Name\(r) | \(c)Bundle Identifier\(r))> <(\(c)UTI\(r) | \(c)Extension\(r))>...
            \(p)approle set\(r) <(\(c)Application Name\(r) | \(c)Bundle Identifier\(r))> -
            \(p)approle help\(r)

        \(p)COMMANDS\(r)
            \(p)id\(r)   <\(c)Application Name\(r)>
                     Print bundle identifier for an Application Name.

            \(p)uti\(r)  <\(c)Extension\(r)>...
                     Print UTIs associated to Extensions.

            \(p)tree\(r) <\(c)Object Path\(r)>
                     Print UTI tree of Object Path.

                     - This operation is dependant on Spotlight metadata database and
                       not always accurate, may return different results than 'approle uti'.

            \(p)set\(r)  <(\(c)Application Name\(r) | \(c)Bundle Identifier\(r))> <(\(c)UTI\(r) | \(c)Extension\(r))>...
                     Set an identifier to UTIs / Extensions as default role handler (All Roles).

                     - It's allowed to mix UTIs and Extensions.
                     - Application Name will be conveted to bundle ID internally, same as 'approle id'.
                     - Extensions will be conveted to UTIs internally, same as 'approle uti'.
                     - The last parameter will be read from stdin if "-" is specified.
                     - It's recommended to use UTI only if an operation has to be UTI specific,
                       as some extensions have multiple UTIs associated.

            \(p)help\(r)
                     Show this help.

        \(p)EXAMPLES\(r)
            \(p)Get BundleIdentifier of an Application\(r)
                \(g)approle id TextEdit\(r)
                \(g)approle id Xcode\(r)

            \(p)Get UTIs from extensions\(r)
                \(g)approle uti sh\(r)
                \(g)approle uti sh py rb\(r)

            \(p)Print UTI tree of an object\(r)
                \(g)approle tree ./example.txt\(r)
                \(g)approle tree ./example.md\(r)

            \(p)Set default application for UTI / Extension\(r)
                \(g)approle set "com.apple.TextEdit" sh\(r)
                \(g)approle set "com.apple.TextEdit" sh public.python-script\(r)
                \(g)approle set "com.apple.TextEdit" sh public.python-script rb\(r)

            \(p)Read from stdin\(r)
                cat << EOF | approle set Xcode -
                c h hh m mm
                swift
                EOF

            \(p)Use UTI tree to set default application\(r)
                \(g)filetypes=$(approle tree ./example.md | grep -v -E 'public.(item|folder|directory|data|content)')\(r)
                \(g)approle set "com.apple.TextEdit" $filetypes\(r)

                - It's usually better to skip too generic UTIs.
        """)
    }
}

extension Command {
    static func execute() {
        var arguments: [String] = CommandLine.arguments.dropFirst().map { $0 }
        let useStdin: Bool = arguments.last == "-"
        let usage: String = r + " 'approle help' for usage."

        if arguments.isEmpty {
            advise("Specify a command." + usage)
        }
        guard let command: Command = .init(rawValue: arguments[0]) else {
            advise("Specify a valid command." + usage)
        }
        arguments = arguments.dropFirst().map { $0 } // Consumed by 'Command.init'

        if arguments.isEmpty, command != .printHelp {
            advise("Invalid form of command." + usage)
        }

        switch command {
        case .printBundleIdentifier:
            let applicationName: String = arguments[0]
            let bundleIdentifier: String = asBundleIdentifier(applicationName)

            if bundleIdentifier.isEmpty {
                advise(#"Application "\#(applicationName)" does not exist."#)
            }
            Self.printBundleIdentifier(bundleIdentifier)

        case .printUTIs:
            Self.printUTIs(arguments.compactMap(UniformType.init(filenameExtension:)))

        case .printTypeTree:
            Self.printTypeTree(of: .init(fileURLWithPath: arguments[0]))

        case .setDefaultRoleHandler:
            if !useStdin, arguments.count < 2 {
                advise("Invalid form of command.")
            }

            func parseSTDIN() -> [String] {
                var components: [String] = []
                while let line: String = readLine() {
                    components += line
                        .components(separatedBy: " ")
                        .filter { !$0.isEmpty && $0 != " " }
                }
                if components.isEmpty {
                    advise("Failed to read stdin.")
                }
                return components
            }

            let appNameOrID: String = arguments[0]
            let possibleBundleID: String = asBundleIdentifier(appNameOrID)
            arguments = arguments.dropFirst().map { $0 } // Consumed by 'appNameOrID'
            let components: [String] = useStdin ? parseSTDIN() : arguments

            let bundleIdentifier: String = possibleBundleID.isEmpty ? appNameOrID : possibleBundleID
            let uniformTypes: [UniformType] = components.reduce(into: [UniformType]()) { (utis: inout [UniformType], component: String) in
                if case .some = component.range(of: ".") {
                    // UTI (UTIs should have '.')
                    utis.append(.init(identifiers: [component]))
                } else {
                    // Extensions does not have '.'
                    utis.append(.init(filenameExtension: component))
                }
            }

            Self.setDefaultRoleHandler(to: bundleIdentifier, uniformTypes)

        case .printHelp:
            Self.printHelp()
        }
    }
}

///
/// MARK: Main
///
Command.execute()
