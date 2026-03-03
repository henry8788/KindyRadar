import SwiftUI

struct ViolationAlertView: View {
    let preschools: [Preschool]
    @ObservedObject private var store = ViolationAlertStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#f2f2f7").ignoresSafeArea()

            if preschools.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 說明文字
                        HStack {
                            Text("以下幼兒園有新裁罰紀錄")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#64748b"))
                            Spacer()
                            Button("清除全部") {
                                store.clearAll()
                                dismiss()
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#e53e3e"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        ForEach(preschools) { preschool in
                            NavigationLink(destination: PreschoolDetailView(preschool: preschool)) {
                                ViolationAlertCard(preschool: preschool)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }

                        Color.clear.frame(height: 24)
                    }
                }
            }
        }
        .navigationTitle("新裁罰通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

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
}

// MARK: - 通知卡片（帶「新」標籤）

private struct ViolationAlertCard: View {
    let preschool: Preschool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 「新」標籤
                    Text("新")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#e53e3e"))
                        .clipShape(Capsule())

                    Text(preschool.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "#0f172a"))
                }

                Text(preschool.district)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#94a3b8"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#94a3b8"))
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
