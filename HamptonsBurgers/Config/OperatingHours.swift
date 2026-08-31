import Foundation

enum OperatingHours {
    private static let timeZone = TimeZone(identifier: "America/Denver")!
    private static let dayNames = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    /// Updated when remote app config changes; defaults to bundled hours at launch.
    static var locationHours: [LocationContent.HoursEntry] = AppContent.bundled().location.hours

    static var isOpen: Bool {
        isOpen(at: Date())
    }

    static func isOpen(at date: Date) -> Bool {
        openInterval(containing: date) != nil
    }

    static var formattedNextOpening: String {
        formattedNextOpening(after: Date())
    }

    static func formattedNextOpening(after date: Date) -> String {
        formattedNextOpening(from: nextOpening(after: date))
    }

    /// Next scheduled open time strictly after today — for admin “closed today” notices.
    static func formattedNextOpeningAfterToday(after date: Date) -> String {
        formattedNextOpening(from: nextOpening(after: date, skipToday: true))
    }

    private static func formattedNextOpening(from next: Date?) -> String {
        guard let next else { return "soon" }

        let calendar = calendar()
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US")
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: next)

        if calendar.isDateInToday(next) {
            return "today at \(timeString)"
        }
        if calendar.isDateInTomorrow(next) {
            return "tomorrow at \(timeString)"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "EEEE, MMMM d"
        return "\(dateFormatter.string(from: next)) at \(timeString)"
    }

    static var closedOrderMessage: String {
        closedOrderMessage(at: Date())
    }

    static func closedOrderMessage(at date: Date) -> String {
        "Sorry, we are currently closed. We will be ready to serve you Gypsum's best smash burger \(formattedNextOpening(after: date))."
    }

    private static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func openInterval(containing date: Date) -> DateInterval? {
        let calendar = calendar()
        let weekday = calendar.component(.weekday, from: date)
        guard let dayHours = hours(forWeekday: weekday),
              let open = combine(date: date, timeString: dayHours.open, calendar: calendar),
              let close = combine(date: date, timeString: dayHours.close, calendar: calendar),
              date >= open, date < close else {
            return nil
        }
        return DateInterval(start: open, end: close)
    }

    private static func nextOpening(after date: Date, skipToday: Bool = false) -> Date? {
        let calendar = calendar()
        let startOfToday = calendar.startOfDay(for: date)
        let startOffset = skipToday ? 1 : 0

        for dayOffset in startOffset..<8 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: day)
            guard let dayHours = hours(forWeekday: weekday),
                  let open = combine(date: day, timeString: dayHours.open, calendar: calendar) else {
                continue
            }

            if dayOffset == 0 {
                if date < open {
                    return open
                }
                continue
            }

            return open
        }

        return nil
    }

    private static func hours(forWeekday weekday: Int) -> (open: String, close: String)? {
        let dayName = dayNames[weekday - 1]
        guard let entry = locationHours.first(where: { $0.day == dayName }) else {
            return nil
        }

        let normalized = entry.hours
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
        let parts = normalized.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              !parts[0].lowercased().contains("closed"),
              !parts[1].lowercased().contains("closed") else {
            return nil
        }

        return (open: parts[0], close: parts[1])
    }

    private static func combine(date: Date, timeString: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"

        guard let parsedTime = formatter.date(from: timeString) else { return nil }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0
        return calendar.date(from: components)
    }
}
