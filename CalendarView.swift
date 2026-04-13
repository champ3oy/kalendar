import SwiftUI
import EventKit

struct CalendarView: View {
    @StateObject private var eventManager = EventManager()
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil
    private let calendar = Calendar.current
    private let daySymbols = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        VStack(spacing: 12) {
            // Header with month/year and navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearString)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
            }

            // Day of week headers
            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.id) { day in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selectedDate.map({ calendar.isDate($0, inSameDayAs: day.date) }) ?? false {
                                selectedDate = nil
                            } else {
                                selectedDate = day.date
                            }
                        }
                    }) {
                        DayCell(
                            day: day,
                            hasEvents: eventManager.hasItems(on: day.date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: day.date) } ?? false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Today button
            if !isCurrentMonth {
                Button("Today") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = Date()
                        selectedDate = nil
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
            }

            // Event list for selected day
            if let selected = selectedDate {
                Divider()
                EventListView(date: selected, eventManager: eventManager)
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            eventManager.fetchEvents(for: displayedMonth)
            eventManager.fetchReminders(for: displayedMonth)
        }
        .onChange(of: displayedMonth) { newMonth in
            selectedDate = nil
            eventManager.fetchEvents(for: newMonth)
            eventManager.fetchReminders(for: newMonth)
        }
        .onChange(of: eventManager.calendarAccess) { _ in
            eventManager.fetchEvents(for: displayedMonth)
        }
        .onChange(of: eventManager.reminderAccess) { _ in
            eventManager.fetchReminders(for: displayedMonth)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func changeMonth(by value: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        }
    }

    private func generateDays() -> [DayModel] {
        var days: [DayModel] = []

        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday + 5) % 7

        if offset > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
            let prevRange = calendar.range(of: .day, in: .month, for: prevMonth)!
            let prevStart = prevRange.upperBound - offset
            for day in prevStart..<prevRange.upperBound {
                let date = calendar.date(bySetting: .day, value: day, of: prevMonth)!
                days.append(DayModel(number: day, date: date, isCurrentMonth: false, isToday: false))
            }
        }

        for day in range {
            let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth)!
            let isToday = calendar.isDateInToday(date)
            days.append(DayModel(number: day, date: date, isCurrentMonth: true, isToday: isToday))
        }

        let remaining = (7 - days.count % 7) % 7
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
        for day in 1...max(remaining, 1) {
            if days.count % 7 == 0 && days.count >= 28 { break }
            let date = calendar.date(bySetting: .day, value: day, of: nextMonth)!
            days.append(DayModel(number: day, date: date, isCurrentMonth: false, isToday: false))
        }

        return days
    }
}

// MARK: - Event List

struct EventListView: View {
    let date: Date
    @ObservedObject var eventManager: EventManager

    private var dayEvents: [EKEvent] { eventManager.eventsForDay(date) }
    private var dayReminders: [EKReminder] { eventManager.remindersForDay(date) }
    private var hasItems: Bool { !dayEvents.isEmpty || !dayReminders.isEmpty }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Self.dayFormatter.string(from: date))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            if !eventManager.calendarAccess && !eventManager.reminderAccess {
                Text("Grant calendar access in System Settings")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else if !hasItems {
                Text("No events")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(dayEvents.prefix(8), id: \.eventIdentifier) { event in
                        EventRow(event: event)
                    }
                    ForEach(dayReminders.prefix(4), id: \.calendarItemIdentifier) { reminder in
                        ReminderRow(reminder: reminder, eventManager: eventManager)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventRow: View {
    let event: EKEvent

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(event.calendar.cgColor))
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled")
                    .font(.system(size: 12))
                    .lineLimit(1)

                if event.isAllDay {
                    Text("All day")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Text(timeString(event.startDate, to: event.endDate))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            let epoch = Int(event.startDate.timeIntervalSinceReferenceDate)
            if let url = URL(string: "ical://\(epoch)") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func timeString(_ start: Date, to end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}

struct ReminderRow: View {
    let reminder: EKReminder
    @ObservedObject var eventManager: EventManager

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(reminder.calendar.cgColor))
                .frame(width: 3, height: 28)

            Button(action: { eventManager.toggleReminder(reminder) }) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(reminder.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(reminder.title ?? "Untitled")
                .font(.system(size: 12))
                .strikethrough(reminder.isCompleted)
                .lineLimit(1)
                .onTapGesture {
                    if let url = URL(string: "x-apple-reminderkit://") {
                        NSWorkspace.shared.open(url)
                    }
                }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Day Model & Cell

struct DayModel: Identifiable {
    let id = UUID()
    let number: Int
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
}

struct DayCell: View {
    let day: DayModel
    let hasEvents: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day.number)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                .foregroundColor(foregroundColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )

            Circle()
                .fill(hasEvents && day.isCurrentMonth ? Color.accentColor.opacity(0.8) : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var foregroundColor: Color {
        if !day.isCurrentMonth { return .secondary.opacity(0.5) }
        if day.isToday || isSelected { return .white }
        return .primary
    }

    private var backgroundColor: Color {
        if day.isToday { return Color.accentColor }
        if isSelected && day.isCurrentMonth { return Color.accentColor.opacity(0.4) }
        return .clear
    }
}

#Preview {
    CalendarView()
        .frame(width: 300, height: 450)
}
