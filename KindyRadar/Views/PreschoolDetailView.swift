import SwiftUI

struct PreschoolDetailView: View {
    @StateObject private var viewModel: PreschoolDetailViewModel
    @Environment(\.openURL) private var openURL
    @State private var showMapPicker = false

    init(preschool: Preschool) {
        _viewModel = StateObject(wrappedValue: PreschoolDetailViewModel(preschool: preschool))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景
            Color(hex: "#f5f7f8").ignoresSafeArea()

            // 可捲動內容
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    violationBanner
                    if viewModel.hasViolations {
                        penaltySection
                    }
                    infoSection
                    facilitySection
                    registrationSection
                    // 底部留白，避免被按鈕遮住
                    Color.clear.frame(height: 100)
                }
            }

            // 底部固定按鈕
            contactButton
        }
        .navigationTitle("園所詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    shareButton
                    subscribeButton
                }
            }
        }
        .task {
            await viewModel.loadSubscriptionState()
        }
        .alert("訂閱失敗", isPresented: Binding(
            get: { viewModel.subscriptionError != nil },
            set: { if !$0 { viewModel.subscriptionError = nil } }
        )) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(viewModel.subscriptionError ?? "")
        }
    }

    // MARK: - 分享按鈕

    private var shareButton: some View {
        let school = viewModel.preschool
        let violationText = school.violationStatus.isClean
            ? "✅ 無裁罰紀錄"
            : "⚠️ 有裁罰紀錄（\(school.violationStatus.label)）"
        let shareText = """
        【幼兒園避雷】\(school.name)
        📍 \(school.fullAddress)
        🏷 類型：\(school.type.rawValue)
        \(violationText)

        資料來源：教育部幼兒園基本資料
        """
        return ShareLink(item: shareText) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#64748b"))
        }
    }

    // MARK: - 訂閱按鈕

    private var subscribeButton: some View {
        Button {
            Task { await viewModel.toggleSubscription() }
        } label: {
            if viewModel.isSubscriptionLoading {
                ProgressView()
                    .tint(Color(hex: "#2094f3"))
            } else {
                Image(systemName: viewModel.isSubscribed ? "bell.fill" : "bell")
                    .font(.system(size: 16))
                    .foregroundStyle(viewModel.isSubscribed ? Color(hex: "#2094f3") : Color(hex: "#64748b"))
            }
        }
        .disabled(viewModel.isSubscriptionLoading)
    }

    // MARK: - Hero Section（名稱、地址）

    private var heroSection: some View {
        let school = viewModel.preschool
        return VStack(alignment: .leading, spacing: 12) {
            // 類型標籤列
            HStack(spacing: 8) {
                typeTag(school.type.rawValue)
                if let period = school.quasiPublicPeriod {
                    typeTag("準公共 \(period)")
                }
            }

            // 園所名稱
            Text(school.name)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color(hex: "#0f172a"))
                .tracking(-0.75)

            // 地址（可點擊開地圖）
            Button {
                showMapPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#2094f3"))
                    Text(school.fullAddress)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#2094f3"))
                        .underline()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#2094f3"))
                }
            }
            .buttonStyle(.plain)
            .confirmationDialog("選擇地圖", isPresented: $showMapPicker) {
                Button("Apple 地圖") {
                    let encoded = school.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "maps://?q=\(encoded)") {
                        openURL(url)
                    }
                }
                Button("Google Maps") {
                    let encoded = school.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "comgooglemaps://?q=\(encoded)"),
                       UIApplication.shared.canOpenURL(url) {
                        openURL(url)
                    } else if let url = URL(string: "https://maps.google.com/?q=\(encoded)") {
                        openURL(url)
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 25)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }

    private func typeTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(hex: "#2094f3"))
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Color(hex: "#2094f3").opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - 裁罰狀態 Banner

    private var violationBanner: some View {
        let isClean = viewModel.preschool.violationStatus.isClean
        return HStack(spacing: 12) {
            Image(systemName: isClean ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.system(size: 28))
                .foregroundStyle(isClean ? Color(hex: "#16a34a") : Color(hex: "#dc2626"))

            VStack(alignment: .leading, spacing: 2) {
                Text(isClean ? "無裁罰紀錄" : "有裁罰紀錄")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isClean ? Color(hex: "#16a34a") : Color(hex: "#dc2626"))
                Text(isClean ? "此幼兒園目前無違規裁罰記錄" : "此幼兒園有 \(viewModel.preschool.violationStatus.label)，請見下方詳情")
                    .font(.system(size: 13))
                    .foregroundStyle(isClean ? Color(hex: "#15803d") : Color(hex: "#b91c1c"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isClean ? Color(hex: "#f0fdf4") : Color(hex: "#fff1f2"))
        .overlay(
            Rectangle()
                .frame(width: 4)
                .foregroundStyle(isClean ? Color(hex: "#16a34a") : Color(hex: "#dc2626")),
            alignment: .leading
        )
    }

    // MARK: - 基本資訊

    private var infoSection: some View {
        let school = viewModel.preschool
        return DetailSection(title: "基本資訊 Basic Info") {
            InfoRow(
                icon: "person",
                label: "負責人",
                value: school.principalName ?? "—"
            )
            Divider().padding(.leading, 72)

            // 電話（可點擊撥打）
            if let phone = school.phone {
                Button {
                    let cleaned = phone.filter { $0.isNumber }
                    if let url = URL(string: "tel:\(cleaned)") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        InfoRow(icon: "phone", label: "聯絡電話", value: phone)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#94a3b8"))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 設施規模

    private var facilitySection: some View {
        let school = viewModel.preschool
        return DetailSection(title: "設施規模 Facility Details") {
            InfoRow(
                icon: "person.3",
                label: "核定人數",
                value: viewModel.approvedCapacityText
            )
            Divider().padding(.leading, 72)

            InfoRow(
                icon: "building.2",
                label: "樓層資訊",
                value: school.floors ?? "—"
            )
            Divider().padding(.leading, 72)

            // 總面積（含室內/室外子卡）
            HStack(alignment: .top, spacing: 16) {
                iconBox("ruler")
                VStack(alignment: .leading, spacing: 4) {
                    Text("總面積")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                    Text(viewModel.totalAreaText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#0f172a"))
                    HStack(spacing: 16) {
                        areaSubCard(label: "室內", value: viewModel.indoorAreaText)
                        areaSubCard(label: "室外", value: viewModel.outdoorAreaText)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            Divider().padding(.leading, 72)

            InfoRow(
                icon: "clock",
                label: "課後留園",
                value: school.afterSchoolCare ?? "—"
            )
        }
    }

    private func areaSubCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#64748b"))
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#0f172a"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(hex: "#f5f7f8"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 核准立案

    private var registrationSection: some View {
        let school = viewModel.preschool
        return DetailSection(title: "核准立案 Registration") {
            if let no1 = school.registrationNo1 {
                RegistrationRow(label: "文號（一）", value: no1)
                Divider().padding(.leading, 16)
            }
            if let no2 = school.registrationNo2 {
                RegistrationRow(label: "文號（二）", value: no2)
                Divider().padding(.leading, 16)
            }
            if let date = school.registrationDate {
                RegistrationRow(label: "立案日期", value: date)
            }
        }
    }

    // MARK: - 裁罰紀錄

    private var penaltySection: some View {
        DetailSection(title: "裁罰紀錄 Penalty Records") {
            ForEach(viewModel.preschool.violations) { violation in
                VStack(spacing: 0) {
                    // 行為人 header
                    HStack {
                        Text("行為人：\(violation.perpetrator)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#64748b"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#f8fafc"))

                    Divider()

                    // 日期 + 罰鍰 + 說明
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(violation.date)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "#94a3b8"))
                            Spacer()
                            let fineText = "罰鍰：\(NumberFormatter.localizedString(from: NSNumber(value: violation.fineAmount), number: .decimal))元"
                            Text(fineText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "#dc2626"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#fee2e2"))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(violation.description)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#334155"))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        // 條文摘要補充
                        if let summary = LawArticleHelper.summary(for: violation.description) {
                            Text("📋 \(summary)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#64748b"))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    if violation.id != viewModel.preschool.violations.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - 底部聯繫按鈕

    private var contactButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                if let phone = viewModel.preschool.phone {
                    let cleaned = phone.filter { $0.isNumber }
                    if let url = URL(string: "tel:\(cleaned)") {
                        openURL(url)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                    Text("立即聯繫園所")
                        .font(.system(size: 16, weight: .semibold))
                }
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

    // MARK: - 共用 icon box

    private func iconBox(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundStyle(Color(hex: "#2094f3"))
            .frame(width: 40, height: 40)
            .background(Color(hex: "#2094f3").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - DetailSection 容器

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "#94a3b8"))
                .tracking(1.2)
                .textCase(.uppercase)
                .padding(.horizontal, 20)

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
        .padding(.top, 32)
    }
}

// MARK: - InfoRow（icon + label + value）

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#2094f3"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "#2094f3").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#94a3b8"))
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0f172a"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - RegistrationRow（label + value 上下排列）

private struct RegistrationRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#94a3b8"))
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#0f172a"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        PreschoolDetailView(preschool: Preschool.mockData[0])
    }
}

#Preview("無違規") {
    NavigationStack {
        PreschoolDetailView(preschool: Preschool.mockData[1])
    }
}
#endif
