import SwiftUI
import CoreData

extension AppView {
    // MARK: - SelectedCategoryDetailsView
    struct SelectedCategoryDetailsView: View {
        let transactions: FetchedResults<Transaction>
        let selectedCategoryFilter: String
        
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @EnvironmentObject var currencyDataModel: CurrencyDataModel
        
        @State private var transactionToEdit: Transaction?
        
        private var currencyManager: CurrencyManager {
            CurrencyManager(currencyDataModel: currencyDataModel)
        }
        
        var body: some View {
            let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
            
            return VStack {
                CategoryHeader(
                    selectedCategory: selectedCategoryFilter,
                    transactions: filteredTransactions,
                    color: categoryDataModel.colors[selectedCategoryFilter] ?? .gray,
                    currencyManager: currencyManager
                )
                
                List {
                    ForEach(filteredTransactions, id: \.wrappedId) { transaction in
                        TransactionCell(
                            transaction: transaction,
                            color: categoryDataModel.colors[transaction.validCategory] ?? .gray,
                            onEdit: { transactionToEdit = transaction },
                            onDelete: { deleteTransaction(transaction) }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .sheet(item: $transactionToEdit) { transaction in
                EditTransaction(transaction: transaction)
                    .environmentObject(categoryDataModel)
                    .environmentObject(currencyDataModel)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
        
        // MARK: - Helper Methods
        private func deleteTransaction(_ transaction: Transaction) {
            let viewContext = PersistenceController.shared.container.viewContext
            viewContext.delete(transaction)
            do {
                try viewContext.save()
            } catch {
                print("Помилка видалення: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CategoryHeader (використовується в SelectedCategoryDetailsView)
extension AppView.SelectedCategoryDetailsView {
    struct CategoryHeader: View {
        let selectedCategory: String
        let transactions: [Transaction]
        let color: Color
        let currencyManager: CurrencyManager
        
        var body: some View {
            // Перевіряємо чи категорія - "На інший рахунок"
            let isOtherAccount = selectedCategory == "На інший рахунок"
            
            let totalUAH: Double = isOtherAccount ?
                PersistenceController.shared.totalToOtherAccount(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
                :
                PersistenceController.shared.totalExpenses(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
            
            let totalPLN: Double = isOtherAccount ?
                PersistenceController.shared.totalToOtherAccount(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency2,
                    currencyManager: currencyManager
                )
                :
                PersistenceController.shared.totalExpenses(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency2,
                    currencyManager: currencyManager
                )
            
            let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
            
            return VStack(spacing: 8) {
                Text("Загальна сума \(isOtherAccount ? "переведень" : "витрат") в UAH: \(totalUAH, format: .number.precision(.fractionLength(2)))")
                Text("Загальна сума \(isOtherAccount ? "переведень" : "витрат") в PLN: \(totalPLN, format: .number.precision(.fractionLength(2)))")
                Text("Курс: \(rate, format: .number.precision(.fractionLength(2)))")
            }
            .padding()
            .background(color.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
