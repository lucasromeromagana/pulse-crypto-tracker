import DesignSystem
import Domain
import SwiftUI

public struct PortfolioView: View {
    @State private var viewModel: PortfolioViewModel
    @State private var isAddingHolding = false
    private let dependencies: AppDependencies

    public init(viewModel: PortfolioViewModel, dependencies: AppDependencies) {
        _viewModel = State(initialValue: viewModel)
        self.dependencies = dependencies
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let valuation = viewModel.valuation {
                    if valuation.positions.isEmpty {
                        emptyState
                    } else {
                        holdingsList(valuation)
                    }
                } else {
                    loadingState
                }
            }
            .background(Palette.background)
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingHolding = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $isAddingHolding) {
                AddHoldingView(dependencies: dependencies) {
                    Task { await viewModel.refreshHoldings() }
                }
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.activate() }
    }

    private func holdingsList(_ valuation: PortfolioValuation) -> some View {
        List {
            PortfolioHeroCard(valuation: valuation)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
            ForEach(valuation.positions) { position in
                HoldingRowView(
                    position: position,
                    movement: viewModel.movements[position.holding.symbol] ?? .flat
                )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.remove(position.holding) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Palette.heroGradient)
                    .opacity(0.16)
                    .frame(width: 88, height: 88)
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Palette.accent)
            }
            Text("Build your portfolio")
                .font(AppTypography.label(20, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Text("Add your first holding and watch its value\nmove with the market in real time.")
                .font(AppTypography.label(14))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                isAddingHolding = true
            } label: {
                Text("Add Holding")
                    .font(AppTypography.label(15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Palette.heroGradient))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            SkeletonBlock(cornerRadius: 24)
                .frame(height: 170)
            ForEach(0..<3, id: \.self) { _ in
                SkeletonBlock(cornerRadius: 20)
                    .frame(height: 68)
            }
            Spacer()
        }
        .padding(16)
        .shimmering()
    }
}

#Preview("Portfolio — mock feed") {
    let dependencies = AppDependencies.mock()
    return PortfolioView(
        viewModel: PortfolioViewModel(dependencies: dependencies),
        dependencies: dependencies
    )
}
