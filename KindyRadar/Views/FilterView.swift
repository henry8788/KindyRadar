import SwiftUI

struct FilterView: View {
    @StateObject private var viewModel: FilterViewModel
    @Environment(\.dismiss) private var dismiss

    init(current: FilterCriteria, onApply: @escaping (FilterCriteria) -> Void) {
        _viewModel = StateObject(wrappedValue: FilterViewModel(current: current, onApply: onApply))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#f2f2f7").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Section 1：縣市
                    FilterSection(title: "縣市") {
                        ForEach(City.allCases) { city in
                            FilterRow(
                                label: city.rawValue,
                                isSelected: viewModel.pendingCriteria.city == city
                            ) {
                                viewModel.selectCity(city)
                            }
                            if city != City.allCases.last {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }

                    // Section 1b：行政區（選了縣市才出現）
                    if viewModel.pendingCriteria.city != .all && !viewModel.availableDistricts.isEmpty {
                        FilterSection(title: "行政區") {
                            FilterRow(
                                label: "全部",
                                isSelected: viewModel.pendingCriteria.district.isEmpty
                            ) {
                                viewModel.pendingCriteria.district = ""
                            }
                            ForEach(viewModel.availableDistricts, id: \.self) { district in
                                Divider().padding(.leading, 16)
                                FilterRow(
                                    label: district,
                                    isSelected: viewModel.pendingCriteria.district == district
                                ) {
                                    viewModel.pendingCriteria.district = district
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Section 2：幼兒園類型
                    FilterSection(title: "類型") {
                        ForEach(SchoolType.allCases) { type in
                            FilterRow(
                                label: type.rawValue,
                                isSelected: viewModel.pendingCriteria.schoolType == type
                            ) {
                                viewModel.pendingCriteria.schoolType = type
                            }
                            if type != SchoolType.allCases.last {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }

                    // Section 3：裁罰狀態
                    FilterSection(title: "裁罰狀態") {
                        ForEach(PenaltyFilter.allCases) { filter in
                            FilterRow(
                                label: filter.rawValue,
                                isSelected: viewModel.pendingCriteria.penaltyFilter == filter
                            ) {
                                viewModel.pendingCriteria.penaltyFilter = filter
                            }
                            if filter != PenaltyFilter.allCases.last {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }

                    // 底部留白，避免按鈕遮住
                    Color.clear.frame(height: 110)
                }
                .padding(.top, 32)
                .animation(.easeInOut(duration: 0.25), value: viewModel.pendingCriteria.city)
            }

            // 底部固定按鈕
            applyButton
        }
        .navigationTitle("篩選")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.hasChanges {
                    Button("重設") {
                        viewModel.reset()
                    }
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#2094f3"))
                }
            }
        }
    }

    // MARK: - 套用篩選按鈕

    private var applyButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                viewModel.apply()
                dismiss()
            } label: {
                Text("套用篩選")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2094f3"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 17)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - FilterSection 容器

private struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "#94a3b8"))
                .tracking(1.2)
                .textCase(.uppercase)
                .padding(.leading, 32)

            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#f1f5f9"), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - FilterRow（單一選項列）

private struct FilterRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color(hex: "#2094f3") : Color(hex: "#0f172a"))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#2094f3"))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FilterView(current: FilterCriteria()) { _ in }
    }
}

#Preview("已選擇條件") {
    NavigationStack {
        FilterView(current: FilterCriteria(city: .taipei, schoolType: .public_, penaltyFilter: .clean)) { _ in }
    }
}
