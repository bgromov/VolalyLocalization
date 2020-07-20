// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VolalyLocalization",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "VolalyLocalization",
            type: .dynamic,
            targets: ["CRelloc"])
    ],
    dependencies: [
        .package(url: "https://github.com/bgromov/TransformSwift", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "VolalyLocalization",
            dependencies: ["CRelloc", .product(name: "Transform", package: "TransformSwift")]
        ),
        .target(
            name: "CRelloc",
            cxxSettings: [
                .unsafeFlags(["-std=c++17", "-stdlib=libc++", "-ILibraries/dlib/include"]),
            ],
            linkerSettings: [
                .linkedLibrary("dlib"),
                .linkedFramework("Accelerate", .when(platforms: [.iOS, .macOS])),
                .unsafeFlags(["-LLibraries/dlib/lib/arm64"], .when(platforms: [.iOS])),
                .unsafeFlags(["-LLibraries/dlib/lib/x86_64"], .when(platforms: [.macOS])),
            ]
        ),
    ]
)
