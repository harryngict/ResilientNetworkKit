// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "ResilientNetworkKit",
  platforms: [.iOS(.v15)],
  products: [
    // ResilientNetworkKit, ResilientNetworkKitImp, ResilientNetworkKitMock
    .library(
      name: "ResilientNetworkKit",
      targets: ["ResilientNetworkKit"]
    ),
    .library(
      name: "ResilientNetworkKitImp",
      targets: ["ResilientNetworkKitImp"]
    ),
    .library(
      name: "ResilientNetworkKitMock",
      targets: ["ResilientNetworkKitMock"]
    ),
  ],
  dependencies: [],
  targets: [
    // ResilientNetworkKit, ResilientNetworkKitImp, ResilientNetworkKitMock
    .target(
      name: "ResilientNetworkKit",
      dependencies: [],
      path: "Sources/ResilientNetworkKit/interfaces/src"
    ),
    .target(
      name: "ResilientNetworkKitImp",
      dependencies: [
        "ResilientNetworkKit",
      ],
      path: "Sources/ResilientNetworkKit/implementation/src"
    ),
    .target(
      name: "ResilientNetworkKitMock",
      dependencies: [
        "ResilientNetworkKit"
      ],
      path: "Sources/ResilientNetworkKit/mocks/src"
    ),
  ],
  swiftLanguageModes: [.v6]
)
