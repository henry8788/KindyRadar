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
        Messaging.messaging().apnsToken = deviceToken
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
                await NotificationService.shared.fetchFCMToken()
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
        guard let token = fcmToken else { return }
        Task { @MainActor in
            NotificationService.shared.fcmToken = token
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
        return [.banner, .sound, .badge]
    }
}

// MARK: - App

@main
struct KindyRadarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        CacheManager.shared.clearAll()
    }

    var body: some Scene {
        WindowGroup {
            PreschoolListView()
        }
    }
}
