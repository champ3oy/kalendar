import SwiftUI

struct CalendarView: View {
    @State private var displayedMonth = Date()
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
                    DayCell(day: day)
                }
            }

            // Today button
            if !isCurrentMonth {
                Button("Today") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = Date()
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
            }
        }
        .padding(16)
        .frame(width: 280)
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

        // Monday = 1, Sunday = 7 (ISO)
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        // Convert to Monday-based: Mon=0, Tue=1, ..., Sun=6
        let offset = (weekday + 5) % 7

        // Previous month padding
        if offset > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
            let prevRange = calendar.range(of: .day, in: .month, for: prevMonth)!
            let prevStart = prevRange.upperBound - offset
            for day in prevStart..<prevRange.upperBound {
                let date = calendar.date(bySetting: .day, value: day, of: prevMonth)!
                days.append(DayModel(number: day, date: date, isCurrentMonth: false, isToday: false))
            }
        }

        // Current month days
        for day in range {
            let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth)!
            let isToday = calendar.isDateInToday(date)
            days.append(DayModel(number: day, date: date, isCurrentMonth: true, isToday: isToday))
        }

        // Next month padding
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

struct DayModel: Identifiable {
    let id = UUID()
    let number: Int
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
}

struct DayCell: View {
    let day: DayModel

    var body: some View {
        Text("\(day.number)")
            .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
            .foregroundColor(day.isCurrentMonth ? (day.isToday ? .white : .primary) : .secondary.opacity(0.5))
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(day.isToday ? Color.accentColor : Color.clear)
            )
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    CalendarView()
        .frame(width: 280, height: 320)
}
