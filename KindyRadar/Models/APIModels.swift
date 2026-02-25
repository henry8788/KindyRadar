import Foundation

// MARK: - preschools.json (GeoJSON)

struct PreschoolGeoJSON: Decodable {
    let features: [PreschoolFeature]
}

struct PreschoolFeature: Decodable {
    let properties: PreschoolProperties
    let geometry: PreschoolGeometry?
}

struct PreschoolGeometry: Decodable {
    let coordinates: [Double]   // [longitude, latitude]

    enum CodingKeys: String, CodingKey {
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var coordsContainer = try container.nestedUnkeyedContainer(forKey: .coordinates)
        var coords: [Double] = []
        while !coordsContainer.isAtEnd {
            if let value = try? coordsContainer.decode(Double.self) {
                coords.append(value)
            } else if let str = try? coordsContainer.decode(String.self),
                      let value = Double(str) {
                coords.append(value)
            } else {
                _ = try? coordsContainer.decode(String.self)
            }
        }
        self.coordinates = coords
    }
}

struct PreschoolProperties: Decodable {
    let id: String
    let title: String
    let owner: String?
    let city: String
    let town: String
    let type: String            // "公立" / "私立" / "準公共" / "非營利"
    let address: String
    let floor: String?
    let size: String?
    let sizeIn: String?
    let sizeOut: String?
    let tel: String?
    let countApproved: String?
    let prePublic: String?      // 準公共化期間，如 "113-115"
    let isAfter: String?        // 課後留園，如 "有，人數：10"
    let penalty: String?        // "有" / "無"
    let monthly: FlexibleInt?
    let regNo: String?
    let regDocno: String?
    let regDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, owner, city, town, type, address, floor
        case size, tel, penalty, monthly
        case sizeIn       = "size_in"
        case sizeOut      = "size_out"
        case countApproved = "count_approved"
        case prePublic    = "pre_public"
        case isAfter      = "is_after"
        case regNo        = "reg_no"
        case regDocno     = "reg_docno"
        case regDate      = "reg_date"
    }
}

// MARK: - punish_all.json
// 結構：{ "行為人：田書后": [ { date, law, punishment, id }, ... ], ... }

typealias PunishAllJSON = [String: [PunishRecord]]

// MARK: - FlexibleInt（同時接受 Int 和 String 型別的數字）

struct FlexibleInt: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let strValue = try? container.decode(String.self),
                  let intValue = Int(strValue) {
            value = intValue
        } else {
            value = 0
        }
    }
}

struct PunishRecord: Decodable {
    let date: String
    let law: String
    let punishment: String  // "罰鍰：60,000元"
    let id: String          // preschool UUID
}
