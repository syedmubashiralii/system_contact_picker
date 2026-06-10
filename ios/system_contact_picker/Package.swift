// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "system_contact_picker",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(
            name: "system-contact-picker",
            targets: ["system_contact_picker"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "system_contact_picker",
            dependencies: []
        ),
    ]
)
