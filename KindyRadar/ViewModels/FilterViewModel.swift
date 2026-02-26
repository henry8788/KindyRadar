import Foundation

@MainActor
class FilterViewModel: ObservableObject {
    @Published var pendingCriteria: FilterCriteria

    private let onApply: (FilterCriteria) -> Void

    init(current: FilterCriteria, onApply: @escaping (FilterCriteria) -> Void) {
        self.pendingCriteria = current
        self.onApply = onApply
    }

    var availableDistricts: [String] {
        pendingCriteria.city.districts
    }

    func selectCity(_ city: City) {
        pendingCriteria.city = city
        pendingCriteria.district = ""
    }

    func apply() {
        onApply(pendingCriteria)
    }

    func reset() {
        pendingCriteria = FilterCriteria()
    }

    var hasChanges: Bool {
        !pendingCriteria.isDefault
    }
}
