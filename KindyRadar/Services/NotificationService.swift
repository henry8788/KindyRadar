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
            await updateToken(token)
        } catch {
            print("❌ [NotificationService] 取得 FCM token 失敗: \(error)")
        }
    }

    /// token 更新時呼叫：更新記憶體內的 token，並把 Firestore 裡的舊訂閱全部換成新 token
    func updateToken(_ newToken: String) async {
        let oldToken = fcmToken
        fcmToken = newToken
        print("✅ [NotificationService] FCM token 更新: \(newToken)")

        guard oldToken != newToken else { return }

        do {
            if let old = oldToken {
                // 有舊 token → 更新舊訂閱
                let snapshot = try await _db
                    .collection(_subscriptionsCollection)
                    .whereField("fcmToken", isEqualTo: old)
                    .getDocuments()

                if !snapshot.documents.isEmpty {
                    let batch = _db.batch()
                    for doc in snapshot.documents {
                        let schoolName = doc.data()["schoolName"] as? String ?? ""
                        let newDocId = documentId(schoolName: schoolName, token: newToken)
                        let newRef = _db.collection(_subscriptionsCollection).document(newDocId)
                        batch.setData(["schoolName": schoolName, "fcmToken": newToken], forDocument: newRef)
                        batch.deleteDocument(doc.reference)
                    }
                    try await batch.commit()
                    print("✅ [NotificationService] 已更新 \(snapshot.documents.count) 筆訂閱的 token")
                    return
                }
            }

            // oldToken 是 nil 或舊訂閱不存在 → 存一筆新裝置 token
            let docId = documentId(schoolName: "", token: newToken)
            try await _db
                .collection(_subscriptionsCollection)
                .document(docId)
                .setData(["fcmToken": newToken, "schoolName": ""])
            print("✅ [NotificationService] 新裝置 token 已儲存")
        } catch {
            print("❌ [NotificationService] 更新訂閱 token 失敗: \(error)")
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
