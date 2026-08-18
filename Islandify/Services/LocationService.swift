import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate, LocationSampleProvider {
    private let manager = CLLocationManager()
    private var sink: ((LocationSample) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start(sink: @escaping (LocationSample) -> Void) -> LocationAuthorizationState {
        self.sink = sink
        guard CLLocationManager.locationServicesEnabled() else { return .unavailable }

        switch authorizationState {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            return authorizationState
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .unavailable:
            return .unavailable
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        sink = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard authorizationState.canCollectLocation else { return }
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations where location.horizontalAccuracy >= 0 {
            sink?(LocationSample(
                timestamp: location.timestamp,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                horizontalAccuracy: location.horizontalAccuracy,
                speedMetersPerSecond: location.speed
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // The running session remains usable as a time-only run. The app presents
        // the permission/error message through its model instead of dropping data.
    }

    private var authorizationState: LocationAuthorizationState {
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse: return .authorizedWhenInUse
        case .authorizedAlways: return .authorizedAlways
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unavailable
        }
    }
}
