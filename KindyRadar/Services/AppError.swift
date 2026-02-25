import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case decodingFailed
    case serverError(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:    return "網路連線失敗，請檢查網路設定"
        case .decodingFailed:        return "資料解析失敗，請稍後再試"
        case .serverError(let code): return "伺服器錯誤（\(code)），請稍後再試"
        case .unknown:               return "發生未知錯誤，請稍後再試"
        }
    }
}
