import Foundation

struct Violation: Identifiable, Codable, Hashable {
    let id: String
    let perpetrator: String   // 行為人
    let date: String          // 裁罰日期
    let fineAmount: Int       // 罰鍰金額（元）
    let description: String   // 違規說明
}
