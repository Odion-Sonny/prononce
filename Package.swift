// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Prononce",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Prononce",
            targets: ["Prononce"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Prononce",
            path: "Sources/Prononce",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
