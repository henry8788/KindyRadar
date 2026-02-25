---
name: kindyradar-dev
description: KindyRadar iOS 程式碼開發規範。當需要寫 Swift 程式碼、新增功能、修復 bug 時使用。
---

# KindyRadar 開發規範

## 新功能開發流程

### Step 1 — 定義 Model + Service Protocol
```swift
struct Preschool: Codable, Identifiable {
    let id: String
    let name: String
    let city: String
}

protocol PreschoolServiceProtocol {
    func fetchPreschools() async throws -> [Preschool]
    func fetchViolations() async throws -> [Violation]
}
```

### Step 2 — 實作 MockService（先做 UI）
```swift
#if DEBUG
class MockPreschoolService: PreschoolServiceProtocol {
    func fetchPreschools() async throws -> [Preschool] { return Preschool.mockData }
    func fetchViolations() async throws -> [Violation] { return [] }
}

class MockEmptyService: PreschoolServiceProtocol {
    func fetchPreschools() async throws -> [Preschool] { return [] }
    func fetchViolations() async throws -> [Violation] { return [] }
}

class MockErrorService: PreschoolServiceProtocol {
    func fetchPreschools() async throws -> [Preschool] { throw AppError.networkUnavailable }
    func fetchViolations() async throws -> [Violation] { throw AppError.networkUnavailable }
}

extension Preschool {
    static let mockData: [Preschool] = [
        Preschool(id: "1", name: "陽光幼兒園", city: "台北市"),
        Preschool(id: "2", name: "快樂幼兒園", city: "台中市"),
        Preschool(id: "3", name: "彩虹幼兒園", city: "高雄市")
    ]
}
#endif
```

### Step 3 — 實作 ViewModel 商業邏輯
完成搜尋、篩選、錯誤處理後再往下。

### Step 4 — 實作 RealService 串接 API
```swift
// 只換 Service，ViewModel 和 UI 完全不動
class PreschoolService: PreschoolServiceProtocol {
    func fetchPreschools() async throws -> [Preschool] {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Preschool].self, from: data)
    }
}
```

---

## 設計模式

### Protocol-Oriented + Dependency Injection
```swift
@MainActor
class PreschoolListViewModel: ObservableObject {
    private let service: PreschoolServiceProtocol

    init(service: PreschoolServiceProtocol = PreschoolService()) {
        self.service = service
    }
}
```

### Repository Pattern
Service 層同時負責網路請求和快取，ViewModel 不管快取細節：
```swift
class PreschoolService: PreschoolServiceProtocol {
    private let cache = CacheManager.shared

    func fetchPreschools() async throws -> [Preschool] {
        if let cached = cache.get("preschools") { return cached }
        let data = try await fetchFromAPI()
        cache.set("preschools", data, ttl: 86400)
        return data
    }
}
```

### Singleton（快取管理）
```swift
class CacheManager {
    static let shared = CacheManager()
    private init() {}

    func get(_ key: String) -> [Preschool]? { ... }
    func set(_ key: String, _ data: [Preschool], ttl: TimeInterval) { ... }
}
```

### Observer（Combine）
```swift
// 搜尋防抖
$searchText
    .debounce(for: 0.3, scheduler: RunLoop.main)
    .sink { [weak self] text in self?.performSearch(text) }
    .store(in: &cancellables)

// 多條件篩選
Publishers.CombineLatest($searchText, $selectedCity)
    .map { search, city in self.filterItems(search: search, city: city) }
    .assign(to: &$filteredItems)
```

---

## 錯誤處理統一格式

### 定義 AppError
```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case decodingFailed
    case serverError(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:    return "網路連線失敗，請檢查網路設定"
        case .decodingFailed:        return "資料解析失敗，請稍後再試"
        case .serverError(let code): return "伺服器錯誤（\(code)），請稍後再試"
        case .unknown:               return "發生未知錯誤，請稍後再試"
        }
    }
}
```

### ViewModel 統一用 AppError
```swift
func loadData() async {
    state = .loading
    do {
        let result = try await service.fetchPreschools()
        state = result.isEmpty ? .empty : .success(result)
    } catch is URLError {
        state = .error(AppError.networkUnavailable)
    } catch {
        state = .error(AppError.unknown)
    }
}
```

---

## Loading State

### 定義 ViewState
```swift
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case empty
    case error(AppError)
}
```

### ViewModel 使用
```swift
@MainActor
class PreschoolListViewModel: ObservableObject {
    @Published var state: ViewState<[Preschool]> = .idle
    private let service: PreschoolServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: PreschoolServiceProtocol = PreschoolService()) {
        self.service = service
    }
}
```

### View 對應五種狀態
```swift
var body: some View {
    switch viewModel.state {
    case .idle:
        Color.clear
    case .loading:
        ProgressView("載入中...")
    case .success(let preschools):
        PreschoolListContent(preschools: preschools)
    case .empty:
        ContentUnavailableView("找不到幼兒園", systemImage: "magnifyingglass")
    case .error(let error):
        ErrorView(message: error.errorDescription ?? "發生錯誤")
    }
}
```

---

## Concurrency — 用 async/await
```swift
// ✅ 正確
func loadData() async throws -> [Item] {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Item].self, from: data)
}

// ✅ 並行請求
async let preschools = fetchPreschools()
async let violations = fetchViolations()
let results = try await (preschools, violations)

// ❌ 禁止
DispatchQueue.global().async { }
DispatchQueue.main.async { }
DispatchGroup()
```

---

## SwiftUI 規範

### @StateObject + .task
```swift
// ✅ 正確
@StateObject private var viewModel = ListViewModel()
.task { await viewModel.loadData() }

// ❌ 禁止
@ObservedObject var viewModel = ListViewModel()
.onAppear { Task { await viewModel.loadData() } }
```

### Preview — 每個 View 必寫三種狀態
```swift
#Preview("正常資料") {
    PreschoolListView()
        .environmentObject(PreschoolListViewModel(service: MockPreschoolService()))
}

#Preview("空資料") {
    PreschoolListView()
        .environmentObject(PreschoolListViewModel(service: MockEmptyService()))
}

#Preview("錯誤狀態") {
    PreschoolListView()
        .environmentObject(PreschoolListViewModel(service: MockErrorService()))
}
```

---

## 命名規則
- `camelCase` — 變數、函式
- `PascalCase` — 型別、struct
- `_camelCase` — private 屬性
- 優先使用 `guard let`，避免巢狀 `if let`

## UI 文字規範
```swift
// ✅ 正確
Text("搜尋幼兒園")
.navigationTitle("裁罰記錄")
.searchable(text: $searchText, prompt: "輸入名稱或地址")
errorMessage = "載入失敗，請檢查網路連線"

// ❌ 禁止
Text("Search")
errorMessage = "Load failed"
```