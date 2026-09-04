import CoreLocation
import Foundation

/// 获取 Mac 当前地点，并把经纬度转换成容易阅读的城市、区域名称。
@MainActor
final class LocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var placeName = "地点获取中"
    @Published private(set) var isLocating = true

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func begin() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorized, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
            placeName = "未允许获取地点"
        @unknown default:
            isLocating = false
            placeName = "地点不可用"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        begin()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            do {
                let marks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "zh_CN"))
                guard let mark = marks.first else {
                    placeName = coordinateText(location)
                    isLocating = false
                    return
                }
                let pieces = [mark.administrativeArea, mark.locality, mark.subLocality]
                    .compactMap { $0 }
                    .reduce(into: [String]()) { result, item in
                        if !result.contains(item) { result.append(item) }
                    }
                placeName = pieces.isEmpty ? coordinateText(location) : pieces.joined(separator: " ")
                isLocating = false
            } catch {
                placeName = coordinateText(location)
                isLocating = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            placeName = "地点暂时不可用"
            isLocating = false
        }
    }

    private func coordinateText(_ location: CLLocation) -> String {
        String(format: "北纬 %.4f，东经 %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }
}
