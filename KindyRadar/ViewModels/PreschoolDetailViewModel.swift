import Foundation

@MainActor
class PreschoolDetailViewModel: ObservableObject {
    let preschool: Preschool

    @Published var isSubscribed: Bool = false
    @Published var isSubscriptionLoading: Bool = false
    @Published var subscriptionError: String? = nil

    private let _notificationService = NotificationService.shared

    init(preschool: Preschool) {
        self.preschool = preschool
    }

    func loadSubscriptionState() async {
        isSubscribed = await _notificationService.isSubscribed(to: preschool.name)
    }

    func toggleSubscription() async {
        isSubscriptionLoading = true
        subscriptionError = nil
        do {
            if isSubscribed {
                try await _notificationService.unsubscribe(from: preschool.name)
                isSubscribed = false
            } else {
                try await _notificationService.subscribe(to: preschool.name)
                isSubscribed = true
            }
        } catch {
            subscriptionError = error.localizedDescription
        }
        isSubscriptionLoading = false
    }

    // MARK: - 格式化欄位

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
