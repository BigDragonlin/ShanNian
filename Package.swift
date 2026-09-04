// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ShanNian",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ShanNian", targets: ["ShanNian"])
    ],
    targets: [
        .target(name: "ShanNianCore"),
        .executableTarget(name: "ShanNian", dependencies: ["ShanNianCore"]),
        .executableTarget(name: "VerifyShanNian", dependencies: ["ShanNianCore"])
    ]
)
