import Foundation
import CoreWLAN
import CoreLocation

struct LocationAccessState {
    let servicesEnabled: Bool
    let authorizationStatus: CLAuthorizationStatus

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways
    }

    var summary: String {
        if !servicesEnabled {
            return "disabled"
        }

        switch authorizationStatus {
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "unknown"
        }
    }
}

private final class LocationAuthorizationRequester: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestAccessIfNeeded(timeout: TimeInterval = 3.0) -> LocationAccessState {
        guard CLLocationManager.locationServicesEnabled() else {
            return LocationAccessState(servicesEnabled: false, authorizationStatus: currentStatus())
        }

        guard currentStatus() == .notDetermined else {
            return LocationAccessState(servicesEnabled: true, authorizationStatus: currentStatus())
        }

        locationManager.requestAlwaysAuthorization()

        let deadline = Date().addingTimeInterval(timeout)
        while currentStatus() == .notDetermined && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }

        return LocationAccessState(servicesEnabled: true, authorizationStatus: currentStatus())
    }

    private func currentStatus() -> CLAuthorizationStatus {
        if #available(macOS 11.0, *) {
            return locationManager.authorizationStatus
        }

        return CLLocationManager.authorizationStatus()
    }
}

func requestLocationAccessIfNeeded(timeout: TimeInterval = 3.0) -> LocationAccessState {
    let requester = LocationAuthorizationRequester()
    return requester.requestAccessIfNeeded(timeout: timeout)
}

func networkFieldValue(_ value: String?, placeholder: String) -> String {
    guard let value, !value.isEmpty else {
        return placeholder
    }

    return value
}

func networkIdentifiersUnavailable(_ network: CWNetwork) -> Bool {
    let ssidUnavailable = network.ssid?.isEmpty != false
    let bssidUnavailable = network.bssid?.isEmpty != false
    return ssidUnavailable && bssidUnavailable
}

func scanNetworks(_ interface: CWInterface, name: String? = nil) throws -> Set<CWNetwork> {
    if #available(macOS 10.13, *) {
        return try interface.scanForNetworks(withName: name, includeHidden: true)
    } else {
        return try interface.scanForNetworks(withName: name)
    }
}
