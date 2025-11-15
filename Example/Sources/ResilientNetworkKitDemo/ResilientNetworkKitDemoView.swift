import ResilientNetworkKit
import SwiftUI

// MARK: - ResilientNetworkKitDemoView

struct ResilientNetworkKitDemoView: View {
  // MARK: Lifecycle

  init(networkKit: ResilientNetworkKit) {
    self.networkKit = networkKit
  }

  // MARK: Internal

  var body: some View {
    VStack(spacing: 20) {
      Button(action: {
        Task {
          await asynCall()
        }
      }) {
        Text("Test Async Function")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }

      Button(action: {
        completionCall()
      }) {
        Text("Test Completion Function")
          .padding()
          .background(Color.green)
          .foregroundColor(.white)
          .cornerRadius(8)
      }

      Button(action: {
        testRefreshTokenRequest()
      }) {
        Text("Test Refresh Token Request")
          .padding()
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
    }
    .padding()
  }

  // MARK: Private

  private let networkKit: ResilientNetworkKit

  private func completionCall() {
    let endpoint = AccountEndpoint()
    networkKit.send(endpoint, retry: .constant(count: 2, delay: 1.0)) { result in
      switch result {
      case let .success(response):
        print("ResilientNetworkKitDemoView completionCall", "response: \(response)")
      case let .failure(error):
        print("ResilientNetworkKitDemoView completionCall", "error: \(error)")
      }
    }
  }

  private func asynCall() async {
    let endpoint = AccountEndpoint()
    do {
      let response = try await networkKit.send(endpoint, retry: .constant(count: 2, delay: 2.0))
      print("ResilientNetworkKitDemoView completionCall", "response: \(response)")
    } catch {
      print("ResilientNetworkKitDemoView completionCall", "error: \(error)")
    }
  }

  private func testRefreshTokenRequest() {
    let refreshTokenEndpoint = RefreshTokenEndpoint()
    networkKit.send(refreshTokenEndpoint, retry: .constant(count: 2, delay: 1.0)) { result in
      switch result {
      case let .success(response):
        print("ResilientNetworkKitDemoView completionCall", "response: \(response)")
      case let .failure(error):
        print("ResilientNetworkKitDemoView completionCall", "error: \(error)")
      }
    }
  }
}
