import SwiftUI
import CoreLocation

struct PreschoolListView: View {
    @ObservedObject var viewModel: PreschoolListViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var alertStore = ViolationAlertStore.shared

    var body: some View {
        listBody
    }

    private var listBody: some View {
        ZStack(alignment: .top) {
            // 背景色
            Color(hex: "#f2f2f7")
                .ignoresSafeArea()

            // 卡片列表（在 Header 下方）
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header 佔位（撐開 ScrollView 內容不被 Header 遮住）
                    Color.clear.frame(height: 216)

                    listContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.refresh()
            }

            // 固定 Header（毛玻璃）
            headerView
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            viewModel.userLocation = newLocation
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text("幼兒園查詢")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0f172a"))

                Spacer()

                // 裁罰通知按鈕
                NavigationLink(destination: ViolationAlertView(
                    allPreschools: viewModel.allPreschools
                )) {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 5) {
                            Image(systemName: alertStore.hasUnread ? "bell.badge.fill" : "bell.fill")
                                .font(.system(size: 14))
                            Text("最新裁罰")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(alertStore.hasUnread ? Color.white : Color(hex: "#475569"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(alertStore.hasUnread ? Color(hex: "#e53e3e") : Color(hex: "#f1f5f9"))
                        .clipShape(Capsule())
                    }
                }
                .padding(.trailing, 16)

                NavigationLink(destination: FilterView(
                    current: viewModel.filterCriteria,
                    onApply: { viewModel.applyFilterCriteria($0) }
                )) {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 4) {
                            if viewModel.filterCriteria.city != .all {
                                Text(viewModel.filterCriteria.city.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "#2094f3"))
                            }
                            Text("篩選")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color(hex: "#2094f3"))
                        }
                        if viewModel.hasActiveFilter {
                            Circle()
                                .fill(Color(hex: "#e53e3e"))
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -2)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            // 搜尋欄
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // 類型篩選
            typeFilterBar
                .padding(.top, 8)

            // 結果數量 + 排序提示
            if !viewModel.resultCountText.isEmpty {
                HStack {
                    Text(viewModel.resultCountText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#64748b"))

                    Spacer()

                    if locationManager.userLocation != nil {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text("依您目前位置由近到遠排序")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(Color(hex: "#2094f3"))
                    } else if locationManager.authorizationStatus == .denied ||
                              locationManager.authorizationStatus == .restricted {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "location.slash.fill")
                                    .font(.system(size: 11))
                                Text("開啟定位以依距離排序")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#2094f3"))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
            } else {
                Color.clear.frame(height: 20).padding(.vertical, 4)
            }
        }
        .background(.ultraThinMaterial)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 搜尋欄

    private var searchBar: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#94a3b8"))
                .frame(width: 40)

            TextField("搜尋幼兒園或地址...", text: $viewModel.searchText)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#0f172a"))
                .tint(Color(hex: "#2094f3"))
        }
        .frame(height: 44)
        .background(Color(hex: "#f1f5f9"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 類型篩選 Tab

    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SchoolType.allCases) { type in
                    TypeFilterChip(
                        type: type,
                        isSelected: viewModel.selectedType == type
                    ) {
                        viewModel.selectedType = type
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    // MARK: - 列表內容（五種狀態）

    @ViewBuilder
    private var listContent: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            ProgressView("載入中...")
                .padding(.top, 40)
        case .success(let preschools):
            ForEach(preschools) { preschool in
                NavigationLink(destination: PreschoolDetailView(preschool: preschool)) {
                    PreschoolCardView(preschool: preschool)
                }
                .buttonStyle(.plain)
            }
        case .empty:
            ContentUnavailableView(
                "找不到符合的幼兒園",
                systemImage: "magnifyingglass",
                description: Text("請嘗試其他關鍵字或篩選條件")
            )
            .padding(.top, 40)
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "#94a3b8"))
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - 類型篩選膠囊按鈕

private struct TypeFilterChip: View {
    let type: SchoolType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color(hex: "#475569"))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "#2094f3") : Color(hex: "#f1f5f9"))
                .clipShape(Capsule())
                .shadow(
                    color: isSelected ? Color.black.opacity(0.05) : Color.clear,
                    radius: 2, x: 0, y: 1
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("正常資料") { @MainActor in
    PreschoolListView(viewModel: PreschoolListViewModel(), locationManager: LocationManager())
}

#Preview("深色模式") { @MainActor in
    PreschoolListView(viewModel: PreschoolListViewModel(), locationManager: LocationManager())
        .preferredColorScheme(.dark)
}
#endif

