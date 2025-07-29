// Month Budget/Views/Main/AppView.swift
import SwiftUI
import CoreData

struct AppView: View {
    // MARK: - Властивості для фільтрації та моделі даних
    @State private var selectedCategoryFilter = "Всі"
    @State private var categoryFilterType: CategoryFilterType = .count
    @StateObject private var categoryDataModel = CategoryDataModel()
    @StateObject private var currencyDataModel = CurrencyDataModel()
    
    // MARK: - CoreData середовище та запит транзакцій
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<Transaction>
    
    private let monthlyBudget: Double = 20000.0

    // MARK: - Body
    var body: some View {
        HStack {
            Divider()
            SidebarView(selectedCategoryFilter: $selectedCategoryFilter,
                        categoryFilterType: $categoryFilterType)
                .environmentObject(categoryDataModel)
            Divider()
            VStack {
                // Логіка відображення транзакцій залежно від вибраного фільтру
                switch selectedCategoryFilter {
                //Screen 1
                case "Логотип":
                    BudgetSummaryView(
                        monthlyBudget: monthlyBudget,
                        transactions: transactions,
                        categoryColor: categoryDataModel.colors["Всі"] ?? .gray
                    )
                    .environmentObject(currencyDataModel)
                //Screen 2
                case "Всі":
                    AllCategoriesSummaryView(
                        transactions: transactions,
                        categoryFilterType: $categoryFilterType
                    )
                    .environmentObject(currencyDataModel)
                //Screen 3
                case "Поповнення":
                    ReplenishmentSummaryView(
                        transactions: transactions,
                        selectedCategoryFilter: selectedCategoryFilter
                    )
                    .environmentObject(currencyDataModel)
                //Screen 4
                case "API":
                    APITransactionsView(
                        transactions: transactions,
                        categoryDataModel: categoryDataModel
                    )
                    .environmentObject(currencyDataModel)
                //Screen 5
                default:
                    CategoryDetailsView(
                        transactions: transactions,
                        selectedCategoryFilter: selectedCategoryFilter
                    )
                    .environmentObject(currencyDataModel)
                }
            }
            Divider()
        }
        .environmentObject(categoryDataModel)
    }
}
