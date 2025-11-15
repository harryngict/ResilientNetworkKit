import ResilientNetworkKit
import ResilientNetworkKitImp
import SwiftUI

// MARK: - SceneDelegate

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  var networkKit: ResilientNetworkKit!

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions)
  {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: windowScene)

    let requestInterceptors: [RequestInterceptor] = [
      ClientRequestInterceptorImp(),
      SensibleRequestInterceptorImp(),
    ]

    let builder = ResilientNetworkKitBuilder()
    networkKit = builder
      .withNetworkLogTracker(self)
      .withSessionDelegate(.default)
      .withResponseMonitorInterceptor(ClientResponseMonitorInterceptorImp(networkLogTracker: self))
      .withNetworkTraceInspector(nil)
      .withTokenRefreshingInterceptor(self)
      .withCircuitBreakerConfig(CircuitBreakerConfiguration())
      .withAdvancedRetryInterceptor(AdvancedRetryInterceptorImp())
      .addRequestInterceptors(requestInterceptors)
      .build()

    let dependency = AppDependencyImp(networkKit: networkKit)

    let contentView = ContentView(dependency: dependency)
    window.rootViewController = UIHostingController(rootView: contentView)
    self.window = window
    window.makeKeyAndVisible()
  }

  func sceneDidEnterBackground(_ scene: UIScene) {}
}

// MARK: TokenRefreshingInterceptor

extension SceneDelegate: TokenRefreshingInterceptor {
  func getRefreshToken() -> String { "refresh-token" }

  func refreshAccessToken(completion: @escaping (Result<Void, ResilientNetworkKitError>) -> Void) {
    let endpoint = RefreshTokenEndpoint()
    networkKit?.send(endpoint, completion: { result in
      switch result {
      case .success:
        completion(.success(()))
      case let .failure(error):
        completion(.failure(error))
      }
    })
  }
}

// MARK: NetworkLogTracker

extension SceneDelegate: NetworkLogTracker {
  func log(_ tag: String, _ message: String) {}
  func infor(_ tag: String, _ message: String) {}
  func warning(_ tag: String, _ message: String) {}
  func error(_ tag: String, _ message: String) {}
  func success(_ tag: String, _ message: String) {}
}
