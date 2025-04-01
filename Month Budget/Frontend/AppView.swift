import SwiftUI
import CoreData

// MARK: - MainAppView
struct MainAppView: View {
    @State private var selectedCategoryFilter = "Всі"
    @State private var categoryFilterType: CategoryFilterType = .count
    @StateObject private var categoryDataModel = CategoryDataModel()
    
    var body: some View {
        HStack {
            Divider()
            SidebarView(selectedCategoryFilter: $selectedCategoryFilter,
                        categoryFilterType: $categoryFilterType)
                .environmentObject(categoryDataModel)
            Divider()
            VStack {
                TransactionsMainView(selectedCategoryFilter: $selectedCategoryFilter,
                                       categoryFilterType: $categoryFilterType)
                    .environmentObject(categoryDataModel)
            }
            Divider()
        }
    }
}

// MARK: - Text Extensions for стилізацію кнопок
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
 
