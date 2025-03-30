import SwiftUI
import CoreData

// MARK: - TransactionsMainView та супутні компоненти
struct TransactionsMainView: View {
    @Binding var selectedCategoryFilter: String
    @Binding var categoryFilterType: CategoryFilterType
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<Transaction>
    
    private let monthlyBudget: Double = 20000.0
    
    var body: some View {
        switch selectedCategoryFilter {
        case "Логотип":
            BudgetSummaryListView(
                monthlyBudget: monthlyBudget,
                transactions: transactions,
                categoryColor: categoryDataModel.colors["Всі"] ?? .gray
            )
        case "Всі":
            AllCategoriesSummaryView(
                transactions: transactions,
                categoryFilterType: $categoryFilterType
            )
        case "Поповнення":
            TotalRepliesSummaryView(
                transactions: transactions,
                selectedCategoryFilter: selectedCategoryFilter
            )
        case "API":
            APITransactionsView(
                transactions: transactions,
                categoryDataModel: categoryDataModel
            )
        default:
            SelectedCategoryDetailsView(
                transactions: transactions,
                selectedCategoryFilter: selectedCategoryFilter
            )
        }
    }
}

extension TransactionsMainView {
    struct BudgetSummaryListView: View {
        let monthlyBudget: Double
        let transactions: FetchedResults<Transaction>
        let categoryColor: Color
        
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @Environment(\.managedObjectContext) private var viewContext  // Додано контекст Core Data
        @State private var transactionToEdit: Transaction?
        @State private var showTransactionInputSheet: Bool = false
        @State private var showFullTransactionList: Bool = false
        
        private let initialBalance: Double = 29703.54
        private let currencyManager = CurrencyManager()
        
        // Викликаємо методи з PersistenceController для розрахунків
        private var totalExpensesUAH: Double {
            PersistenceController.shared.totalExpenses(for: transactions, in: "UAH", using: currencyManager)
        }
        
        private var totalReplenishmentUAH: Double {
            PersistenceController.shared.totalReplenishment(for: transactions, in: "UAH", using: currencyManager)
        }
        
        private var totalToOtherAccountUAH: Double {
            PersistenceController.shared.totalToOtherAccount(for: transactions, in: "UAH", using: currencyManager)
        }
        
        private var averageRate: Double {
            PersistenceController.shared.averageExchangeRate(for: transactions, baseCurrency: "UAH", using: currencyManager)
        }
        
        private var expectedBalanceUAH: Double {
            monthlyBudget - totalExpensesUAH
        }
        
        private var actualBalanceUAH: Double {
            initialBalance + totalReplenishmentUAH - totalExpensesUAH - totalToOtherAccountUAH
        }
        
        // Функція для видалення транзакції
        private func deleteTransaction(_ transaction: Transaction) {
            TransactionService.deleteTransaction(transaction, in: viewContext)
        }
        
        var body: some View {
            ScrollView(.vertical) {
                LazyVStack(alignment: .center, spacing: 10) {
                    BudgetSummary(
                        monthlyBudget: monthlyBudget,
                        transactions: transactions,
                        color: categoryColor,
                        expectedBalance: expectedBalanceUAH,
                        actualBalance: actualBalanceUAH
                    )
                    Spacer()
                    Button(action: { showTransactionInputSheet = true }) {
                        Text("Додати транзакцію")
                            .transactionButtonStyle(
                                isSelected: false,
                                color: categoryDataModel.colors["Всі"] ?? .gray
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 10)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Історія транзакцій:")
                                .font(.headline)
                                .padding(.leading, 8)
                            Spacer()
                            Button(action: {
                                withAnimation { showFullTransactionList.toggle() }
                            }) {
                                Image(systemName: "list.bullet")
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 5)
                        Divider()
                        
                        if showFullTransactionList {
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
                        } else {
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
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: showFullTransactionList ? nil : 360)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(6)
            }
            .sheet(isPresented: $showTransactionInputSheet) {
                TransactionInput()
                    .environmentObject(categoryDataModel)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
            .sheet(item: $transactionToEdit) { transaction in
                EditTransaction(transaction: transaction)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
        
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
        
        struct TransactionInput: View {
            @Environment(\.managedObjectContext) private var viewContext
            @EnvironmentObject var categoryDataModel: CategoryDataModel
            @Environment(\.presentationMode) var presentationMode
            
            // Два поля для введення сум та відповідні коди валюти
            @State private var firstAmount = ""
            @State private var secondAmount = ""
            @State private var firstCurrencyCode = "UAH"
            @State private var secondCurrencyCode = "PLN"
            @State private var selectedCategory = "Їжа"
            @State private var comment = ""
            
            private let currencyManager = CurrencyManager()
            
            var body: some View {
                NavigationStack {
                    VStack(alignment: .center, spacing: 12) {
                        // Поле введення для першої суми
                        InputField(title: "Сума", text: $firstAmount)
                        // Picker для вибору коду валюти для першої суми
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
                        
                        // Поле введення для другої суми
                        InputField(title: "Сума", text: $secondAmount)
                        // Picker для вибору коду валюти для другої суми
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
                        
                        // Вибір категорії
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Категорія:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" }, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                        }) {
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
                        
                        TextField("Коментар", text: $comment)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        
                        Button(action: addTransaction) {
                            Text("Зберегти транзакцію")
                                .transactionButtonStyle(
                                    isSelected: false,
                                    color: categoryDataModel.colors["Всі"] ?? .gray
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
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
                
                let success = TransactionService.addTransaction(firstAmount: firstAmt,
                                                                firstCurrencyCode: firstCurrencyCode,
                                                                secondAmount: secondAmt,
                                                                secondCurrencyCode: secondCurrencyCode,
                                                                selectedCategory: selectedCategory,
                                                                comment: comment,
                                                                in: viewContext)
                if success {
                    firstAmount = ""
                    secondAmount = ""
                    comment = ""
                    closeView()
                }
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
}


extension TransactionsMainView {
    struct AllCategoriesSummaryView: View {
        let transactions: FetchedResults<Transaction>
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @Binding var categoryFilterType: CategoryFilterType
        private let currencyManager = CurrencyManager()
        
        private var sortedCategories: [String] {
            let categories = categoryDataModel.filterOptions.filter { $0 != "Поповнення" && $0 != "API" && $0 != "Всі" }
            
            switch categoryFilterType {
            case .count:
                return categories.sorted { lhs, rhs in
                    let lhsCount = transactions.filter { $0.validCategory == lhs }.count
                    let rhsCount = transactions.filter { $0.validCategory == rhs }.count
                    return lhsCount > rhsCount
                }
            case .alphabetical:
                return categories.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            case .expenses:
                return categories.sorted { lhs, rhs in
                    let lhsExpenses = PersistenceController.shared.totalExpenses(
                        for: transactions.filter { $0.validCategory == lhs },
                        in: "UAH", using: currencyManager
                    )
                    let rhsExpenses = PersistenceController.shared.totalExpenses(
                        for: transactions.filter { $0.validCategory == rhs },
                        in: "UAH", using: currencyManager
                    )
                    return lhsExpenses > rhsExpenses
                }
            }
        }
        
        var body: some View {
            List {
                totalExpensesSummary
                replenishmentSummary
                ForEach(sortedCategories, id: \.self) { category in
                    CategoryExpenseSummary(
                        category: category,
                        transactions: transactions,
                        color: categoryDataModel.colors[category] ?? .gray,
                        currencyManager: currencyManager
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
        
        private var totalExpensesSummary: some View {
            let totalUAH = PersistenceController.shared.totalExpenses(
                for: transactions.filter {
                    $0.validCategory != "Поповнення" &&
                    $0.validCategory != "На інший рахунок" &&
                    $0.validCategory != "API"
                },
                in: "UAH", using: currencyManager
            )
            let totalPLN = PersistenceController.shared.totalExpenses(
                for: transactions.filter {
                    $0.validCategory != "Поповнення" &&
                    $0.validCategory != "На інший рахунок" &&
                    $0.validCategory != "API"
                },
                in: "PLN", using: currencyManager
            )
            let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
            
            return SummaryView(
                title: "Усі витрати",
                amountUAH: totalUAH,
                amountPLN: totalPLN,
                rate: rate,
                color: categoryDataModel.colors["Всі"] ?? .gray
            )
        }
        
        private var replenishmentSummary: some View {
            let totalUAH = PersistenceController.shared.totalReplenishment(
                for: transactions.filter { $0.validCategory == "Поповнення" },
                in: "UAH", using: currencyManager
            )
            let totalPLN = PersistenceController.shared.totalReplenishment(
                for: transactions.filter { $0.validCategory == "Поповнення" },
                in: "PLN", using: currencyManager
            )
            let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
            
            return SummaryView(
                title: "Поповнення",
                amountUAH: totalUAH,
                amountPLN: totalPLN,
                rate: rate,
                color: categoryDataModel.colors["Поповнення"] ?? .gray
            )
        }
        
        struct CategoryExpenseSummary: View {
            let category: String
            let transactions: FetchedResults<Transaction>
            let color: Color
            let currencyManager: CurrencyManager
            
            var body: some View {
                let totalUAH = PersistenceController.shared.totalExpenses(
                    for: transactions.filter { $0.validCategory == category },
                    in: "UAH", using: currencyManager
                )
                let totalPLN = PersistenceController.shared.totalExpenses(
                    for: transactions.filter { $0.validCategory == category },
                    in: "PLN", using: currencyManager
                )
                let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
                return SummaryView(
                    title: category,
                    amountUAH: totalUAH,
                    amountPLN: totalPLN,
                    rate: rate,
                    color: color
                )
            }
        }
        
        struct SummaryView: View {
            let title: String
            let amountUAH: Double
            let amountPLN: Double
            let rate: Double
            let color: Color
            
            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(title):")
                            .font(.headline)
                            .foregroundColor(color)
                        Spacer()
                    }
                    HStack {
                        Text("UAH: \(amountUAH, format: .number.precision(.fractionLength(2)))")
                        Spacer()
                        Text("PLN: \(amountPLN, format: .number.precision(.fractionLength(2)))")
                        Spacer()
                        Text("Курс: \(rate, format: .number.precision(.fractionLength(2)))")
                    }
                }
                .padding()
                .background(color.opacity(0.2))
                .cornerRadius(8)
                .padding(.vertical, 4)
            }
        }
    }
}


extension TransactionsMainView {
    struct TotalRepliesSummaryView: View {
        let transactions: FetchedResults<Transaction>
        let selectedCategoryFilter: String
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @State private var transactionToEdit: Transaction?
        private let currencyManager = CurrencyManager()
        
        var body: some View {
            // Фільтруємо транзакції за категорією "Поповнення"
            let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
            return VStack {
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
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
        
        private func deleteTransaction(_ transaction: Transaction) {
            let viewContext = PersistenceController.shared.container.viewContext
            viewContext.delete(transaction)
            do {
                try viewContext.save()
            } catch {
                print("Помилка видалення: \(error.localizedDescription)")
            }
        }
        
        struct ReplenishmentHeader: View {
            let transactions: [Transaction]
            let color: Color
            let currencyManager: CurrencyManager
            
            var body: some View {
                // Виклик методу з PersistenceController для розрахунку поповнень
                let totalUAH = PersistenceController.shared.totalReplenishment(for: transactions, in: "UAH", using: currencyManager)
                return VStack(spacing: 8) {
                    Text("Загальна сума поповнень в UAH: \(totalUAH, format: .number.precision(.fractionLength(2)))")
                }
                .padding()
                .background(color.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }
}


extension TransactionsMainView {
    struct SelectedCategoryDetailsView: View {
        let transactions: FetchedResults<Transaction>
        let selectedCategoryFilter: String
        @EnvironmentObject var categoryDataModel: CategoryDataModel
        @State private var transactionToEdit: Transaction?
        private let currencyManager = CurrencyManager()
        
        var body: some View {
            let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
            return VStack {
                CategoryHeader(
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
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
        
        private func deleteTransaction(_ transaction: Transaction) {
            let viewContext = PersistenceController.shared.container.viewContext
            viewContext.delete(transaction)
            do {
                try viewContext.save()
            } catch {
                print("Помилка видалення: \(error.localizedDescription)")
            }
        }
        
        struct CategoryHeader: View {
            let transactions: [Transaction]
            let color: Color
            let currencyManager: CurrencyManager
            
            var body: some View {
                let totalUAH = PersistenceController.shared.totalExpenses(
                    for: transactions,
                    in: "UAH", using: currencyManager
                )
                let totalPLN = PersistenceController.shared.totalExpenses(
                    for: transactions,
                    in: "PLN", using: currencyManager
                )
                let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
                return VStack(spacing: 8) {
                    Text("Загальна сума витрат в UAH: \(totalUAH, format: .number.precision(.fractionLength(2)))")
                    Text("Загальна сума витрат в PLN: \(totalPLN, format: .number.precision(.fractionLength(2)))")
                    Text("Курс: \(rate, format: .number.precision(.fractionLength(2)))")
                }
                .padding()
                .background(color.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }
}


extension TransactionsMainView {
    struct APITransactionsView: View {
        let transactions: FetchedResults<Transaction>
        let categoryDataModel: CategoryDataModel
        @Environment(\.managedObjectContext) private var viewContext
        @State private var transactionToEdit: Transaction?
        
        var body: some View {
            VStack {
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
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }
}


// MARK: - Global Shared Views
struct EditTransaction: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var transaction: Transaction

    @State private var editedFirstAmount: String
    @State private var editedSecondAmount: String
    @State private var selectedFirstCurrency: String
    @State private var selectedSecondCurrency: String
    @State private var selectedCategory: String
    @State private var editedComment: String

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
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
            Spacer()
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
            Text(title).font(.headline)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
    }

    private func currencyPickerSection(title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Picker("", selection: selection) {
                ForEach(["UAH", "PLN"], id: \.self) { code in
                    Text(code)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }

    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Категорія:").font(.headline)
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

    private func closeView() {
        presentationMode.wrappedValue.dismiss()
    }

    private func saveChanges() {
        guard let firstAmt = Double(editedFirstAmount),
              let secondAmt = Double(editedSecondAmount) else { return }

        let success = TransactionService.updateTransaction(
            transaction,
            newFirstAmount: firstAmt,
            newFirstCurrencyCode: selectedFirstCurrency,
            newSecondAmount: secondAmt,
            newSecondCurrencyCode: selectedSecondCurrency,
            newCategory: selectedCategory,
            newComment: editedComment,
            in: viewContext
        )
        if success {
            closeView()
        }
    }
}



struct TransactionCell: View {
    let transaction: Transaction
    let color: Color
    let onEdit: () -> Void
    let onDelete: () -> Void
    private let currencyManager = CurrencyManager()
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        // Отримуємо коди валют із транзакції, або базовий, якщо не вказано
        let firstCode = transaction.firstCurrencyCode ?? currencyManager.baseCurrencyCode
        let secondCode = transaction.secondCurrencyCode ?? currencyManager.baseCurrencyCode
        let firstCurrencyInfo = currencyManager.currencies[firstCode]
        let secondCurrencyInfo = currencyManager.currencies[secondCode]
        
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                // Відображення першої суми з відповідним символом валюти
                Text("\(transaction.firstAmount, specifier: "%.2f") \(firstCurrencyInfo?.symbol ?? firstCode)")
                    .font(.headline)
                // Відображення другої суми з відповідним символом валюти
                Text("\(transaction.secondAmount, specifier: "%.2f") \(secondCurrencyInfo?.symbol ?? secondCode)")
                // Розрахунок курсу як відношення першої суми до другої (якщо друга не 0)
                Text("Курс: \(transaction.secondAmount != 0 ? (transaction.firstAmount / transaction.secondAmount) : 0, specifier: "%.2f")")
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
