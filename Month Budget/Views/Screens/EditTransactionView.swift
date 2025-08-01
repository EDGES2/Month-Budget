import SwiftUI
import CoreData

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
                inputSection(title: "Друга сума (необов'язково):", text: $editedSecondAmount)
                categoryPickerSection
                inputSection(title: "Коментар:", text: $editedComment)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
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
                ForEach(Array(currencyManager.currencies.keys.sorted()), id: \.self) { code in
                    Text(currencyManager.currencies[code]?.symbol ?? code).tag(code)
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
    
    private func closeView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveChanges() {
        guard let firstAmt = Double(editedFirstAmount), !editedFirstAmount.isEmpty else { return }
        
        let secondAmt = Double(editedSecondAmount) ?? 0.0

        let success = TransactionService.updateTransaction(
            transaction,
            newFirstAmount: firstAmt,
            newFirstCurrencyCode: selectedFirstCurrency,
            newSecondAmount: secondAmt,
            newSecondCurrencyCode: selectedSecondCurrency,
            newCategory: selectedCategory,
            newComment: editedComment,
            currencyManager: currencyManager,
            in: viewContext
        )
        if success {
            closeView()
        }
    }
}
