import DesignSystem
import Domain
import PriceFeed
import SwiftUI

public struct AssetDetailView: View {
    @State private var viewModel: AssetDetailViewModel
    @State private var scrubbedPoint: PricePoint?
    @State private var isAddingHolding = false
    private let dependencies: AppDependencies

    public init(row: MarketsViewModel.Row, dependencies: AppDependencies) {
        _viewModel = State(initialValue: AssetDetailViewModel(row: row, dependencies: dependencies))
        self.dependencies = dependencies
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                chartCard
                statsCard
                addToPortfolioButton
            }
            .padding(16)
        }
        .background(Palette.background)
        .navigationTitle(viewModel.asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FeedStatusBadge(status: viewModel.feedStatus)
            }
        }
        .task { await viewModel.activate() }
        .sheet(isPresented: $isAddingHolding) {
            AddHoldingView(dependencies: dependencies, preselectedAsset: viewModel.asset)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            TokenBadge(
                code: viewModel.asset.code,
                color: Color(hex: viewModel.asset.brandColorHex),
                size: 48
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.asset.code)
                    .font(AppTypography.label(15, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
                Text(displayedPrice.usdPrice)
                    .font(AppTypography.numeric(34, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.numericText(value: displayedPrice.doubleValue))
                    .animation(.snappy(duration: 0.3), value: displayedPrice)
                    .flash(on: flashTrigger, color: flashColor)
                subtitleRow
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var subtitleRow: some View {
        if let scrubbedPoint {
            Text(scrubbedPoint.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(AppTypography.label(13, weight: .medium))
                .foregroundStyle(Palette.textSecondary)
        } else {
            HStack(spacing: 8) {
                TrendPill(changePercent: viewModel.changePercent24h)
                Text("Past 24h")
                    .font(AppTypography.label(13))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Price")
                    .font(AppTypography.label(15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                TimeframePicker(selection: viewModel.timeframe) { viewModel.select($0) }
            }
            switch viewModel.chartState {
            case .loading:
                SkeletonBlock(cornerRadius: 12)
                    .frame(height: 220)
                    .shimmering()
            case .loaded(let points):
                PriceChartView(
                    points: points,
                    tint: chartTint,
                    showsLiveDot: viewModel.timeframe.supportsLiveAppend && viewModel.feedStatus == .live,
                    xLabelFormat: xLabelFormat,
                    scrubbedPoint: $scrubbedPoint
                )
                .frame(height: 220)
            case .failed(let message):
                VStack(spacing: 10) {
                    Text(message)
                        .font(AppTypography.label(14))
                        .foregroundStyle(Palette.textSecondary)
                    Button("Retry") { viewModel.retryHistory() }
                        .font(AppTypography.label(14, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            }
        }
        .card()
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("24h Statistics")
                .font(AppTypography.label(15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            RangeBar(
                low: viewModel.low24h.doubleValue,
                high: viewModel.high24h.doubleValue,
                current: viewModel.currentPrice.doubleValue
            )
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                StatCell(title: "High", value: viewModel.high24h.usdPrice)
                StatCell(title: "Low", value: viewModel.low24h.usdPrice)
                StatCell(title: "Volume", value: viewModel.quoteVolume24h.usdCompact)
                StatCell(title: "Change", value: changeText)
            }
        }
        .card()
    }

    private var addToPortfolioButton: some View {
        Button {
            isAddingHolding = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add to Portfolio")
            }
            .font(AppTypography.label(16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.heroGradient)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var displayedPrice: Decimal {
        scrubbedPoint?.price ?? viewModel.currentPrice
    }

    private var flashTrigger: Decimal {
        scrubbedPoint == nil ? viewModel.currentPrice : 0
    }

    private var flashColor: Color {
        switch viewModel.movement {
        case .up: Palette.gain
        case .down: Palette.loss
        case .flat: .clear
        }
    }

    private var chartTint: Color {
        viewModel.changePercent24h < 0 ? Palette.loss : Palette.gain
    }

    private var changeText: String {
        let sign = viewModel.changePercent24h >= 0 ? "+" : "-"
        let magnitude = viewModel.changePercent24h.magnitude
            .formatted(.number.precision(.fractionLength(2)))
        return "\(sign)\(magnitude)%"
    }

    private var xLabelFormat: Date.FormatStyle {
        switch viewModel.timeframe {
        case .hour, .day: .dateTime.hour().minute()
        case .week: .dateTime.weekday(.abbreviated)
        }
    }
}

struct StatCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.label(12, weight: .medium))
                .foregroundStyle(Palette.textTertiary)
            Text(value)
                .font(AppTypography.numeric(15))
                .foregroundStyle(Palette.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RangeBar: View {
    let low: Double
    let high: Double
    let current: Double

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Palette.loss.opacity(0.55), Palette.gain.opacity(0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Circle()
                        .fill(Palette.textPrimary)
                        .overlay(Circle().stroke(Palette.surface, lineWidth: 2))
                        .frame(width: 12, height: 12)
                        .offset(x: fraction * (geometry.size.width - 12))
                        .animation(.smooth(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 12)
            HStack {
                Text("24h Low")
                Spacer()
                Text("24h High")
            }
            .font(AppTypography.label(11, weight: .medium))
            .foregroundStyle(Palette.textTertiary)
        }
    }

    private var fraction: CGFloat {
        guard high > low else { return 0.5 }
        return CGFloat(min(1, max(0, (current - low) / (high - low))))
    }
}
