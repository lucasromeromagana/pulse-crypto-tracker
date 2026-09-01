import DesignSystem
import Domain
import PriceFeed
import SwiftUI

public struct MarketsView: View {
    @State private var viewModel: MarketsViewModel
    private let dependencies: AppDependencies

    public init(viewModel: MarketsViewModel, dependencies: AppDependencies) {
        _viewModel = State(initialValue: viewModel)
        self.dependencies = dependencies
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    loadingList
                case .loaded(let rows):
                    marketList(rows)
                case .failed(let message):
                    ErrorStateView(message: message) {
                        Task { await viewModel.retry() }
                    }
                }
            }
            .background(Palette.background)
            .navigationTitle("Markets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FeedStatusBadge(status: viewModel.feedStatus)
                }
            }
            .navigationDestination(for: MarketsViewModel.Row.self) { row in
                AssetDetailView(row: row, dependencies: dependencies)
            }
        }
        .task { await viewModel.activate() }
    }

    private func marketList(_ rows: [MarketsViewModel.Row]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(rows) { row in
                    NavigationLink(value: row) {
                        MarketRowView(row: row)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var loadingList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<8, id: \.self) { _ in
                    MarketRowSkeleton()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .disabled(true)
    }
}

struct MarketRowView: View {
    let row: MarketsViewModel.Row

    var body: some View {
        HStack(spacing: 12) {
            TokenBadge(code: row.asset.code, color: Color(hex: row.asset.brandColorHex))
            VStack(alignment: .leading, spacing: 3) {
                Text(row.asset.code)
                    .font(AppTypography.label(16, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text(row.asset.name)
                    .font(AppTypography.label(13))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(row.price.usdPrice)
                    .font(AppTypography.numeric(16))
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.numericText(value: row.price.doubleValue))
                    .animation(.snappy(duration: 0.3), value: row.price)
                    .flash(on: row.price, color: flashColor)
                TrendPill(changePercent: row.changePercent24h)
            }
        }
        .card(padding: 14)
    }

    private var flashColor: Color {
        switch row.movement {
        case .up: Palette.gain
        case .down: Palette.loss
        case .flat: .clear
        }
    }
}

struct MarketRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBlock(cornerRadius: 21)
                .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock().frame(width: 56, height: 13)
                SkeletonBlock().frame(width: 84, height: 11)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                SkeletonBlock().frame(width: 78, height: 13)
                SkeletonBlock().frame(width: 52, height: 18)
            }
        }
        .card(padding: 14)
        .shimmering()
    }
}

#Preview("Markets — mock feed") {
    let dependencies = AppDependencies.mock()
    return MarketsView(
        viewModel: MarketsViewModel(dependencies: dependencies),
        dependencies: dependencies
    )
}
