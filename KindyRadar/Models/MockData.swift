#if DEBUG
extension Preschool {
    static let mockData: [Preschool] = [
        Preschool(
            id: "1",
            name: "愛丁堡幼兒園",
            district: "台中市北屯區",
            type: .public_,
            violationStatus: .count(2)
        ),
        Preschool(
            id: "2",
            name: "快樂森林幼兒園",
            district: "台北市大安區",
            type: .quasiPublic,
            violationStatus: .none
        ),
        Preschool(
            id: "3",
            name: "小哈佛國際幼兒園",
            district: "高雄市左營區",
            type: .private_,
            violationStatus: .count(1)
        ),
        Preschool(
            id: "4",
            name: "蒙特梭利學園",
            district: "新竹市東區",
            type: .nonprofit,
            violationStatus: .none
        ),
    ]
}
#endif
