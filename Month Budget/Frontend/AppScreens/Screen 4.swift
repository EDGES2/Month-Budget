import SwiftUI
import CoreData

extension AppView {
    // MARK: - APITransactionsView
    struct APITransactionsView: View {
        let transactions: FetchedResults<Transaction>
        let categoryDataModel: CategoryDataModel
        
        @EnvironmentObject var currencyDataModel: CurrencyDataModel
        @Environment(\.managedObjectContext) private var viewContext
        
        @State private var transactionToEdit: Transaction?
        
        private var currencyManager: CurrencyManager {
            CurrencyManager(currencyDataModel: currencyDataModel)
        }
        
        var body: some View {
            VStack {
                header
                apiTransactionsList
            }
        }
        
        // MARK: - Components
        private var header: some View {
            HStack {
                Text("API транзакції")
                    .font(.headline)
                Spacer()
                Button(action: {
                    TransactionService.deleteAllAPITransactions(in: viewContext, transactions: transactions)
                }) {
                    Image(systemName: "trash")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .help("Видалити всі транзакції категорії API")
                
                Button(action: {
                    TransactionService.fetchAPITransactions(in: viewContext)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .help("Оновити транзакції з API")
            }
            .padding()
        }
        
        private var apiTransactionsList: some View {
            List {
                ForEach(transactions.filter { $0.validCategory == "API" }, id: \.wrappedId) { transaction in
                    TransactionCell(
                        transaction: transaction,
                        color: categoryDataModel.colors[transaction.validCategory] ?? .gray,
                        onEdit: { transactionToEdit = transaction },
                        onDelete: { TransactionService.deleteTransaction(transaction, in: viewContext) }
                    )
                }
            }
            .listStyle(PlainListStyle())
            .sheet(item: $transactionToEdit) { transaction in
                EditTransaction(transaction: transaction)
                    .environmentObject(categoryDataModel)
                    .environmentObject(currencyDataModel)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}
