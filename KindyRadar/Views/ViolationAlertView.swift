import SwiftUI
import FirebaseFirestore

struct ViolationAlertView: View {
    let allPreschools: [Preschool]

    @StateObject private var viewModel = ViolationAlertViewModel()

    var body: some View {
        ZStack {
            Color(hex: "#f2f2f7").ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if viewModel.items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .navigationTitle("新裁罰通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await viewModel.load(allPreschools: allPreschools)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("比對裁罰紀錄中...")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#64748b"))
        }
    }

    // MARK: - 錯誤

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "#94a3b8"))
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#64748b"))
        }
    }

    // MARK: - 空狀態

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "#94a3b8"))
            Text("目前沒有新裁罰通知")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#64748b"))
        }
    }

    // MARK: - 列表

    private var listView: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("以下幼兒園近三個月有新裁罰紀錄")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#64748b"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                ForEach(viewModel.items) { item in
                    NavigationLink(destination: PreschoolDetailView(preschool: item.preschool)) {
                        ViolationAlertCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                Color.clear.frame(height: 24)
            }
        }
    }
}

// MARK: - 通知卡片

private struct ViolationAlertCard: View {
    let item: NewViolationItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("新")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#e53e3e"))
                        .clipShape(Capsule())

                    Text(item.preschool.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: "#0f172a"))
                }

                Text(item.law)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .lineLimit(2)

                Text(item.date)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#94a3b8"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#94a3b8"))
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#fee2e2"), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}
