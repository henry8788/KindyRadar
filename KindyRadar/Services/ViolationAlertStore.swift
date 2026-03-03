import Foundation

/// 儲存從推播收到的新裁罰幼兒園 ID，持久化於 UserDefaults
@MainActor
final class ViolationAlertStore: ObservableObject {
    static let shared = ViolationAlertStore()

    @Published private(set) var pendingPreschoolIds: [String] = []

    private let _key = "pendingViolationPreschoolIds"

    private init() {
        load()
    }

    var hasUnread: Bool { !pendingPreschoolIds.isEmpty }

    /// 從推播 payload 加入新的幼兒園 ID（去重）
    func add(ids: [String]) {
        let merged = Array(Set(pendingPreschoolIds + ids))
        pendingPreschoolIds = merged
        save()
    }

    /// 使用者看完後清除
    func clearAll() {
        pendingPreschoolIds = []
        save()
    }

    // MARK: - Private

    private func load() {
        pendingPreschoolIds = UserDefaults.standard.stringArray(forKey: _key) ?? []
    }

    private func save() {
        UserDefaults.standard.set(pendingPreschoolIds, forKey: _key)
    }
}
