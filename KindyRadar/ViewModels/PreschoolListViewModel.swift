import Foundation
import Combine

// MARK: - ViewState

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case empty
    case error(String)
}

// MARK: - ViewModel

@MainActor
class PreschoolListViewModel: ObservableObject {
    @Published var state: ViewState<[Preschool]> = .idle
    @Published var searchText: String = ""
    @Published var selectedType: SchoolType = .all

    private var _allPreschools: [Preschool] = []
    private var _cancellables = Set<AnyCancellable>()

    init() {
        setupFiltering()
    }

    // MARK: - 載入資料（目前使用 Mock）

    func loadData() async {
        guard case .idle = state else { return }
        state = .loading

        // TODO: 替換為 RealService
        try? await Task.sleep(nanoseconds: 500_000_000)
        #if DEBUG
        _allPreschools = Preschool.mockData
        #else
        _allPreschools = []
        #endif

        applyFilter()
    }

    func refresh() async {
        state = .loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        applyFilter()
    }

    // MARK: - 篩選邏輯

    private func setupFiltering() {
        Publishers.CombineLatest($searchText, $selectedType)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _, _ in self?.applyFilter() }
            .store(in: &_cancellables)
    }

    private func applyFilter() {
        var result = _allPreschools

        if selectedType != .all {
            result = result.filter { $0.type == selectedType }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.contains(searchText) || $0.district.contains(searchText)
            }
        }

        state = result.isEmpty ? .empty : .success(result)
    }

    var resultCountText: String {
        guard case .success(let items) = state else { return "" }
        let formatted = NumberFormatter.localizedString(
            from: NSNumber(value: items.count),
            number: .decimal
        )
        return "顯示 \(formatted) 筆幼兒園"
    }
}
