import Foundation
import CoreLocation

// MARK: - 幼兒園類型

enum SchoolType: String, CaseIterable, Identifiable, Codable {
    case all = "全部"
    case public_ = "公立"
    case quasiPublic = "準公共化"
    case private_ = "私立"
    case nonprofit = "非營利"

    var id: String { rawValue }

    var tagColor: (background: String, text: String) {
        switch self {
        case .all:         return ("#f1f5f9", "#475569")
        case .public_:     return ("#dcfce7", "#15803d")
        case .quasiPublic: return ("#ccfbf1", "#0f766e")
        case .private_:    return ("#dbeafe", "#1d4ed8")
        case .nonprofit:   return ("#ffedd5", "#c2410c")
        }
    }
}

// MARK: - 違規狀態

enum ViolationStatus: Codable {
    case none
    case count(Int)

    var label: String {
        switch self {
        case .none:           return "無違規"
        case .count(let n):   return "\(n)筆"
        }
    }

    var isClean: Bool {
        if case .none = self { return true }
        return false
    }
}

// MARK: - 幼兒園

struct Preschool: Identifiable, Codable {
    let id: String
    let name: String
    let district: String
    let fullAddress: String
    let type: SchoolType
    let quasiPublicPeriod: String?    // 準公共化期間，如 "113-115"
    let violationStatus: ViolationStatus

    // 基本資訊
    let monthlyFee: Int?              // 每月學費
    let principalName: String?        // 負責人
    let phone: String?                // 聯絡電話

    // 設施規模
    let approvedCapacity: Int?        // 核定人數
    let floors: String?               // 樓層資訊
    let totalArea: Double?            // 總面積（平方公尺）
    let indoorArea: Double?           // 室內面積
    let outdoorArea: Double?          // 室外面積
    let afterSchoolCare: String?      // 課後留園

    // 核准立案
    let registrationNo1: String?      // 文號（一）
    let registrationNo2: String?      // 文號（二）
    let registrationDate: String?     // 立案日期

    // 地理座標
    let latitude: Double?             // 緯度
    let longitude: Double?            // 經度

    // 裁罰記錄
    let violations: [Violation]

    /// 回傳與使用者位置的距離（公尺），若無座標則為 nil
    func distance(from userLocation: CLLocation) -> Double? {
        guard let lat = latitude, let lon = longitude else { return nil }
        let location = CLLocation(latitude: lat, longitude: lon)
        return userLocation.distance(from: location)
    }
}
