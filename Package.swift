// swift-tools-version:5.7
import Foundation
import PackageDescription

let packageDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
let infoPlistPath = "\(packageDirectory)/Sources/bssid/Info.plist"

let package = Package(
    name: "bssid",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.4.1"),
    ],
    targets: [
        .executableTarget(
            name: "bssid",
            dependencies: ["Guaka"],
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", infoPlistPath
                ])
            ]),
    ]
)
