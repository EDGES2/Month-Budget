import SwiftUI

struct CustomCalendarView: View {
    private let calendar = Calendar.current
    private let today = Date()
    
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack {
            // Панель навігації між місяцями
            HStack {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                .buttonStyle(.plain)
                Spacer()
                Text(monthYearString(for: currentMonth))
                    .font(.headline)
                Spacer()
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .padding()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            // Дні тижня
            let daysOfWeek = calendar.shortWeekdaySymbols
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Дні місяця у сітці 7x6
            let dates = generateDates(for: currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(dates, id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                    }) {
                        Text("\(calendar.component(.day, from: date))")
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundColor(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .primary : .gray)
                            .background(
                                // Підсвічування: сьогодні та вибрана дата мають фон
                                calendar.isDate(date, inSameDayAs: today) ?
                                    Color.blue.opacity(0.3) :
                                    (calendar.isDate(date, inSameDayAs: selectedDate) ?
                                        Color.green.opacity(0.3) :
                                        Color.clear)
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle()) // Забираємо стандартний фон кнопки
                }
            }
            .padding()
        }
    }
    
    // Зміна місяця на задану кількість місяців вперед або назад
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    // Форматування рядка з місяцем і роком
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    /// Генерує масив з 42 дат для відображення календаря.
    /// Дні з попереднього та наступного місяця додаються для заповнення сітки.
    private func generateDates(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        // Обчислюємо кількість днів для заповнення першого рядка (дні з попереднього місяця)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmptyCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var dates: [Date] = []
        
        // Додаємо дні з попереднього місяця
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
        
        // Додаємо дні поточного місяця
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: month)!.count
        for day in 1...daysInCurrentMonth {
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = day
            if let date = calendar.date(from: components) {
                dates.append(date)
            }
        }
        
        // Заповнюємо дні наступного місяця, щоб отримати рівно 42 елементи
        while dates.count < 42 {
            if let lastDate = dates.last,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                dates.append(nextDay)
            }
        }
        
        return dates
    }
}

//struct CustomCalendarView_Previews: PreviewProvider {
//    @State static var date = Date()
//    static var previews: some View {
//        CustomCalendarView(selectedDate: $date)
//    }
//}
