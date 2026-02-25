import Foundation

// MARK: - 幼兒園類型

enum SchoolType: String, CaseIterable, Identifiable {
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

enum ViolationStatus {
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

struct Preschool: Identifiable {
    let id: String
    let name: String
    let district: String
    let type: SchoolType
    let violationStatus: ViolationStatus
}
