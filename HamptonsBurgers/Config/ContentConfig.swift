import Foundation
import CoreLocation

struct LocationContent: Codable, Equatable {
    struct Coordinates: Codable, Equatable {
        let latitude: Double
        let longitude: Double
    }

    struct HoursEntry: Codable, Equatable, Identifiable {
        var id: String { day }
        let day: String
        let hours: String
    }

    let name: String
    let addressLine1: String
    let addressLine2: String
    let phone: String
    let coordinates: Coordinates
    let hours: [HoursEntry]

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
    let question: String
    let answer: String
}

struct FAQContent: Codable, Equatable {
    let items: [FAQItem]
}

enum ContentConfig {
    static let location: LocationContent = load("location", as: LocationContent.self)
    static let faq: FAQContent = load("faq", as: FAQContent.self)

    private static func load<T: Decodable>(_ name: String, as type: T.Type) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("Missing or invalid \(name).json in app bundle. Check Resources/Content.")
        }
        return decoded
    }
}
