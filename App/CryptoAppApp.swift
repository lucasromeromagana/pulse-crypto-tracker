import Features
import SwiftUI

@main
struct CryptoAppApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
