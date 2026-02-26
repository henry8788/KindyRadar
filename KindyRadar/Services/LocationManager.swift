import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let _locationManager = CLLocationManager()

    override init() {
        super.init()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = _locationManager.authorizationStatus
    }

    func requestLocation() {
        switch _locationManager.authorizationStatus {
        case .notDetermined:
            _locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            _locationManager.requestLocation()
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ [LocationManager] 定位失敗：\(error.localizedDescription)")
    }
}
