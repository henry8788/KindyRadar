import Foundation

@MainActor
class PreschoolDetailViewModel: ObservableObject {
    let preschool: Preschool

    init(preschool: Preschool) {
        self.preschool = preschool
    }

    // MARK: - 格式化欄位

    var monthlyFeeText: String {
        guard let fee = preschool.monthlyFee else { return "—" }
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: fee), number: .decimal)
        return "$\(formatted)"
    }

    var totalAreaText: String {
        guard let area = preschool.totalArea else { return "—" }
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: area), number: .decimal)
        return "\(formatted) 平方公尺"
    }

    var indoorAreaText: String {
        guard let area = preschool.indoorArea else { return "—" }
        return String(format: "%.2f m²", area)
    }

    var outdoorAreaText: String {
        guard let area = preschool.outdoorArea else { return "—" }
        return String(format: "%.2f m²", area)
    }

    var approvedCapacityText: String {
        guard let cap = preschool.approvedCapacity else { return "—" }
        return "\(cap) 人"
    }

    var hasViolations: Bool {
        !preschool.violations.isEmpty
    }
}
