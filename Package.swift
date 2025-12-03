// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SRDoubleStickyHeaderList",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SRDoubleStickyHeaderList",
            targets: ["SRDoubleStickyHeaderList"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/siteline/swiftui-introspect", from: "26.0.0"),
    ],
    targets: [
        .target(
            name: "SRDoubleStickyHeaderList",
            dependencies: [
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
            ]
        ),
    ]
)
