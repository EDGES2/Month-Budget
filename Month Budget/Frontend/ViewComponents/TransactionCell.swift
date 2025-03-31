import SwiftUI
import CoreData

// MARK: - TransactionCell
struct TransactionCell: View {
    let transaction: Transaction
    let color: Color
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @EnvironmentObject var currencyDataModel: CurrencyDataModel
    
    private var currencyManager: CurrencyManager {
        CurrencyManager(currencyDataModel: currencyDataModel)
    }
    
    private let viewContext = PersistenceController.shared.container.viewContext
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    private var displaySecondAmount: Double {
        transaction.secondAmount
    }
    
    private var displaySecondSymbol: String {
        let secondCode = transaction.secondCurrencyCode ?? currencyManager.baseCurrency1
        if secondCode == currencyManager.baseCurrency2 {
            return currencyManager.currencies[currencyManager.baseCurrency2]?.symbol ?? currencyManager.baseCurrency2
        } else {
            return currencyManager.currencies[secondCode]?.symbol ?? secondCode
        }
    }
    
    var body: some View {
        let firstCode = transaction.firstCurrencyCode ?? currencyManager.baseCurrency1
        let firstCurrencyInfo = currencyManager.currencies[firstCode]
        
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Text("\(transaction.firstAmount, specifier: "%.2f") \(firstCurrencyInfo?.symbol ?? firstCode)")
                    .font(.headline)
                Text("\(displaySecondAmount, specifier: "%.2f") \(displaySecondSymbol)")
                Text("Курс: \(displaySecondAmount != 0 ? (transaction.firstAmount / displaySecondAmount) : 0, specifier: "%.2f")")
                Text(transaction.date ?? Date(), formatter: dateFormatter)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let comment = transaction.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(minWidth: 370, maxWidth: .infinity, minHeight: 35, maxHeight: 100)
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        // Отримуємо контекст для Core Data (можна використовувати preview context)
        let context = PersistenceController.shared.container.viewContext
        
        // Створюємо демо-об’єкт Transaction
        let transaction = Transaction(context: context)
        transaction.firstAmount = 100.0
        transaction.secondAmount = 80.0
        transaction.firstCurrencyCode = "USD"
        transaction.secondCurrencyCode = "EUR"
        transaction.date = Date()
        transaction.comment = "Приклад транзакції"
        
        // Створюємо демо-модель даних для валют
        let currencyDataModel = CurrencyDataModel()
        // За потребою налаштуйте currencies, baseCurrency1 та baseCurrency2
        // Наприклад:
        // currencyDataModel.baseCurrency1 = "USD"
        // currencyDataModel.baseCurrency2 = "EUR"
        // currencyDataModel.currencies = [
        //     "USD": Currency(symbol: "$"),
        //     "EUR": Currency(symbol: "€")
        // ]
        
        return TransactionCell(
            transaction: transaction,
            color: .blue,
            onEdit: { print("Edit tapped") },
            onDelete: { print("Delete tapped") }
        )
        .environmentObject(currencyDataModel)
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
