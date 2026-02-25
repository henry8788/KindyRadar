import Foundation

final class PreschoolService: PreschoolServiceProtocol {
    private let cache = CacheManager.shared
    private let cacheKey = "preschools_v1"

    private let preschoolsURL = URL(string: "https://kiang.github.io/ap.ece.moe.edu.tw/preschools.json")!
    private let punishURL     = URL(string: "https://kiang.github.io/ap.ece.moe.edu.tw/punish_all.json")!

    // MARK: - Public

    func fetchPreschools() async throws -> [Preschool] {
        // 快取命中直接回傳
        if let cached = cache.load([Preschool].self, key: cacheKey) {
            print("✅ [PreschoolService] 快取命中，\(cached.count) 筆")
            return cached
        }
        print("🌐 [PreschoolService] 快取未命中，從 API 拉取...")
        cache.clear(key: cacheKey)

        // 並行拉取兩支 API
        async let geoJSONData   = fetch(from: preschoolsURL)
        async let punishAllData = fetch(from: punishURL)

        let (rawPreschools, rawPunish) = try await (geoJSONData, punishAllData)

        // 解析
        let geoJSON: PreschoolGeoJSON
        let punishAll: PunishAllJSON
        do {
            geoJSON   = try JSONDecoder().decode(PreschoolGeoJSON.self, from: rawPreschools)
            punishAll = try JSONDecoder().decode(PunishAllJSON.self, from: rawPunish)
        } catch {
            print("❌ [PreschoolService] Decode error: \(error)")
            throw AppError.decodingFailed
        }

        // 建立裁罰記錄索引：[preschool UUID: [Violation]]
        let violationIndex = buildViolationIndex(from: punishAll)

        // 轉換成 App model
        let preschools = geoJSON.features.compactMap { feature -> Preschool? in
            map(feature: feature, violations: violationIndex[feature.properties.id] ?? [])
        }

        print("✅ [PreschoolService] 載入 \(preschools.count) 筆幼兒園")
        cache.save(preschools, key: cacheKey)
        return preschools
    }

    // MARK: - Private — 網路請求

    private func fetch(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.unknown
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.serverError(httpResponse.statusCode)
            }
            return data
        } catch let error as AppError {
            throw error
        } catch let urlError as URLError {
            print("❌ [PreschoolService] URLError: \(urlError)")
            throw AppError.networkUnavailable
        } catch let unknownError {
            print("❌ [PreschoolService] Unknown error: \(unknownError)")
            throw AppError.unknown
        }
    }

    // MARK: - Private — 建立違規索引

    private func buildViolationIndex(from punishAll: PunishAllJSON) -> [String: [Violation]] {
        var index: [String: [Violation]] = [:]

        for (perpetratorKey, records) in punishAll {
            // key 格式：「行為人：田書后」或「負責人：陳麗娟」
            let perpetrator = perpetratorKey
                .replacingOccurrences(of: "行為人：", with: "")
                .replacingOccurrences(of: "負責人：", with: "")

            for record in records {
                let violation = Violation(
                    id: "\(record.id)-\(record.date)-\(perpetrator)",
                    perpetrator: perpetrator,
                    date: record.date,
                    fineAmount: parseFine(from: record.punishment),
                    description: record.law
                )

                index[record.id, default: []].append(violation)
            }
        }

        // 每個學校的違規依日期由新到舊排序
        return index.mapValues { violations in
            violations.sorted { $0.date > $1.date }
        }
    }

    // MARK: - Private — 解析罰鍰金額
    // 格式：「罰鍰：60,000元」→ 60000

    private func parseFine(from punishment: String) -> Int {
        let digits = punishment
            .components(separatedBy: "：").last ?? ""
        let cleaned = digits
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "元", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Int(cleaned) ?? 0
    }

    // MARK: - Private — Feature → Preschool

    private func map(feature: PreschoolFeature, violations: [Violation]) -> Preschool? {
        let p = feature.properties
        guard !p.id.isEmpty, !p.title.isEmpty else { return nil }

        let schoolType = parseSchoolType(p.type, prePublic: p.prePublic)
        let violationStatus: ViolationStatus = violations.isEmpty ? .none : .count(violations.count)

        return Preschool(
            id: p.id,
            name: p.title,
            district: "\(p.city)\(p.town)",
            fullAddress: p.address,
            type: schoolType,
            quasiPublicPeriod: p.prePublic,
            violationStatus: violationStatus,
            monthlyFee: p.monthly?.value,
            principalName: p.owner,
            phone: p.tel,
            approvedCapacity: Int(p.countApproved ?? ""),
            floors: p.floor,
            totalArea: parseArea(p.size),
            indoorArea: parseArea(p.sizeIn),
            outdoorArea: parseArea(p.sizeOut),
            afterSchoolCare: p.isAfter,
            registrationNo1: p.regNo,
            registrationNo2: p.regDocno,
            registrationDate: p.regDate?.replacingOccurrences(of: "/", with: " / "),
            violations: violations
        )
    }

    // MARK: - Private — 解析類型

    private func parseSchoolType(_ raw: String, prePublic: String?) -> SchoolType {
        // 有準公共化期間的私立園 → 準公共化
        if let period = prePublic, !period.isEmpty {
            return .quasiPublic
        }
        switch raw {
        case "公立":   return .public_
        case "私立":   return .private_
        case "非營利": return .nonprofit
        default:       return .private_
        }
    }

    // MARK: - Private — 解析面積
    // 格式：「585.47平方公尺」或「1,280平方公尺」

    private func parseArea(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let cleaned = raw
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "平方公尺", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

