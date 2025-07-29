// Month Budget/Views/Screens/ReplenishmentSummaryView.swift
import SwiftUI
import CoreData

struct ReplenishmentSummaryView: View {
    let transactions: FetchedResults<Transaction>
    let selectedCategoryFilter: String
    
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @EnvironmentObject var currencyDataModel: CurrencyDataModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var transactionToEdit: Transaction?
    
    private var currencyManager: CurrencyManager {
        CurrencyManager(currencyDataModel: currencyDataModel)
    }
    
    var body: some View {
        let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
        
        VStack {
            ReplenishmentHeader(
                transactions: Array(filteredTransactions),
                color: categoryDataModel.colors[selectedCategoryFilter] ?? .gray,
                currencyManager: currencyManager
            )
            
            List {
                ForEach(filteredTransactions, id: \.wrappedId) { transaction in
                    TransactionCell(
                        transaction: transaction,
                        color: categoryDataModel.colors[transaction.validCategory] ?? .gray,
                        onEdit: { transactionToEdit = transaction },
                        onDelete: { TransactionService.deleteTransaction(transaction, in: viewContext) }
                    )
                }
            }
        }
        .sheet(item: $transactionToEdit) { transaction in
            EditTransaction(transaction: transaction)
                .environmentObject(categoryDataModel)
                .environmentObject(currencyDataModel)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

private extension ReplenishmentSummaryView {
    struct ReplenishmentHeader: View {
        let transactions: [Transaction]
        let color: Color
        let currencyManager: CurrencyManager
        
        var body: some View {
            let totalUAH = TransactionService.totalReplenishment(
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
