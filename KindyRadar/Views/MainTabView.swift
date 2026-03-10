import SwiftUI

struct MainTabView: View {
    @StateObject private var listViewModel = PreschoolListViewModel()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        TabView {
            // 列表 tab
            NavigationStack {
                PreschoolListView(viewModel: listViewModel, locationManager: locationManager)
            }
            .tabItem {
                Label("查詢", systemImage: "list.bullet")
            }

            // 地圖 tab
            NavigationStack {
                PreschoolMapView(preschools: listViewModel.allPreschools, locationManager: locationManager)
            }
            .tabItem {
                Label("地圖", systemImage: "map.fill")
            }
        }
        .tint(Color(hex: "#2094f3"))
        .task {
            locationManager.requestLocation()
        }
    }
}
