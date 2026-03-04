import Foundation
import FirebaseFirestore

// MARK: - Firestore 裁罰資料結構

struct FirestoreViolation: Identifiable {
    let id: String
    let schoolName: String   // 原始（含縣市前綴，如「桃園市私立甜蘋果幼兒園」）
    let law: String
    let date: String
    let punishment: String
    let createdAt: Date
}

// MARK: - 比對結果

struct NewViolationItem: Identifiable {
    let id: String           // Firestore doc id
    let preschool: Preschool
    let law: String
    let date: String
    let punishment: String
}

// MARK: - ViewModel

@MainActor
class ViolationAlertViewModel: ObservableObject {
    @Published var items: [NewViolationItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let _db = Firestore.firestore()

    /// allPreschools：從 PreschoolListViewModel 傳入，用於比對
    func load(allPreschools: [Preschool]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1. 拉全部資料，在 Swift 端用 date 字串篩近三個月
            let snapshot = try await _db
                .collection("violations")
                .getDocuments()

            print("📋 [ViolationAlert] Firestore 全部共 \(snapshot.documents.count) 筆")

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()

            // 2. 解析成 FirestoreViolation，並篩近三個月
            let firestoreViolations: [FirestoreViolation] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard
                    let school = data["school"] as? String,
                    let law = data["law"] as? String,
                    let dateStr = data["date"] as? String,
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                else { return nil }

                // 篩近三個月（用裁罰日期判斷）
                if let violationDate = dateFormatter.date(from: dateStr), violationDate < threeMonthsAgo {
                    return nil
                }

                let punishment = data["punishment"] as? String ?? ""
                return FirestoreViolation(
                    id: doc.documentID,
                    schoolName: school,
                    law: law,
                    date: dateStr,
                    punishment: punishment,
                    createdAt: createdAt
                )
            }

            // 依裁罰日期新→舊排序
            let sorted = firestoreViolations.sorted {
                $0.date > $1.date
            }

            print("📋 [ViolationAlert] 近三個月共 \(sorted.count) 筆")

            // 3. 比對 App 幼兒園清單
            var result: [NewViolationItem] = []
            for fv in sorted {
                // 用 contains 比對（Firestore 名稱含縣市前綴，App 名稱不含）
                guard let preschool = allPreschools.first(where: { fv.schoolName.contains($0.name) }) else {
                    // App 端沒有這間幼兒園 → 過濾掉
                    continue
                }
                // App 端有這間，但這筆裁罰 App 沒有 → 新裁罰
                let alreadyExists = preschool.violations.contains { $0.date == fv.date && $0.description.contains(fv.law) }
                if !alreadyExists {
                    result.append(NewViolationItem(
                        id: fv.id,
                        preschool: preschool,
                        law: fv.law,
                        date: fv.date,
                        punishment: fv.punishment
                    ))
                }
            }

            print("✅ [ViolationAlert] 比對後新裁罰 \(result.count) 筆")
            items = result

        } catch {
            print("❌ [ViolationAlert] 查詢失敗: \(error)")
            errorMessage = "載入失敗，請稍後再試"
        }
    }
}
