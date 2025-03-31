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
                categoryDataModel: categoryDataModel,
                currencyManager: CurrencyManager()
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
        @Environment(\.managedObjectContext) private var viewContext
        @State private var transactionToEdit: Transaction?
        @State private var showTransactionInputSheet: Bool = false
        @State private var showFullTransactionList: Bool = false

        private let initialBalance: Double = 29703.54
        private let currencyManager = CurrencyManager()

        // Використовуємо нові функції з параметрами targetCurrency та currencyManager
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

        private var averageRate: Double {
            PersistenceController.shared.overallAverageExchangeRate(for: transactions.map { $0 })
        }

        private var expectedBalanceUAH: Double {
            monthlyBudget - totalExpensesUAH
        }

        private var actualBalanceUAH: Double {
            initialBalance + totalReplenishmentUAH - totalExpensesUAH - totalToOtherAccountUAH
        }

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

                let success = TransactionService.addTransaction(
                    firstAmount: firstAmt,
                    firstCurrencyCode: firstCurrencyCode,
                    secondAmount: secondAmt,
                    secondCurrencyCode: secondCurrencyCode,
                    selectedCategory: selectedCategory,
                    comment: comment,
                    in: viewContext
                )
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
                        targetCurrency: currencyManager.baseCurrency1,
                        currencyManager: currencyManager
                    )
                    let rhsExpenses = PersistenceController.shared.totalExpenses(
                        for: transactions.filter { $0.validCategory == rhs },
                        targetCurrency: currencyManager.baseCurrency1,
                        currencyManager: currencyManager
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
            let filteredTransactions = transactions.filter {
                $0.validCategory != "Поповнення" &&
                $0.validCategory != "На інший рахунок" &&
                $0.validCategory != "API"
            }
            let totalUAH = PersistenceController.shared.totalExpenses(
                for: filteredTransactions,
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
            let totalPLN = PersistenceController.shared.totalExpenses(
                for: filteredTransactions,
                targetCurrency: currencyManager.baseCurrency2,
                currencyManager: currencyManager
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
            let filteredTransactions = transactions.filter { $0.validCategory == "Поповнення" }
            let totalUAH = PersistenceController.shared.totalReplenishment(
                for: filteredTransactions,
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
            let totalPLN = PersistenceController.shared.totalReplenishment(
                for: filteredTransactions,
                targetCurrency: currencyManager.baseCurrency2,
                currencyManager: currencyManager
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
                            let filteredTransactions = transactions.filter { $0.validCategory == category }
                            let totalUAH: Double
                            let totalPLN: Double
                            
                            if category == "На інший рахунок" {
                                totalUAH = PersistenceController.shared.totalToOtherAccount(
                                    for: filteredTransactions,
                                    targetCurrency: currencyManager.baseCurrency1,
                                    currencyManager: currencyManager
                                )
                                totalPLN = PersistenceController.shared.totalToOtherAccount(
                                    for: filteredTransactions,
                                    targetCurrency: currencyManager.baseCurrency2,
                                    currencyManager: currencyManager
                                )
                            } else {
                                totalUAH = PersistenceController.shared.totalExpenses(
                                    for: filteredTransactions,
                                    targetCurrency: currencyManager.baseCurrency1,
                                    currencyManager: currencyManager
                                )
                                totalPLN = PersistenceController.shared.totalExpenses(
                                    for: filteredTransactions,
                                    targetCurrency: currencyManager.baseCurrency2,
                                    currencyManager: currencyManager
                                )
                            }
                            
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
                let totalUAH = PersistenceController.shared.totalReplenishment(for: transactions, targetCurrency: currencyManager.baseCurrency1, currencyManager: currencyManager)
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
            let selectedCategory: String
            let transactions: [Transaction]
            let color: Color
            let currencyManager: CurrencyManager

            var body: some View {
                let isOtherAccount = selectedCategory == "На інший рахунок"
                
                let totalUAH = isOtherAccount ?
                    PersistenceController.shared.totalToOtherAccount(for: transactions,
                                                                     targetCurrency: currencyManager.baseCurrency1,
                                                                     currencyManager: currencyManager)
                    :
                    PersistenceController.shared.totalExpenses(for: transactions,
                                                               targetCurrency: currencyManager.baseCurrency1,
                                                               currencyManager: currencyManager)
                
                let totalPLN = isOtherAccount ?
                    PersistenceController.shared.totalToOtherAccount(for: transactions,
                                                                     targetCurrency: currencyManager.baseCurrency2,
                                                                     currencyManager: currencyManager)
                    :
                    PersistenceController.shared.totalExpenses(for: transactions,
                                                               targetCurrency: currencyManager.baseCurrency2,
                                                               currencyManager: currencyManager)
                
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
}


extension TransactionsMainView {
    struct APITransactionsView: View {
        let transactions: FetchedResults<Transaction>
        let categoryDataModel: CategoryDataModel
        let currencyManager: CurrencyManager  // Додаємо менеджер валют
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
                        // Передаємо currencyManager у функцію fetchAPITransactions
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
    @StateObject var currencyManager = CurrencyManager()

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
        
        // Отримуємо всі транзакції з viewContext для пошуку актуального курсу конвертації
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
            transactions: transactionsArray,      // Передаємо масив транзакцій
            currencyManager: currencyManager,       // Передаємо об’єкт CurrencyManager
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
