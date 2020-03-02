// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WalletKitCore",
    products: [
        .library(
            name: "WalletKitCore",
            targets: ["WalletKitCore"]
        ),
        
        .executable(
            name: "WalletKitExplore",
            targets: ["WalletKitExplore"]
        ),
        
        
        .executable(
            name: "WalletKitPerf",
            targets: ["WalletKitPerf"]
        ),
    ],
    dependencies: [],
    targets: [
        // MARK: - Core Targets

        //
        // We want to compile all Core sources with various warnings enabled.  This is performed
        // in a Package.swift with a `cSettings.unsafeFlags` declaration.  However, a sub-package
        // dependency is forbidden from having a unsafeFlags declaration.  Thus walletkit-swift
        // depending on walletkit-core will fail during package validation.  We work around this
        // by ensuring that this top-level `.target` does not have an unsafeFlags declaration but
        // that subtargets do have our desired unsafeFlags.
        //
        // In order to accomplish the above this `WalletKitCore` target will depend on
        // `WalletKitCoreSafe`, where ALL the sources will be, BUT we need at least one source
        // file to remain in `WalletKitCore`.  We'll create one.
        //
        .target(
            name: "WalletKitCore",
            dependencies: [
                "WalletKitCoreSafe",
                "WalletKitSQLite",
                "WalletKitEd25519",
                "WalletKitHederaProto",
            ],
            path: "WalletKitCore",
            sources: ["version"],                   // Holds BRCryptoVersion.c only
            publicHeadersPath: "include",           // Export all public includes
            linkerSettings: [
                .linkedLibrary("resolv"),
                .linkedLibrary("pthread"),
                .linkedLibrary("bsd", .when(platforms: [.linux])),
            ]
        ),

        .target(
            name: "WalletKitCoreSafe",
            dependencies: [
            ],
            path: "WalletKitCore",
            exclude: [
                "version",          // See target: WalletKitCore (above)
                "vendor",           // See target: WalletKitSQLite
                "hedera/proto"      // See target: WalletKitHederaProto
            ],
            publicHeadersPath: "version",   // A directory WITHOUT headers
            cSettings: [
                .headerSearchPath("include"),           // BRCrypto
                .headerSearchPath("support"),           // Temporary (change support/, bitcoin/)
                .headerSearchPath("."),
                .headerSearchPath("vendor/secp256k1"),
                .unsafeFlags([
                    // Enable warning flags
                    "-Wall",
                    "-Wconversion",
                    "-Wsign-conversion",
                    "-Wparentheses",
                    "-Wswitch",
                    // Disable warning flags, if appropriate
                    "-Wno-implicit-int-conversion",
                    // "-Wno-sign-conversion",
                    "-Wno-missing-braces"
                ])
            ]
        ),

        // Custom compilation flags for SQLite - to silence warnings
        .target(
            name: "WalletKitSQLite",
            dependencies: [],
            path: "WalletKitCore/vendor/sqlite3",
            sources: ["sqlite3.c"],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-D_HAVE_SQLITE_CONFIG_H=1",
                    "-Wno-ambiguous-macro",
                    "-Wno-shorten-64-to-32",
                    "-Wno-unreachable-code",
                    "-Wno-#warnings"
                ])
            ]
        ),

        // Custom compilation flags for ed15519 - to silence warnings
        .target(
            name: "WalletKitEd25519",
            dependencies: [],
            path: "WalletKitCore/vendor/ed25519",
            exclude: [],
            publicHeadersPath: nil,
            cSettings: [
                .unsafeFlags([])
            ]
        ),

        // Custom compilation flags for hedera/proto - to silence warnings
        .target(
            name: "WalletKitHederaProto",
            dependencies: [],
            path: "WalletKitCore/hedera/proto",
            publicHeadersPath: nil,
            cSettings: [
                .unsafeFlags([
                    "-Wno-shorten-64-to-32",
                ])
            ]
        ),

        // MARK: - Core Misc Targets

        .target (
            name: "WalletKitExplore",
            dependencies: ["WalletKitCore"],
            path: "WalletKitExplore",
            cSettings: [
                .headerSearchPath("../WalletKitCore"),
                .headerSearchPath("../WalletKitCore/support"),
                .headerSearchPath("../WalletKitCore/bitcoin"),
            ]
        ),

        .target (
            name: "WalletKitPerf",
            dependencies: ["WalletKitCore", "WalletKitSupportTests"],
            path: "WalletKitPerf",
            cSettings: [
                .headerSearchPath("../WalletKitCore"),
                .headerSearchPath("../WalletKitCore/support"),
                .headerSearchPath("../WalletKitCore/bitcoin"),
                .headerSearchPath("../WalletKitCoreTests/test"),
            ]
        ),

        // MARK: - Core Test Targets

        .target(
            name: "WalletKitSupportTests",
            dependencies: ["WalletKitCore"],
            path: "WalletKitCoreTests/test",
            publicHeadersPath: "include",
            cSettings: [
                .define("BITCOIN_TEST_NO_MAIN"),
                .headerSearchPath("../../WalletKitCore"),
                .headerSearchPath("../../WalletKitCore/support"),
                .headerSearchPath("../../WalletKitCore/bitcoin")
            ]
        ),

        .testTarget(
            name: "WalletKitCoreTests",
            dependencies: [
                "WalletKitSupportTests"
            ],
            path: "WalletKitCoreTests",
            exclude: [
                "test"
            ],
            cSettings: [
                .headerSearchPath("../WalletKitCore"),
                .headerSearchPath("../WalletKitCore/support"),
                .headerSearchPath("../WalletKitCore/bitcoin")
            ],
            linkerSettings: [
                .linkedLibrary("pthread"),
                .linkedLibrary("bsd", .when(platforms: [.linux])),
            ]
        ),
    ]
)
