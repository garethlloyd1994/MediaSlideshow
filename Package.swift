// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "MediaSlideshow",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MediaSlideshow",
            targets: ["MediaSlideshow"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.2"),
        .package(url: "https://github.com/hainayanda/Odeum.git", .upToNextMajor(from: "1.2.8"))
    ],
    targets: [
        .target(name: "MediaSlideshow",
                dependencies: ["Kingfisher", "Odeum"],
                path: "MediaSlideshow",
                sources: ["Source"],
                resources: [
                    .copy("Resources/ic_cross_white@2x.png"),
                    .copy("Resources/ic_cross_white@3x.png"),
                    .copy("Resources/AVAssets.xcassets")
                ]),
    ]
)
