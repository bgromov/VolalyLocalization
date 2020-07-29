// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "VolalyLocalization",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "VolalyLocalization",
            targets: ["CRelloc", "VolalyLocalization"]),
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
                .headerSearchPath("../../Libraries/dlib/include")
            ],
            linkerSettings: [
                // These are not strictly needed in current implementation, as it seems
                // all the functionality is available in headers
                .linkedLibrary(":Libraries/dlib/lib/arm64/libdlib.a", .when(platforms: [.iOS])),
                .linkedLibrary(":Libraries/dlib/lib/x86_64/libdlib.a", .when(platforms: [.macOS])),

                .linkedFramework("Accelerate", .when(platforms: [.iOS, .macOS])),
            ]
        ),

        /// FIXME: this won't build because, apparently, tests are built
        /// as a dynamic library and we have static ones in CRelloc
        ///
        /// Workaround: comment out .linkedLibraries above in CRelloc target.

        //.testTarget(name: "CRellocTests",
        //            dependencies: ["CRelloc", "VolalyLocalization",
        //                           .product(name: "Transform", package: "TransformSwift")]),
    ],
    cxxLanguageStandard: .cxx1z
)
