import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        Task {
            await requestNotificationPermission(application)
        }
        return true
    }

    // MARK: - APNs 註冊回呼

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ [AppDelegate] APNs token 收到，長度: \(deviceToken.count)")
        Messaging.messaging().apnsToken = deviceToken
        Task {
            await NotificationService.shared.fetchFCMToken()
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ [AppDelegate] APNs 註冊失敗: \(error)")
    }

    // MARK: - Private

    private func requestNotificationPermission(_ application: UIApplication) async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run { application.registerForRemoteNotifications() }
                print("✅ [AppDelegate] 推播權限已授權")
            } else {
                print("⚠️ [AppDelegate] 使用者拒絕推播權限")
            }
        } catch {
            print("❌ [AppDelegate] 請求推播權限失敗: \(error)")
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ [AppDelegate] MessagingDelegate token: \(fcmToken ?? "nil")")
        guard let token = fcmToken else { return }
        Task { @MainActor in
            await NotificationService.shared.updateToken(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate（前景推播）

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 前景收到推播時顯示 banner
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        print("📩 [推播收到] title: \(content.title), body: \(content.body), userInfo: \(content.userInfo)")
        handleViolationPayload(content.userInfo)
        return [.banner, .sound, .badge]
    }

    // 使用者點擊推播
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        print("👆 [推播點擊] userInfo: \(userInfo)")
        handleViolationPayload(userInfo)
    }

    // MARK: - Private

    private func handleViolationPayload(_ userInfo: [AnyHashable: Any]) {
        guard let raw = userInfo["violationIds"] as? String else { return }
        let ids = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !ids.isEmpty else { return }
        Task { @MainActor in
            ViolationAlertStore.shared.add(ids: ids)
        }
    }
}

// MARK: - App

@main
struct KindyRadarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isLaunching = true

    init() {
        CacheManager.shared.clearAll()
    }

    var body: some Scene {
        WindowGroup {
            if isLaunching {
                LaunchScreenView()
                    .task {
                        try? await Task.sleep(for: .seconds(1.5))
                        withAnimation(.easeOut(duration: 0.4)) {
                            isLaunching = false
                        }
                    }
            } else {
                MainTabView()
            }
        }
    }
}
