import Foundation

/// 幼兒教育及照顧法條文摘要對照表
/// 資料來源：全國法規資料庫 https://law.moj.gov.tw
enum LawArticleHelper {

    /// 給定裁罰 law 字串，回傳條文摘要（若查無則回傳 nil）
    static func summary(for lawText: String) -> String? {
        // 抽出條號，例如 "第38條第2項-費用超收..." -> "第38條"
        guard let match = lawText.range(of: #"第\d+條"#, options: .regularExpression) else {
            return nil
        }
        let articleNo = String(lawText[match])
        return articleSummary(for: articleNo)
    }

    // MARK: - 條文摘要（僅列裁罰資料實際用到的條號）

    private static func articleSummary(for no: String) -> String? {
        switch no {
        case "第8條":  return "幼兒園應經主管機關許可設立，並於取得設立許可後，始得招收幼兒進行教保服務。"
        case "第12條": return "教保服務內容規範，包括生理、心理及社會需求滿足之相關服務等。"
        case "第13條": return "主管機關應對身心障礙幼兒主動提供專業團隊，加強早期療育及學前特殊教育相關服務。"
        case "第15條": return "教保服務機構進用教職員工後，應於三十個工作日內報主管機關備查；異動時亦同。"
        case "第16條": return "幼兒園各年齡班級人數限制規定（師生比）。"
        case "第17條": return "幼兒園五歲至入小學前班級，每班應有一人以上為幼兒園教師。"
        case "第20條": return "提供延長照顧服務之人員資格規定。"
        case "第23條": return "教保服務機構之其他服務人員有特定情形者，應予解聘且終身不得再任用。"
        case "第25條": return "有特定情形者，不得擔任教保服務機構之其他服務人員。"
        case "第26條": return "教保服務機構負責人或服務人員知悉違規情形，應依規定通報主管機關。"
        case "第27條": return "主管機關及教保服務機構應依規定辦理通報、資訊蒐集、查詢、處理及利用。"
        case "第28條": return "服務人員因違規經解職者，符合退休條件時應依法給付退休金。"
        case "第29條": return "有特定情形者，不得擔任教保服務機構之負責人或財團法人幼兒園之董事或監察人。"
        case "第30條": return "教保服務機構負責人及服務人員，不得對幼兒有身心虐待、體罰、霸凌、性騷擾或不當對待行為。"
        case "第31條": return "幼兒進出機構時應實施保護措施；幼童專用車接送規定。"
        case "第32條": return "教保服務機構應建立幼兒健康管理制度，並配合主管機關辦理健康檢查。"
        case "第33條": return "教保服務機構應訂定緊急傷病施救步驟及處理措施。"
        case "第34條": return "教保服務機構應依規定辦理幼兒團體保險。"
        case "第37條": return "教保服務機構應公開教保目標、人員資歷、衛生安全措施等相關資訊。"
        case "第38條": return "父母或監護人對教保服務方式有異議時，得請求機構提出說明，機構無正當理由不得拒絕。"
        case "第40條": return "教保服務損及幼兒權益者，父母或監護人得向主管機關提出申訴。"
        case "第41條": return "父母或監護人應依契約繳費、參加相關活動，並遵守機構規定。"
        case "第42條": return "教保服務機構應與父母或監護人訂定書面契約。"
        case "第43條": return "教保服務機構收費項目及用途規定；私立機構不得超收費用。"
        case "第46條": return "主管機關應對教保服務機構辦理檢查、輔導及評鑑，結果應公布於資訊網站。"
        case "第48條": return "兼辦國小兒童課後照顧服務之幼兒園相關規定。"
        default: return nil
        }
    }
}
