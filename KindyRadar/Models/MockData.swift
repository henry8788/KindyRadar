#if DEBUG
extension Preschool {
    static let mockData: [Preschool] = [
        Preschool(
            id: "1",
            name: "愛丁堡幼兒園",
            district: "台中市北屯區",
            fullAddress: "[406] 台中市北屯區文心路四段696號",
            type: .public_,
            quasiPublicPeriod: nil,
            violationStatus: .count(2),
            monthlyFee: 3000,
            principalName: "陳麗娟",
            phone: "(04) 2246-5678",
            approvedCapacity: 120,
            floors: "1 樓、2 樓",
            totalArea: 1280,
            indoorArea: 585.47,
            outdoorArea: 694.53,
            afterSchoolCare: "有 (收托人數: 10)",
            registrationNo1: "中市教特(一)字第1130083341號",
            registrationNo2: "中市教國字第28710號",
            registrationDate: "1996 / 08 / 17",
            latitude: 24.1717,
            longitude: 120.6856,
            violations: [
                Violation(
                    id: "v1",
                    perpetrator: "田書后",
                    date: "2025/10/08",
                    fineAmount: 60000,
                    description: "幼兒教育及照顧法第33條第1項：對幼兒有身心虐待、體罰、霸凌、性騷擾、不當管教，或其他對幼兒之身心暴力或不當對待行為。"
                ),
                Violation(
                    id: "v2",
                    perpetrator: "金郁琳",
                    date: "2024/10/23",
                    fineAmount: 10000,
                    description: "幼兒教育及照顧法第33條第1項：知悉有前二項行為而未依規定通報。"
                )
            ]
        ),
        Preschool(
            id: "2",
            name: "快樂森林幼兒園",
            district: "台北市大安區",
            fullAddress: "[106] 台北市大安區復興南路一段293號",
            type: .quasiPublic,
            quasiPublicPeriod: "113-115",
            violationStatus: .none,
            monthlyFee: 4500,
            principalName: "林美華",
            phone: "(02) 2708-1234",
            approvedCapacity: 80,
            floors: "1 樓",
            totalArea: 850,
            indoorArea: 420,
            outdoorArea: 430,
            afterSchoolCare: "無",
            registrationNo1: "北市教特(一)字第1130012345號",
            registrationNo2: nil,
            registrationDate: "2003 / 03 / 15",
            latitude: 25.0330,
            longitude: 121.5654,
            violations: []
        ),
        Preschool(
            id: "3",
            name: "小哈佛國際幼兒園",
            district: "高雄市左營區",
            fullAddress: "[813] 高雄市左營區博愛三路366號",
            type: .private_,
            quasiPublicPeriod: nil,
            violationStatus: .count(1),
            monthlyFee: 5800,
            principalName: "張偉明",
            phone: "(07) 558-9876",
            approvedCapacity: 150,
            floors: "1 樓、2 樓、3 樓",
            totalArea: 1560,
            indoorArea: 780,
            outdoorArea: 780,
            afterSchoolCare: "有 (收托人數: 25)",
            registrationNo1: "高市教特(一)字第1130056789號",
            registrationNo2: "高市教國字第11230號",
            registrationDate: "1999 / 05 / 20",
            latitude: 22.6803,
            longitude: 120.2972,
            violations: [
                Violation(
                    id: "v3",
                    perpetrator: "王志豪",
                    date: "2025/03/12",
                    fineAmount: 30000,
                    description: "幼兒教育及照顧法第36條第1項：幼兒園之負責人或教保服務人員有違反法令情事。"
                )
            ]
        ),
        Preschool(
            id: "4",
            name: "蒙特梭利學園",
            district: "新竹市東區",
            fullAddress: "[300] 新竹市東區光復路二段101號",
            type: .nonprofit,
            quasiPublicPeriod: nil,
            violationStatus: .none,
            monthlyFee: 2500,
            principalName: "吳雅婷",
            phone: "(03) 572-3456",
            approvedCapacity: 60,
            floors: "1 樓",
            totalArea: 650,
            indoorArea: 350,
            outdoorArea: 300,
            afterSchoolCare: "無",
            registrationNo1: "竹市教特(一)字第1130078901號",
            registrationNo2: nil,
            registrationDate: "2008 / 09 / 01",
            latitude: 24.8138,
            longitude: 120.9675,
            violations: []
        )
    ]
}
#endif
