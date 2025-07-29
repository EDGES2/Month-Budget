// Month Budget/Views/Components/CalendarView.swift
import SwiftUI

struct CustomCalendarView: View {
    private let calendar = Calendar.current
    private let today = Date()
    
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left").padding()
                }
                .buttonStyle(.plain)
                Spacer()
                Text(monthYearString(for: currentMonth)).font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right").padding()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day).frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(generateDates(for: currentMonth), id: \.self) { date in
                    Button(action: { selectedDate = date }) {
                        Text("\(calendar.component(.day, from: date))")
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundColor(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .primary : .gray)
                            .background(
                                calendar.isDate(date, inSameDayAs: today) ? Color.blue.opacity(0.3) :
                                (calendar.isDate(date, inSameDayAs: selectedDate) ? Color.green.opacity(0.3) : Color.clear)
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func generateDates(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmptyCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var dates: [Date] = []
        
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: month),
           let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count {
            for day in (daysInPreviousMonth - leadingEmptyCount + 1)...daysInPreviousMonth {
                var components = calendar.dateComponents([.year, .month], from: previousMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    dates.append(date)
                }
            }
        }
        
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: month)!.count
        for day in 1...daysInCurrentMonth {
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = day
            if let date = calendar.date(from: components) {
                dates.append(date)
            }
        }
        
        while dates.count < 42 {
            if let lastDate = dates.last,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                dates.append(nextDay)
            }
        }
        
        return dates
    }
}
