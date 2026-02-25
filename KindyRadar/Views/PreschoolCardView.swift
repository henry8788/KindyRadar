import SwiftUI

// MARK: - 幼兒園卡片

struct PreschoolCardView: View {
    let preschool: Preschool

    var body: some View {
        HStack(alignment: .center) {
            // 左側：名稱 + 地區 + 類型標籤
            VStack(alignment: .leading, spacing: 2) {
                Text(preschool.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0f172a"))

                HStack(spacing: 8) {
                    Text(preschool.district)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#94a3b8"))

                    SchoolTypeTag(type: preschool.type)
                }
            }

            Spacer()

            // 右側：違規狀態徽章
            ViolationBadge(status: preschool.violationStatus)
        }
        .padding(17)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#f1f5f9"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - 類型標籤

private struct SchoolTypeTag: View {
    let type: SchoolType

    var body: some View {
        let colors = type.tagColor
        Text(type.rawValue)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(hex: colors.text))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(hex: colors.background))
            .clipShape(Capsule())
    }
}

// MARK: - 違規狀態徽章

private struct ViolationBadge: View {
    let status: ViolationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.isClean ? "checkmark.circle" : "exclamationmark.triangle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(badgeTextColor)

            Text(status.label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(badgeTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(badgeBackground)
        .clipShape(Capsule())
    }

    private var badgeBackground: Color {
        status.isClean ? Color(hex: "#f0fdf4") : Color(hex: "#fff7ed")
    }

    private var badgeTextColor: Color {
        status.isClean ? Color(hex: "#16a34a") : Color(hex: "#ea580c")
    }
}

// MARK: - Color Hex 擴充

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ForEach(Preschool.mockData) { preschool in
            PreschoolCardView(preschool: preschool)
        }
    }
    .padding()
    .background(Color(hex: "#f2f2f7"))
}
