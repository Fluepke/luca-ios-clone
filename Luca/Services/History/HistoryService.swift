import Foundation
import RxSwift

// Do not rename the properties, it won't be deserializable than.
// And if you have to, define the old values as strings to preserve the serialization.
// Or implement proper migration
enum HistoryEntryType: String, Codable {
    case checkIn
    case checkOut
    case userDataUpdate
    case userDataTransfer
}

struct HistoryEntry: Codable {
    var date: Date
    var type: HistoryEntryType

    // Optional value for check in and check out events
    var location: Location?
    var role: Role?
    var guestlist: [String]?

    init(date: Date, type: HistoryEntryType, location: Location?) {
        self.date = date
        self.type = type
        self.location = location
        self.role = .guest
    }

    init(date: Date, type: HistoryEntryType, location: Location?, guestlist: [String]?) {
        self.date = date
        self.type = type
        self.location = location
        self.guestlist = guestlist
        self.role = .host
    }

}

class UserEvent: HistoryEvent {

    var checkin: HistoryEntry
    var checkout: HistoryEntry?

    init(checkin: HistoryEntry) {
        self.checkin = checkin
        super.init(date: checkin.date)
    }

    init(checkin: HistoryEntry, checkout: HistoryEntry) {
        self.checkin = checkin
        self.checkout = checkout
        super.init(date: checkin.date)
    }

}

class UserDataTransfer: HistoryEvent {

    var entry: HistoryEntry

    init(entry: HistoryEntry) {
        self.entry = entry
        super.init(date: entry.date)
    }
}

class UserDataUpdate: HistoryEvent {

    var entry: HistoryEntry

    init(entry: HistoryEntry) {
        self.entry = entry
        super.init(date: entry.date)
    }

}

class HistoryEvent {

    var date: Date

    init(date: Date) {
        self.date = date
    }

}

enum Role: String, Codable {

    case guest
    case host

}

class HistoryService {
    private let preferences: Preferences

    public let onEventAdded = "HistoryService.onEventAdded"

    private var entriesBuffer: [HistoryEntry]?

    private(set) var entries: [HistoryEntry] {
        get {
            if let buffer = entriesBuffer {
                return buffer
            }
            let retrieved = preferences.retrieve(key: "historyEntries", type: [HistoryEntry].self) ?? []
            defer { self.entriesBuffer = retrieved }
            return retrieved
        }
        set {
            preferences.store(newValue, key: "historyEntries")
            entriesBuffer = newValue
        }
    }

    var historyEvents: [HistoryEvent] {
        var historyEntries = entries.sorted(by: { $0.date < $1.date })

        let firstCheckin = historyEntries.firstIndex(where: { $0.type == .checkIn })
        let firstCheckout = historyEntries.firstIndex(where: { $0.type == .checkOut })

        // If first entry is a checkout, then history was cleared while checked in.
        if let firstOut = firstCheckout, let firstIn = firstCheckin, firstOut < firstIn {
            historyEntries.remove(at: firstOut)
        }

        let userDataTransfers = historyEntries.filter { $0.type == .userDataTransfer }.map { UserDataTransfer(entry: $0) }
        let checkins = historyEntries.filter { $0.type == .checkIn }
        let checkouts = historyEntries.filter { $0.type == .checkOut }

        // Zip together checkins that have a corresponding checkout
        let events = zip(checkins, checkouts)
        var userEvents = events.map { UserEvent(checkin: $0.0, checkout: $0.1) }

        // There can only be one leftover checkin (if any), as a user cannot check into events simultaneously
        if checkouts.count != checkins.count, let lastCheckin = checkins.last {
            userEvents.append(UserEvent(checkin: lastCheckin))
        }

        let allEvents = userEvents + userDataTransfers

        return allEvents.sorted(by: { $0.date < $1.date })
    }

    func removeOldEntries() {
        let currentDate = Date()
        guard let lastTwoWeeks = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: currentDate) else {
            return
        }

        let filtered = entries.filter { $0.date > lastTwoWeeks }
        entries = filtered
    }

    func clearEntries() {
        entries = [HistoryEntry]()
    }

    func migrateDataFrom_1_2_3() {
        let oldEntries = self.preferences.retrieveArray(key: "historyEntries", type: [HistoryEntry].self)
        var merged = entries
        merged.append(contentsOf: oldEntries)
        merged.sort(by: { $0.date < $1.date })
        self.entries = merged
    }

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func add(entry: HistoryEntry) {
        var temp = entries
        temp.append(entry)
        entries = temp

        NotificationCenter.default.post(Notification(name: Notification.Name(self.onEventAdded), object: self, userInfo: nil))
    }
}

extension HistoryService {
    var onEventAddedRx: Observable<HistoryEntry> {
        return NotificationCenter.default.rx.notification(NSNotification.Name(self.onEventAdded), object: self).map { _ in self.entries.last }.unwrapOptional()
    }
}
