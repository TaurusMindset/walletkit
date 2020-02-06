// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WalletKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "WalletKit",
            targets: ["WalletKit"]
        ),
    ],

    dependencies: [
        .package(url: "git@github.com:blockset-corp/walletkit-core.git", .branch("develop"))
    ],

    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "WalletKit",
            dependencies: [
                "WalletKitCore"
            ],
            path: "WalletKit"
        ),

        .testTarget(
            name: "WalletKitTests",
            dependencies: [
                "WalletKit"
            ],
            path: "WalletKitTests"
        ),
    ]
)
