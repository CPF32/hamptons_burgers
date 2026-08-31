import Foundation
import CoreLocation

struct LocationContent: Codable, Equatable {
    struct Coordinates: Codable, Equatable {
        var latitude: Double
        var longitude: Double
    }

    struct HoursEntry: Codable, Equatable, Identifiable {
        var id: String { day }
        let day: String
        var hours: String
    }

    var name: String
    var addressLine1: String
    var addressLine2: String
    var phone: String
    var email: String
    var coordinates: Coordinates
    var hours: [HoursEntry]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }

    var fullAddress: String {
        "\(addressLine1), \(addressLine2)"
    }

    var mapsURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(coordinates.latitude),\(coordinates.longitude)"),
            URLQueryItem(name: "q", value: name)
        ]
        return components?.url
    }
}

struct FAQItem: Codable, Equatable, Identifiable {
    let id: String
    var question: String
    var answer: String
}

struct FAQContent: Codable, Equatable {
    var items: [FAQItem]
}

enum ContentConfig {
    static func loadBundled<T: Decodable>(_ name: String, as type: T.Type) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("Missing or invalid \(name).json in app bundle. Check Resources/Content.")
        }
        return decoded
    }
}
