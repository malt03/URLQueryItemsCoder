// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "URLQueryItemsCoder",
    products: [
        .library(name: "URLQueryItemsCoder", targets: ["URLQueryItemsCoder"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "URLQueryItemsCoder", dependencies: []),
        .testTarget(name: "URLQueryItemsCoderTests", dependencies: ["URLQueryItemsCoder"]),
    ]
)
