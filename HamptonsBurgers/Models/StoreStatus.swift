import Foundation

struct StoreStatus: Codable, Equatable {
    var isOffDay: Bool
    var isSoldOut: Bool
    var pattyCount: Int
    var pattyCapacity: Int
    var noticeTitle: String
    var noticeBody: String
    var orderClosedMessage: String
    var updatedAt: Date

    static let `default` = StoreStatus(
        isOffDay: false,
        isSoldOut: false,
        pattyCount: BrandConfig.defaultPattyCapacity,
        pattyCapacity: BrandConfig.defaultPattyCapacity,
        noticeTitle: "",
        noticeBody: "",
        orderClosedMessage: "",
        updatedAt: Date()
    )

    /// Shown when sold out or patty count hits zero — always Tuesday (start of the week).
    static let soldOutMessage = "Sorry, we've sold out for the week. Check back Tuesday at 11:00 AM."

    static func offDayMessage(at date: Date = Date()) -> String {
        "Sorry, we're closed today. Check back \(OperatingHours.formattedNextOpeningAfterToday(after: date))."
    }

    var isEffectivelySoldOut: Bool {
        isSoldOut || pattyCount <= 0
    }

    var fuelLevel: Double {
        guard pattyCapacity > 0 else { return 0 }
        return min(1, max(0, Double(pattyCount) / Double(pattyCapacity)))
    }

    var hasNotice: Bool {
        !noticeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !noticeBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayNoticeTitle: String {
        let trimmed = noticeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Notice" : trimmed
    }

    /// Off day, sold-out flag, or zero patties — drives the automatic status banner.
    var showsStatusBanner: Bool {
        isOffDay || isEffectivelySoldOut
    }

    var statusBannerTitle: String {
        if isOffDay { return "Closed Today" }
        return "Sold Out"
    }

    func statusBannerMessage(at date: Date = Date()) -> String {
        let trimmedClosedMessage = orderClosedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNoticeBody = noticeBody.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedClosedMessage.isEmpty { return trimmedClosedMessage }
        if !trimmedNoticeBody.isEmpty { return trimmedNoticeBody }
        if isOffDay {
            return Self.offDayMessage(at: date)
        }
        return Self.soldOutMessage
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
        "\(isOffDay)|\(isSoldOut)|\(pattyCount)|\(orderClosedMessage)|\(noticeBody)|\(updatedAt.timeIntervalSince1970)"
    }

    var customerNoticeToken: String {
        "\(noticeTitle)|\(noticeBody)|\(updatedAt.timeIntervalSince1970)"
    }
}

enum OrderAvailability {
    case open
    case outsideHours
    case offDay
    case soldOut

    var allowsOrdering: Bool {
        self == .open
    }
}

extension StoreStatus {
    func availability(at date: Date = Date()) -> OrderAvailability {
        guard OperatingHours.isOpen(at: date) else { return .outsideHours }
        if isOffDay { return .offDay }
        if isEffectivelySoldOut { return .soldOut }
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
        case .offDay, .soldOut:
            if !trimmedClosedMessage.isEmpty { return trimmedClosedMessage }
            if !trimmedNoticeBody.isEmpty { return trimmedNoticeBody }
            if availability(at: date) == .soldOut {
                return Self.soldOutMessage
            }
            return Self.offDayMessage(at: date)
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
        case .soldOut: return "Sold Out"
        }
    }
}
