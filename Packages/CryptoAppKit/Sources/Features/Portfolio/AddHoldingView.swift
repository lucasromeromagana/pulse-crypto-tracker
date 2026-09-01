import DesignSystem
import Domain
import SwiftUI

struct AddHoldingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddHoldingViewModel
    private let onSaved: (() -> Void)?

    init(
        dependencies: AppDependencies,
        preselectedAsset: Asset? = nil,
        onSaved: (() -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: AddHoldingViewModel(
                portfolio: dependencies.portfolio,
                preselectedAsset: preselectedAsset
            )
        )
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    assetPicker
                    inputField(
                        title: "Quantity",
                        text: $viewModel.quantityText,
                        prompt: "0.00",
                        suffix: viewModel.selectedAsset.code
                    )
                    inputField(
                        title: "Average Buy Price (optional)",
                        text: $viewModel.buyPriceText,
                        prompt: "0.00",
                        suffix: "USD"
                    )
                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                    }
                    saveButton
                }
                .padding(16)
            }
            .background(Palette.background)
            .navigationTitle("Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var assetPicker: some View {
        Menu {
            ForEach(AssetCatalog.tracked) { asset in
                Button("\(asset.name) (\(asset.code))") {
                    viewModel.selectedAsset = asset
                }
            }
        } label: {
            HStack(spacing: 12) {
                TokenBadge(
                    code: viewModel.selectedAsset.code,
                    color: Color(hex: viewModel.selectedAsset.brandColorHex),
                    size: 38
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedAsset.name)
                        .font(AppTypography.label(15, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text(viewModel.selectedAsset.code)
                        .font(AppTypography.label(12))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .card(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        prompt: String,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.label(13, weight: .medium))
                .foregroundStyle(Palette.textSecondary)
            HStack {
                TextField(prompt, text: text)
                    .font(AppTypography.numeric(17))
                    .foregroundStyle(Palette.textPrimary)
                    .keyboardType(.decimalPad)
                Text(suffix)
                    .font(AppTypography.label(13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .card(padding: 14)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.loss)
            Text(message)
                .font(AppTypography.label(13, weight: .medium))
                .foregroundStyle(Palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.loss.opacity(0.12))
        )
    }

    private var saveButton: some View {
        Button {
            Task {
                if await viewModel.save() {
                    onSaved?()
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Add Holding")
                }
            }
            .font(AppTypography.label(16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.heroGradient)
                    .opacity(viewModel.canSave ? 1 : 0.45)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .padding(.top, 6)
    }
}
