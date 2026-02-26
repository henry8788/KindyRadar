import Foundation
import Combine
import CoreLocation

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
    @Published var filterCriteria: FilterCriteria = FilterCriteria()

    var userLocation: CLLocation? = nil {
        didSet { applyFilter() }
    }

    private let _service: PreschoolServiceProtocol
    private var _allPreschools: [Preschool] = []
    private var _cancellables = Set<AnyCancellable>()

    init(service: PreschoolServiceProtocol = PreschoolService()) {
        self._service = service
        setupFiltering()
    }

    // MARK: - 載入資料

    func loadData() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            _allPreschools = try await _service.fetchPreschools()
            applyFilter(ignoreLoadingState: true)
        } catch let error as AppError {
            print("❌ [ViewModel] loadData error: \(error.errorDescription ?? "")")
            state = .error(error.errorDescription ?? "發生未知錯誤")
        } catch {
            print("❌ [ViewModel] loadData unknown error: \(error)")
            state = .error(AppError.unknown.errorDescription!)
        }
    }

    func refresh() async {
        state = .loading
        do {
            _allPreschools = try await _service.fetchPreschools()
            applyFilter(ignoreLoadingState: true)
        } catch let error as AppError {
            state = .error(error.errorDescription ?? "發生未知錯誤")
        } catch {
            state = .error(AppError.unknown.errorDescription!)
        }
    }

    func applyFilterCriteria(_ criteria: FilterCriteria) {
        filterCriteria = criteria
        selectedType = criteria.schoolType
        applyFilter()
    }

    // MARK: - 篩選邏輯

    private func setupFiltering() {
        Publishers.CombineLatest3($searchText, $selectedType, $filterCriteria)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in self?.applyFilter() }
            .store(in: &_cancellables)
    }

    private func applyFilter(ignoreLoadingState: Bool = false) {
        if !ignoreLoadingState, case .loading = state { return }
        var result = _allPreschools

        if selectedType != .all {
            result = result.filter { $0.type == selectedType }
        }

        if filterCriteria.city != .all {
            result = result.filter { $0.district.hasPrefix(filterCriteria.city.rawValue) }
        }

        if !filterCriteria.district.isEmpty {
            let expected = filterCriteria.city.rawValue + filterCriteria.district
            result = result.filter { $0.district == expected }
        }

        switch filterCriteria.penaltyFilter {
        case .all:
            break
        case .clean:
            result = result.filter { $0.violationStatus.isClean }
        case .hasViolation:
            result = result.filter { !$0.violationStatus.isClean }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.contains(searchText) || $0.district.contains(searchText)
            }
        }

        // 有使用者位置時，依距離由近到遠排序
        if let location = userLocation {
            result = result.sorted { a, b in
                let distA = a.distance(from: location)
                let distB = b.distance(from: location)
                // 沒有座標的排到最後
                switch (distA, distB) {
                case let (da?, db?): return da < db
                case (_?, nil):     return true
                case (nil, _?):     return false
                case (nil, nil):    return false
                }
            }
        }

        state = result.isEmpty ? .empty : .success(result)
    }

    // MARK: - Computed

    var resultCountText: String {
        guard case .success(let items) = state else { return "" }
        let formatted = NumberFormatter.localizedString(
            from: NSNumber(value: items.count),
            number: .decimal
        )
        return "顯示 \(formatted) 筆幼兒園"
    }

    var hasActiveFilter: Bool {
        !filterCriteria.isDefault
    }
}
