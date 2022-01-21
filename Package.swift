// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let productName: String = "approle"
let package: Package = .init(
    name: productName,
    platforms: [.macOS(.v10_15)],
    products: [.executable(name: productName, targets: [productName])],
    targets: [.executableTarget(name: productName)],
    swiftLanguageVersions: [.v5]
)
