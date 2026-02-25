import SwiftUI

@main
struct KindyRadarApp: App {
    init() {
        // 清除舊格式快取，避免版本升級後資料結構不符
        CacheManager.shared.clearAll()
    }

    var body: some Scene {
        WindowGroup {
            PreschoolListView()
        }
    }
}
