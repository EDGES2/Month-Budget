import SwiftUI
import CoreData

// MARK: - Модель даних категорій
final class CategoryDataModel: ObservableObject {
    @Published var filterOptions: [String] = [
        "Всі", "Поповнення", "Їжа", "Проживання", "Здоровʼя та краса",
        "Інтернет послуги", "Транспорт", "Розваги та спорт",
        "Приладдя для дому", "Благо", "Електроніка", "На інший рахунок", "Інше"
    ]
    
    @Published var colors: [String: Color] = [
        "Всі": Color(red: 0.9, green: 0.9, blue: 0.9),
        "Поповнення": Color(red: 0.0, green: 0.7, blue: 0.2),
        "Їжа": Color(red: 1.0, green: 0.6, blue: 0.0),
        "Проживання": Color(red: 0.0, green: 0.48, blue: 1.0),
        "Здоровʼя та краса": Color(red: 1.0, green: 0.41, blue: 0.71),
        "Інтернет послуги": Color(red: 0.0, green: 0.98, blue: 1.0),
        "Транспорт": Color(red: 0.0, green: 0.8, blue: 0.4),
        "Розваги та спорт": Color(red: 0.58, green: 0.0, blue: 0.83),
        "Приладдя для дому": Color(red: 0.5, green: 0.5, blue: 0.5),
        "Благо": Color(red: 0.74, green: 0.98, blue: 0.79),
        "Електроніка": Color(red: 0.0, green: 0.5, blue: 0.5),
        "На інший рахунок": Color(red: 0.7, green: 0.2, blue: 0.3),
        "Інше": Color(red: 0.29, green: 0.0, blue: 0.51)
    ]
}

// MARK: - MainAppView
struct MainAppView: View {
    @State private var selectedCategoryFilter = "Всі"
    @StateObject private var categoryDataModel = CategoryDataModel()
    
    var body: some View {
        HStack {
            Divider()
            SidebarView(selectedCategoryFilter: $selectedCategoryFilter)
                .environmentObject(categoryDataModel)
            Divider()
            VStack {
                TransactionsMainView(selectedCategoryFilter: $selectedCategoryFilter)
                    .environmentObject(categoryDataModel)
            }
            Divider()
        }
    }
}



// MARK: - Text Extension для стилізації кнопок для TransactionInputView
extension Text {
    func transactionButtonStyle(isSelected: Bool, color: Color) -> some View {
        self
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 35, alignment: .center)
            .background(color.opacity(isSelected ? 1.0 : 0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.8), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: color.opacity(isSelected ? 0.3 : 0.2),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1)
            .contentShape(Rectangle())
    }
}



// MARK: - Допоміжні компоненти та розширення
extension Transaction {
    var wrappedId: UUID { id ?? UUID() }
    var validCategory: String { category ?? "Інше" }
}

extension Text {
    func categoryButtonStyle(isSelected: Bool, color: Color) -> some View {
        self
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? (color == Color(red: 0.9, green: 0.9, blue: 0.9) ? .black : .white) : .primary)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(color.opacity(isSelected ? 1.0 : 0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.8), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: color.opacity(isSelected ? 0.3 : 0.2),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1)
            .contentShape(Rectangle())
    }
}
