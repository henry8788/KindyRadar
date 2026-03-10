import SwiftUI
import MapKit

struct PreschoolMapView: View {
    let preschools: [Preschool]

    @ObservedObject var locationManager: LocationManager
    @State private var selectedPreschool: Preschool? = nil
    @State private var showDetail = false
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion? = nil
    @State private var isLoading = true

    private static let maxVisiblePins = 100

    // 只顯示可視範圍內最多 100 筆
    private var visiblePreschools: [Preschool] {
        let mappable = preschools.filter { $0.latitude != nil && $0.longitude != nil }
        guard let region = visibleRegion else {
            return Array(mappable.prefix(Self.maxVisiblePins))
        }
        let filtered = mappable.filter { p in
            let lat = p.latitude!
            let lon = p.longitude!
            let latDelta = region.span.latitudeDelta / 2
            let lonDelta = region.span.longitudeDelta / 2
            return abs(lat - region.center.latitude) <= latDelta &&
                   abs(lon - region.center.longitude) <= lonDelta
        }
        return Array(filtered.prefix(Self.maxVisiblePins))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map

            // 選取幼兒園後顯示底部卡片
            if let preschool = selectedPreschool {
                bottomCard(preschool: preschool)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }

            // Loading overlay
            if isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("地圖載入中...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#64748b"))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.15))
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .navigationTitle("地圖")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            // 定位按鈕
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let loc = locationManager.userLocation {
                        withAnimation {
                            mapPosition = .region(MKCoordinateRegion(
                                center: loc.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
                        }
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color(hex: "#2094f3"))
                }
            }
        }
        .navigationDestination(isPresented: $showDetail) {
            if let preschool = selectedPreschool {
                PreschoolDetailView(preschool: preschool)
                    .onDisappear {
                        selectedPreschool = nil
                    }
            }
        }
        .task {
            // 切入時若位置已有，直接移動地圖
            if let loc = locationManager.userLocation, visibleRegion == nil {
                mapPosition = .region(MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
            // 短暫延遲後隱藏 loading，讓地圖底圖先渲染完
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
            }
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            // 只有第一次拿到位置才自動移動地圖
            guard let loc = newLocation, visibleRegion == nil else { return }
            withAnimation {
                mapPosition = .region(MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }

    // MARK: - 地圖

    private var map: some View {
        Map(position: $mapPosition, selection: $selectedPreschool) {
            // 使用者位置
            UserAnnotation()

            // 幼兒園 pin（只顯示可視範圍內最多 100 筆）
            ForEach(visiblePreschools) { preschool in
                Annotation(preschool.name, coordinate: CLLocationCoordinate2D(
                    latitude: preschool.latitude!,
                    longitude: preschool.longitude!
                ), anchor: .bottom) {
                    pinView(preschool: preschool)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedPreschool = preschool
                            }
                        }
                }
                .tag(preschool)
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .bottom)
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .onTapGesture {
            withAnimation { selectedPreschool = nil }
        }
    }

    // MARK: - Pin 圖示

    private func pinView(preschool: Preschool) -> some View {
        let isClean = preschool.violationStatus.isClean
        let isSelected = selectedPreschool?.id == preschool.id

        return ZStack {
            Circle()
                .fill(isClean ? Color(hex: "#16a34a") : Color(hex: "#e53e3e"))
                .frame(width: isSelected ? 20 : 14, height: isSelected ? 20 : 14)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }

    // MARK: - 底部卡片

    private func bottomCard(preschool: Preschool) -> some View {
        HStack(spacing: 12) {
            // 違規狀態指示條
            RoundedRectangle(cornerRadius: 2)
                .fill(preschool.violationStatus.isClean ? Color(hex: "#16a34a") : Color(hex: "#e53e3e"))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(preschool.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0f172a"))
                    .lineLimit(1)

                Text(preschool.district)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#64748b"))

                HStack(spacing: 6) {
                    // 類型標籤
                    Text(preschool.type.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: preschool.type.tagColor.text))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: preschool.type.tagColor.background))
                        .clipShape(Capsule())

                    // 違規狀態
                    Text(preschool.violationStatus.isClean ? "無裁罰" : "有裁罰 \(preschool.violationStatus.label)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(preschool.violationStatus.isClean ? Color(hex: "#16a34a") : Color(hex: "#e53e3e"))
                }
            }

            Spacer()

            // 進入 Detail
            Button {
                showDetail = true
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: "#2094f3"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .frame(height: 100)
    }
}
