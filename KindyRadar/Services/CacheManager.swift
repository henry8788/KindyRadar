import Foundation

/// 基於 FileManager 的 24 小時磁碟快取
final class CacheManager {
    static let shared = CacheManager()
    private init() {}

    private let ttl: TimeInterval = 86400   // 24 小時
    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KindyRadarCache", isDirectory: true)
    }

    // MARK: - 讀取

    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        let metaURL = cacheDirectory.appendingPathComponent("\(key).meta")

        // 檢查過期
        guard
            let metaData = try? Data(contentsOf: metaURL),
            let savedDate = try? JSONDecoder().decode(Date.self, from: metaData),
            Date().timeIntervalSince(savedDate) < ttl
        else { return nil }

        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode(type, from: data)
        else { return nil }

        return decoded
    }

    // MARK: - 寫入

    func save<T: Encodable>(_ value: T, key: String) {
        createDirectoryIfNeeded()

        let fileURL = cacheDirectory.appendingPathComponent(key)
        let metaURL = cacheDirectory.appendingPathComponent("\(key).meta")

        guard
            let data = try? JSONEncoder().encode(value),
            let metaData = try? JSONEncoder().encode(Date())
        else { return }

        try? data.write(to: fileURL, options: .atomic)
        try? metaData.write(to: metaURL, options: .atomic)
    }

    // MARK: - 清除

    func clear(key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        let metaURL = cacheDirectory.appendingPathComponent("\(key).meta")
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: metaURL)
    }

    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }

    // MARK: - Private

    private func createDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: cacheDirectory.path) else { return }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
