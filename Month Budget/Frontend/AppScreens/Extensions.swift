import SwiftUI
import CoreData

// MARK: - EditTransaction View
struct EditTransaction: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @EnvironmentObject var currencyDataModel: CurrencyDataModel
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var transaction: Transaction
    
    @State private var editedFirstAmount: String
    @State private var editedSecondAmount: String
    @State private var selectedFirstCurrency: String
    @State private var selectedSecondCurrency: String
    @State private var selectedCategory: String
    @State private var editedComment: String
    
    private var currencyManager: CurrencyManager {
        CurrencyManager(currencyDataModel: currencyDataModel)
    }
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _editedFirstAmount = State(initialValue: String(format: "%.2f", transaction.firstAmount))
        _editedSecondAmount = State(initialValue: String(format: "%.2f", transaction.secondAmount))
        _selectedFirstCurrency = State(initialValue: transaction.firstCurrencyCode ?? "UAH")
        _selectedSecondCurrency = State(initialValue: transaction.secondCurrencyCode ?? "PLN")
        _selectedCategory = State(initialValue: transaction.category ?? "Їжа")
        _editedComment = State(initialValue: transaction.comment ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                currencyPickerSection(title: "Перша валюта:", selection: $selectedFirstCurrency)
                inputSection(title: "Перша сума:", text: $editedFirstAmount)
                currencyPickerSection(title: "Друга валюта:", selection: $selectedSecondCurrency)
                inputSection(title: "Друга сума:", text: $editedSecondAmount)
                categoryPickerSection
                inputSection(title: "Коментар:", text: $editedComment)
                Spacer()
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
        }
        .navigationTitle("Редагування")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Скасувати") { closeView() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Зберегти") { saveChanges() }
            }
        }
    }
    
    // MARK: - Input Components
    private func inputSection(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
    }
    
    private func currencyPickerSection(title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Picker("", selection: selection) {
                ForEach(Array(currencyManager.currencies.keys), id: \.self) { code in
                    if let symbol = currencyManager.currencies[code]?.symbol {
                        Text("\(code) (\(symbol))")
                    } else {
                        Text(code)
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Категорія:")
                .font(.headline)
            Picker("", selection: $selectedCategory) {
                ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" }, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var cardBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    // MARK: - Helper Methods
    private func closeView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveChanges() {
        guard let firstAmt = Double(editedFirstAmount),
              let secondAmt = Double(editedSecondAmount) else { return }
        
        // Оновлюємо транзакцію через TransactionService
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        var transactionsArray: [Transaction] = []
        do {
            transactionsArray = try viewContext.fetch(request)
        } catch {
            print("Помилка отримання транзакцій: \(error.localizedDescription)")
        }
        
        let success = TransactionService.updateTransaction(
            transaction,
            newFirstAmount: firstAmt,
            newFirstCurrencyCode: selectedFirstCurrency,
            newSecondAmount: secondAmt,
            newSecondCurrencyCode: selectedSecondCurrency,
            newCategory: selectedCategory,
            newComment: editedComment,
            transactions: transactionsArray,
            currencyManager: currencyManager,
            in: viewContext
        )
        if success {
            closeView()
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

