import SwiftUI
import CoreData

// MARK: - BudgetSummaryView та супутні компоненти
extension TransactionsMainView {
    struct BudgetSummaryView: View {
        // MARK: - Властивості
        let monthlyBudget: Double
        let transactions: FetchedResults<Transaction>
        let categoryColor: Color

        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @EnvironmentObject var currencyDataModel: CurrencyDataModel
        @Environment(\.managedObjectContext) private var viewContext

        @State private var transactionToEdit: Transaction?
        @State private var showTransactionInputSheet: Bool = false
        @State private var showFullTransactionList: Bool = false
        @State private var showCalendarSheet: Bool = false
        @State private var selectedDate: Date = Date()

        private let initialBalance: Double = 29703.54

        private var currencyManager: CurrencyManager {
            CurrencyManager(currencyDataModel: currencyDataModel)
        }

        // MARK: - Розрахунки
        private var totalExpensesUAH: Double {
            PersistenceController.shared.totalExpenses(
                for: transactions.map { $0 },
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
        }

        private var totalReplenishmentUAH: Double {
            PersistenceController.shared.totalReplenishment(
                for: transactions.map { $0 },
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
        }

        private var totalToOtherAccountUAH: Double {
            PersistenceController.shared.totalToOtherAccount(
                for: transactions.map { $0 },
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
        }

        private var expectedBalanceUAH: Double {
            monthlyBudget - totalExpensesUAH
        }

        private var actualBalanceUAH: Double {
            initialBalance + totalReplenishmentUAH - totalExpensesUAH - totalToOtherAccountUAH
        }

        // MARK: - Функції
        private func deleteTransaction(_ transaction: Transaction) {
            TransactionService.deleteTransaction(transaction, in: viewContext)
        }

        // MARK: - Body
        var body: some View {
            ScrollView(.vertical) {
                LazyVStack(alignment: .center, spacing: 10) {
                    headerView
                    addTransactionButton
                    transactionHistoryView
                }
                .padding(6)
            }
            .sheet(isPresented: $showTransactionInputSheet) {
                TransactionInput()
                    .environmentObject(categoryDataModel)
                    .environmentObject(currencyDataModel)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
            .sheet(item: $transactionToEdit) { transaction in
                EditTransaction(transaction: transaction)
                    .environmentObject(categoryDataModel)
                    .environmentObject(currencyDataModel)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
            .sheet(isPresented: $showCalendarSheet) {
                CustomCalendarView(selectedDate: $selectedDate)
            }
        }

        // MARK: - Підкомпоненти View
        private var headerView: some View {
            HStack {
                Spacer()
                BudgetSummary(
                    monthlyBudget: monthlyBudget,
                    transactions: transactions,
                    color: categoryColor,
                    expectedBalance: expectedBalanceUAH,
                    actualBalance: actualBalanceUAH
                )
                Spacer()
                HStack {
                    // Кнопка для відкриття календаря
                    Button {
                        showCalendarSheet = true
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    
                    // Кнопка для відкриття форми транзакції
                    Button {
                        showTransactionInputSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                }
                .padding(.bottom, 100)
            }
        }

        private var addTransactionButton: some View {
            HStack {
                Spacer()
                Button {
                    showTransactionInputSheet = true
                } label: {
                    Text("Додати транзакцію")
                        .transactionButtonStyle(
                            isSelected: false,
                            color: categoryDataModel.colors["Всі"] ?? .gray
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 10)
            }
        }


        private var transactionHistoryView: some View {
            VStack(alignment: .leading) {
                headerForTransactionHistory
                Divider()
                if showFullTransactionList {
                    fullTransactionListView
                } else {
                    compactTransactionListView
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: showFullTransactionList ? nil : 360)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
        }

        private var headerForTransactionHistory: some View {
            HStack {
                Text("Історія транзакцій:")
                    .font(.headline)
                    .padding(.leading, 8)
                Spacer()
                Button {
                    withAnimation { showFullTransactionList.toggle() }
                } label: {
                    Image(systemName: "list.bullet")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
            }
            .padding(.top, 10)
            .padding(.horizontal, 5)
        }

        private var fullTransactionListView: some View {
            ScrollView(.vertical) {
                LazyVStack(spacing: 10) {
                    ForEach(transactions, id: \.wrappedId) { transaction in
                        TransactionCell(
                            transaction: transaction,
                            color: categoryDataModel.colors[transaction.validCategory] ?? .gray,
                            onEdit: { transactionToEdit = transaction },
                            onDelete: { deleteTransaction(transaction) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }

        private var compactTransactionListView: some View {
            VStack(spacing: 10) {
                ForEach(transactions.prefix(3), id: \.wrappedId) { transaction in
                    TransactionCell(
                        transaction: transaction,
                        color: categoryDataModel.colors[transaction.validCategory] ?? .gray,
                        onEdit: { transactionToEdit = transaction },
                        onDelete: { deleteTransaction(transaction) }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }

        // MARK: - Компонент BudgetSummary
        struct BudgetSummary: View {
            let monthlyBudget: Double
            let transactions: FetchedResults<Transaction>
            let color: Color
            let expectedBalance: Double
            let actualBalance: Double

            var body: some View {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(actualBalance, specifier: "%.2f") ₴")
                            .font(.system(size: 60, weight: .bold))
                        Text("\(expectedBalance, specifier: "%.2f") ₴")
                            .font(.system(size: 30, weight: .medium))
                    }
                    .padding()
                    .fixedSize()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}


// MARK: - Підкомпоненти для TransactionInput та InputField
extension TransactionsMainView.BudgetSummaryView {
    struct TransactionInput: View {
        @Environment(\.managedObjectContext) private var viewContext
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @EnvironmentObject var currencyDataModel: CurrencyDataModel
        @Environment(\.presentationMode) var presentationMode

        @State private var firstAmount = ""
        @State private var secondAmount = ""
        @State private var firstCurrencyCode = "UAH"
        @State private var secondCurrencyCode = "PLN"
        @State private var selectedCategory = "Їжа"
        @State private var comment = ""

        private var currencyManager: CurrencyManager {
            CurrencyManager(currencyDataModel: currencyDataModel)
        }

        var body: some View {
            NavigationStack {
                VStack(alignment: .center, spacing: 12) {
                    InputField(title: "Сума", text: $firstAmount)
                    Picker("Валюта", selection: $firstCurrencyCode) {
                        ForEach(Array(currencyManager.currencies.keys), id: \.self) { code in
                            if let symbol = currencyManager.currencies[code]?.symbol {
                                Text("\(code) (\(symbol))")
                            } else {
                                Text(code)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    InputField(title: "Сума", text: $secondAmount)
                    Picker("Валюта", selection: $secondCurrencyCode) {
                        ForEach(Array(currencyManager.currencies.keys), id: \.self) { code in
                            if let symbol = currencyManager.currencies[code]?.symbol {
                                Text("\(code) (\(symbol))")
                            } else {
                                Text(code)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    categoryPicker
                    commentField
                    saveTransactionButton
                }
                .padding()
                .background(cardBackground)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
        }

        private var cardBackground: Color {
            Color(NSColor.windowBackgroundColor)
        }

        private func closeView() {
            presentationMode.wrappedValue.dismiss()
        }

        private func addTransaction() {
            guard let firstAmt = Double(firstAmount),
                  let secondAmt = Double(secondAmount) else {
                print("Невірний формат суми")
                return
            }

            let success = TransactionService.addTransaction(
                firstAmount: firstAmt,
                firstCurrencyCode: firstCurrencyCode,
                secondAmount: secondAmt,
                secondCurrencyCode: secondCurrencyCode,
                selectedCategory: selectedCategory,
                comment: comment,
                currencyManager: currencyManager,
                in: viewContext
            )
            if success {
                firstAmount = ""
                secondAmount = ""
                comment = ""
                closeView()
            }
        }

        private var categoryPicker: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Категорія:")
                    .font(.caption)
                    .foregroundColor(.gray)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" }, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .transactionButtonStyle(
                                        isSelected: selectedCategory == category,
                                        color: categoryDataModel.colors[category] ?? .gray
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }

        private var commentField: some View {
            TextField("Коментар", text: $comment)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }

        private var saveTransactionButton: some View {
            Button(action: addTransaction) {
                Text("Зберегти транзакцію")
                    .transactionButtonStyle(
                        isSelected: false,
                        color: categoryDataModel.colors["Всі"] ?? .gray
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }

        struct InputField: View {
            let title: String
            @Binding var text: String

            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("0.00", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                        )
                        .foregroundColor(.white)
                }
            }
        }
    }
}
