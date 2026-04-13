import EventKit
import SwiftUI

class EventManager: ObservableObject {
    let store = EKEventStore()
    @Published var events: [Date: [EKEvent]] = [:]
    @Published var reminders: [Date: [EKReminder]] = [:]
    @Published var calendarAccess = false
    @Published var reminderAccess = false

    private let calendar = Calendar.current

    init() {
        requestAccess()
    }

    func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async { self.calendarAccess = granted }
            }
            store.requestFullAccessToReminders { granted, _ in
                DispatchQueue.main.async { self.reminderAccess = granted }
            }
        } else {
            store.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async { self.calendarAccess = granted }
            }
            store.requestAccess(to: .reminder) { granted, _ in
                DispatchQueue.main.async { self.reminderAccess = granted }
            }
        }
    }

    func fetchEvents(for month: Date) {
        guard calendarAccess else { return }

        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let monthEvents = store.events(matching: predicate)

        var grouped: [Date: [EKEvent]] = [:]
        for event in monthEvents {
            let dayStart = calendar.startOfDay(for: event.startDate)
            grouped[dayStart, default: []].append(event)
        }

        DispatchQueue.main.async {
            self.events = grouped
        }
    }

    func fetchReminders(for month: Date) {
        guard reminderAccess else { return }

        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }

        let predicate = store.predicateForReminders(in: nil)
        store.fetchReminders(matching: predicate) { reminders in
            guard let reminders = reminders else { return }

            var grouped: [Date: [EKReminder]] = [:]
            for reminder in reminders {
                if let due = reminder.dueDateComponents,
                   let dueDate = self.calendar.date(from: due),
                   dueDate >= start && dueDate < end {
                    let dayStart = self.calendar.startOfDay(for: dueDate)
                    grouped[dayStart, default: []].append(reminder)
                }
            }

            DispatchQueue.main.async {
                self.reminders = grouped
            }
        }
    }

    func eventsForDay(_ date: Date) -> [EKEvent] {
        let key = calendar.startOfDay(for: date)
        return (events[key] ?? []).sorted { $0.startDate < $1.startDate }
    }

    func remindersForDay(_ date: Date) -> [EKReminder] {
        let key = calendar.startOfDay(for: date)
        return reminders[key] ?? []
    }

    func hasItems(on date: Date) -> Bool {
        let key = calendar.startOfDay(for: date)
        return (events[key]?.isEmpty == false) || (reminders[key]?.isEmpty == false)
    }

    func toggleReminder(_ reminder: EKReminder) {
        reminder.isCompleted = !reminder.isCompleted
        try? store.save(reminder, commit: true)
        objectWillChange.send()
    }
}
