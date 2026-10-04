import Foundation

struct StoreStatus: Codable, Equatable {
    var isOffDay: Bool
    var isSoldOutForDay: Bool
    var isSoldOutForWeek: Bool
    var dailyPattyCount: Int
    var dailyPattyCapacity: Int
    var noticeTitle: String
    var noticeBody: String
    var orderClosedMessage: String
    var updatedAt: Date

    static let `default` = StoreStatus(
        isOffDay: false,
        isSoldOutForDay: false,
        isSoldOutForWeek: false,
        dailyPattyCount: BrandConfig.defaultDailyPattyCapacity,
        dailyPattyCapacity: BrandConfig.defaultDailyPattyCapacity,
        noticeTitle: "",
        noticeBody: "",
        orderClosedMessage: "",
        updatedAt: Date()
    )

    /// Shown when sold out for the whole week — always Tuesday (start of the week).
    static let soldOutForWeekMessage = "Sorry, we've sold out for the week. Check back Tuesday at 11:00 AM."

    /// Shown when sold out for just today — points to the next day we're open.
    static func soldOutForDayMessage(at date: Date = Date()) -> String {
        "Sorry, we've sold out for today. Check back \(OperatingHours.formattedNextOpeningAfterToday(after: date))."
    }

    static func offDayMessage(at date: Date = Date()) -> String {
        "Sorry, we're closed today. Check back \(OperatingHours.formattedNextOpeningAfterToday(after: date))."
    }

    var isEffectivelySoldOutForDay: Bool {
        isSoldOutForDay || dailyPattyCount <= 0
    }

    var isEffectivelySoldOutForWeek: Bool {
        isSoldOutForWeek
    }

    var isEffectivelySoldOut: Bool {
        isEffectivelySoldOutForWeek || isEffectivelySoldOutForDay
    }

    var fuelLevel: Double {
        guard dailyPattyCapacity > 0 else { return 0 }
        return min(1, max(0, Double(dailyPattyCount) / Double(dailyPattyCapacity)))
    }

    var hasNotice: Bool {
        !noticeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !noticeBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayNoticeTitle: String {
        let trimmed = noticeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Notice" : trimmed
    }

    /// Off day, sold-out flags, or zero patties for the day — drives the automatic status banner.
    var showsStatusBanner: Bool {
        isOffDay || isEffectivelySoldOut
    }

    var statusBannerTitle: String {
        if isOffDay { return "Closed Today" }
        if isEffectivelySoldOutForWeek { return "Sold Out This Week" }
        return "Sold Out Today"
    }

    func statusBannerMessage(at date: Date = Date()) -> String {
        let trimmedClosedMessage = orderClosedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNoticeBody = noticeBody.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedClosedMessage.isEmpty { return trimmedClosedMessage }
        if !trimmedNoticeBody.isEmpty { return trimmedNoticeBody }
        if isOffDay {
            return Self.offDayMessage(at: date)
        }
        if isEffectivelySoldOutForWeek {
            return Self.soldOutForWeekMessage
        }
        return Self.soldOutForDayMessage(at: date)
    }

    /// General announcements (events, hour changes) — shown in addition to the status banner when set.
    var showsCustomerNoticeBanner: Bool {
        guard hasNotice else { return false }
        guard showsStatusBanner else { return true }

        let trimmedBody = noticeBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBody.isEmpty {
            return !noticeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return trimmedBody != statusBannerMessage()
    }

    var blocksOrderingDueToStatus: Bool {
        isOffDay || isEffectivelySoldOut
    }

    func canPlaceOrder(at date: Date = Date()) -> Bool {
        OperatingHours.isOpen(at: date) && !blocksOrderingDueToStatus
    }

    /// Changes when status banner content should reappear after dismiss.
    var statusBannerToken: String {
        "\(isOffDay)|\(isSoldOutForDay)|\(isSoldOutForWeek)|\(dailyPattyCount)|\(orderClosedMessage)|\(noticeBody)|\(updatedAt.timeIntervalSince1970)"
    }

    var customerNoticeToken: String {
        "\(noticeTitle)|\(noticeBody)|\(updatedAt.timeIntervalSince1970)"
    }
}

enum OrderAvailability {
    case open
    case outsideHours
    case offDay
    case soldOutForDay
    case soldOutForWeek

    var allowsOrdering: Bool {
        self == .open
    }
}

extension StoreStatus {
    func availability(at date: Date = Date()) -> OrderAvailability {
        guard OperatingHours.isOpen(at: date) else { return .outsideHours }
        if isOffDay { return .offDay }
        if isEffectivelySoldOutForWeek { return .soldOutForWeek }
        if isEffectivelySoldOutForDay { return .soldOutForDay }
        return .open
    }

    func orderBlockedMessage(at date: Date = Date()) -> String {
        if isOffDay {
            return statusBannerMessage(at: date)
        }
        if isEffectivelySoldOut && !isOffDay {
            return statusBannerMessage(at: date)
        }

        let trimmedClosedMessage = orderClosedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNoticeBody = noticeBody.trimmingCharacters(in: .whitespacesAndNewlines)

        switch availability(at: date) {
        case .open:
            return ""
        case .outsideHours:
            return OperatingHours.closedOrderMessage(at: date)
        case .offDay:
            if !trimmedClosedMessage.isEmpty { return trimmedClosedMessage }
            if !trimmedNoticeBody.isEmpty { return trimmedNoticeBody }
            return Self.offDayMessage(at: date)
        case .soldOutForWeek:
            if !trimmedClosedMessage.isEmpty { return trimmedClosedMessage }
            if !trimmedNoticeBody.isEmpty { return trimmedNoticeBody }
            return Self.soldOutForWeekMessage
        case .soldOutForDay:
            if !trimmedClosedMessage.isEmpty { return trimmedClosedMessage }
            if !trimmedNoticeBody.isEmpty { return trimmedNoticeBody }
            return Self.soldOutForDayMessage(at: date)
        }
    }

    func orderBlockedTitle(at date: Date = Date()) -> String {
        if isOffDay {
            return statusBannerTitle
        }
        if isEffectivelySoldOut && !isOffDay {
            return statusBannerTitle
        }

        switch availability(at: date) {
        case .open: return ""
        case .outsideHours: return "We're Closed"
        case .offDay: return "Closed Today"
        case .soldOutForWeek: return "Sold Out This Week"
        case .soldOutForDay: return "Sold Out Today"
        }
    }
}
