import DesignSystem
import SwiftUI

public struct RootView: View {
    private let dependencies: AppDependencies
    @State private var marketsViewModel: MarketsViewModel
    @State private var portfolioViewModel: PortfolioViewModel

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _marketsViewModel = State(initialValue: MarketsViewModel(dependencies: dependencies))
        _portfolioViewModel = State(initialValue: PortfolioViewModel(dependencies: dependencies))
    }

    public var body: some View {
        TabView {
            MarketsView(viewModel: marketsViewModel, dependencies: dependencies)
                .tabItem { Label("Markets", systemImage: "chart.line.uptrend.xyaxis") }
            PortfolioView(viewModel: portfolioViewModel, dependencies: dependencies)
                .tabItem { Label("Portfolio", systemImage: "chart.pie.fill") }
        }
        .tint(Palette.accent)
    }
}

#Preview("App — mock feed") {
    RootView(dependencies: .mock())
}
