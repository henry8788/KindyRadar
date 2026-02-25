import Foundation

// MARK: - 縣市

enum City: String, CaseIterable, Identifiable {
    case all = "全部"
    case taipei = "台北市"
    case newTaipei = "新北市"
    case taichung = "台中市"
    case tainan = "台南市"
    case kaohsiung = "高雄市"
    case taoyuan = "桃園市"
    case hsinchu = "新竹市"
    case keelung = "基隆市"
    case chiayi = "嘉義市"

    var id: String { rawValue }
}

// MARK: - 裁罰狀態

enum PenaltyFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case clean = "無裁罰記錄"
    case hasViolation = "有裁罰記錄"

    var id: String { rawValue }
}

// MARK: - 篩選條件

struct FilterCriteria: Equatable {
    var city: City = .all
    var schoolType: SchoolType = .all
    var penaltyFilter: PenaltyFilter = .all

    var isDefault: Bool {
        city == .all && schoolType == .all && penaltyFilter == .all
    }
}
