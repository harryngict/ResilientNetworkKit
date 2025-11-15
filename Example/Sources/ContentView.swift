import SwiftUI

// MARK: - ContentView

struct ContentView: View {
  // MARK: Lifecycle

  init(dependency: AppDependency) {
    self.dependency = dependency
  }

  // MARK: Internal

  var body: some View {
    NavigationView {
      List {
        NavigationLink(destination: ResilientNetworkKitDemoView(networkKit: dependency.networkKit)) {
          Text("Tap to open Demo")
        }
      }
      .navigationTitle("ResilientNetworkKit")
    }
  }

  // MARK: Private

  private let dependency: AppDependency
}
