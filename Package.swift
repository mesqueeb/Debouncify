// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Debouncify",
  products: [.library(name: "Debouncify", targets: ["Debouncify"])],
  targets: [
    .target(name: "Debouncify", swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]),
    .testTarget(name: "DebouncifyTests", dependencies: ["Debouncify"]),
  ]
)
