// Month Budget/Views/Screens/CategoryDetailsView.swift
import SwiftUI
import CoreData

struct CategoryDetailsView: View {
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
        
        return VStack {
            CategoryHeader(
                selectedCategory: selectedCategoryFilter,
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
            .listStyle(PlainListStyle())
        }
        .sheet(item: $transactionToEdit) { transaction in
            EditTransaction(transaction: transaction)
                .environmentObject(categoryDataModel)
                .environmentObject(currencyDataModel)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

private extension CategoryDetailsView {
    struct CategoryHeader: View {
        let selectedCategory: String
        let transactions: [Transaction]
        let color: Color
        let currencyManager: CurrencyManager
        
        var body: some View {
            let isOtherAccount = selectedCategory == "На інший рахунок"
            
            let totalUAH: Double = isOtherAccount ?
                TransactionService.totalToOtherAccount(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
                :
                TransactionService.totalExpenses(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
            
            let totalPLN: Double = isOtherAccount ?
                TransactionService.totalToOtherAccount(
                    for: transactions,
                    targetCurrency: currencyManager.baseCurrency2,
                    currencyManager: currencyManager
                )
                :
                TransactionService.totalExpenses(
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
