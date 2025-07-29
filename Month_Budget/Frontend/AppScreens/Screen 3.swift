import SwiftUI
import CoreData

extension AppView {
    // MARK: - TotalRepliesSummaryView
    struct TotalRepliesSummaryView: View {
        let transactions: FetchedResults<Transaction>
        let selectedCategoryFilter: String
        
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @EnvironmentObject var currencyDataModel: CurrencyDataModel
        
        @State private var transactionToEdit: Transaction?
        
        private var currencyManager: CurrencyManager {
            CurrencyManager(currencyDataModel: currencyDataModel)
        }
        
        var body: some View {
            // Фільтруємо транзакції за категорією
            let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
            
            VStack {
                ReplenishmentHeader(
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

// MARK: - ReplenishmentHeader (використовується в TotalRepliesSummaryView)
extension AppView.TotalRepliesSummaryView {
    struct ReplenishmentHeader: View {
        let transactions: [Transaction]
        let color: Color
        let currencyManager: CurrencyManager
        
        var body: some View {
            let totalUAH = PersistenceController.shared.totalReplenishment(
                for: transactions,
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
            
            return VStack(spacing: 8) {
                Text("Загальна сума поповнень в UAH: \(totalUAH, format: .number.precision(.fractionLength(2)))")
            }
            .padding()
            .background(color.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
