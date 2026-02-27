import Foundation
import FirebaseMessaging
import FirebaseFirestore

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var fcmToken: String? = nil

    private let _db = Firestore.firestore()
    private let _subscriptionsCollection = "subscriptions"

    private init() {}

    // MARK: - FCM Token

    func fetchFCMToken() async {
        do {
            let token = try await Messaging.messaging().token()
            fcmToken = token
            print("✅ [NotificationService] FCM token: \(token)")
        } catch {
            print("❌ [NotificationService] 取得 FCM token 失敗: \(error)")
        }
    }

    // MARK: - 訂閱 / 取消訂閱

    func subscribe(to schoolName: String) async throws {
        guard let token = fcmToken else {
            throw NotificationError.noFCMToken
        }
        let docId = documentId(schoolName: schoolName, token: token)
        try await _db
            .collection(_subscriptionsCollection)
            .document(docId)
            .setData(["schoolName": schoolName, "fcmToken": token])
        print("✅ [NotificationService] 已訂閱: \(schoolName)")
    }

    func unsubscribe(from schoolName: String) async throws {
        guard let token = fcmToken else {
            throw NotificationError.noFCMToken
        }
        let docId = documentId(schoolName: schoolName, token: token)
        try await _db
            .collection(_subscriptionsCollection)
            .document(docId)
            .delete()
        print("✅ [NotificationService] 已取消訂閱: \(schoolName)")
    }

    func isSubscribed(to schoolName: String) async -> Bool {
        guard let token = fcmToken else { return false }
        let docId = documentId(schoolName: schoolName, token: token)
        let snapshot = try? await _db
            .collection(_subscriptionsCollection)
            .document(docId)
            .getDocument()
        return snapshot?.exists == true
    }

    // MARK: - Private

    private func documentId(schoolName: String, token: String) -> String {
        // 用 schoolName + token 組成穩定唯一 ID
        let raw = "\(schoolName)_\(token)"
        return raw.data(using: .utf8)
            .map { Data($0).base64EncodedString() }
            ?? raw
    }
}

// MARK: - Error

enum NotificationError: LocalizedError {
    case noFCMToken

    var errorDescription: String? {
        switch self {
        case .noFCMToken: return "尚未取得推播權限，請先允許通知。"
        }
    }
}
