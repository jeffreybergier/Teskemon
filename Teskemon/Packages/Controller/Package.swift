// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let name = "Controller"

let package = Package(
  name: name,
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: name,
      targets: [name]
    ),
  ],
  dependencies: [
    .package(path: "../Model"),
    .package(url: "https://github.com/jeffreybergier/Umbrella.git", branch: "waterme3-wOS10-Swift6"),
  ],
  targets: [
    .target(
      name: name,
      dependencies: [
        .byNameItem(name: "Model", condition: nil),
        .byNameItem(name: "Umbrella", condition: nil),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
