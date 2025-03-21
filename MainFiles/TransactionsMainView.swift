import SwiftUI
import CoreData

// MARK: - TransactionsMainView
struct TransactionsMainView: View {
    @Binding var selectedCategoryFilter: String
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<Transaction>
    
    private let monthlyBudget: Double = 20000.0
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        switch selectedCategoryFilter {
        case "Логотип":
            BudgetSummaryListView(
                monthlyBudget: monthlyBudget,
                transactions: transactions,
                categoryColor: categoryDataModel.colors["Всі"] ?? .gray
            )
        case "Всі":
            AllCategoriesSummaryView(transactions: transactions)
        case "Поповнення":
            TotalRepliesSummaryView(transactions: transactions, selectedCategoryFilter: selectedCategoryFilter)
        default:
            SelectedCategoryDetailsView(transactions: transactions, selectedCategoryFilter: selectedCategoryFilter)
        }
    }
}

struct BudgetSummaryListView: View {
    let monthlyBudget: Double
    let transactions: FetchedResults<Transaction>
    let categoryColor: Color
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @State private var transactionToEdit: Transaction?

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .center, spacing: 10) {
                BudgetSummaryView(
                    monthlyBudget: monthlyBudget,
                    transactions: transactions,
                    color: categoryColor
                )
                Spacer()
                TransactionInputView()
                    .environmentObject(categoryDataModel)
                
                VStack(alignment: .leading) {
                    Spacer()
                    Text("Історія транзакцій:")
                        .font(.headline)
                        .padding(.leading, 8)
                    Divider()
                    
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
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
            }
            .padding(6)
        }
        .sheet(item: $transactionToEdit) { transaction in
            EditTransactionView(transaction: transaction)
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
}

struct AllCategoriesSummaryView: View {
    let transactions: FetchedResults<Transaction>
    @EnvironmentObject var categoryDataModel: CategoryDataModel

    private var sortedCategories: [String] {
        categoryDataModel.filterOptions
            .dropFirst()
            .filter { $0 != "Поповнення" }
            .sorted { lhs, rhs in
                transactions.filter { $0.validCategory == lhs }.count >
                transactions.filter { $0.validCategory == rhs }.count
            }
    }
    
    var body: some View {
        List {
            totalExpensesSummary
            replenishmentSummary
            ForEach(sortedCategories, id: \.self) { category in
                CategoryExpenseSummaryView(
                    category: category,
                    transactions: transactions,
                    color: categoryDataModel.colors[category] ?? .gray
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var totalExpensesSummary: some View {
        let expenses = transactions.filter {
            $0.validCategory != "Поповнення" &&
            $0.validCategory != "На інший рахунок"
        }
        let totalUAH = expenses.reduce(0) { $0 + $1.amountUAH }
        let totalPLN = expenses.reduce(0) { $0 + $1.amountPLN }
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
        let replenishments = transactions.filter { $0.validCategory == "Поповнення" }
        let totalUAH = replenishments.reduce(0) { $0 + $1.amountUAH }
        let totalPLN = replenishments.reduce(0) { $0 + $1.amountPLN }
        let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
        
        return SummaryView(
            title: "Поповнення",
            amountUAH: totalUAH,
            amountPLN: totalPLN,
            rate: rate,
            color: categoryDataModel.colors["Поповнення"] ?? .gray
        )
    }
}

struct TotalRepliesSummaryView: View {
    let transactions: FetchedResults<Transaction>
    let selectedCategoryFilter: String
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @State private var transactionToEdit: Transaction?

    var body: some View {
        let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
        return VStack {
            ReplenishmentHeaderView(
                transactions: filteredTransactions,
                color: categoryDataModel.colors[selectedCategoryFilter] ?? .gray
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
            EditTransactionView(transaction: transaction)
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
}

struct SelectedCategoryDetailsView: View {
    let transactions: FetchedResults<Transaction>
    let selectedCategoryFilter: String
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @State private var transactionToEdit: Transaction?
    
    var body: some View {
        let filteredTransactions = transactions.filter { $0.validCategory == selectedCategoryFilter }
        return VStack {
            CategoryHeaderView(
                transactions: filteredTransactions,
                color: categoryDataModel.colors[selectedCategoryFilter] ?? .gray
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
            EditTransactionView(transaction: transaction)
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
}






// MARK: - TransactionInputView
struct TransactionInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @State private var amountUAH = ""
    @State private var amountPLN = ""
    @State private var selectedCategory = "Їжа"
    @State private var comment = ""
    @State private var isPresented = false

    private let darkBackground = Color(red: 0.2, green: 0.2, blue: 0.2)

    var body: some View {
        VStack(spacing: 12) {
            toggleButton
            if isPresented {
                inputFormSection
            }
        }
        .padding(12)
        .background(darkBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
    
    private var toggleButton: some View {
        Button(action: {
            withAnimation { isPresented.toggle() }
        }) {
            Text(isPresented ? "Закрити" : "Додати витрати")
                .transactionButtonStyle(
                    isSelected: false,
                    color: categoryDataModel.colors["Всі"] ?? .gray
                )
        }
        .frame(height: 35)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var inputFormSection: some View {
        VStack(spacing: 12) {
            currencyInputFields
            categoryButtonsSection
            commentField
            Button(action: addTransaction) {
                Text("Зберегти транзакцію")
                    .transactionButtonStyle(
                        isSelected: false,
                        color: categoryDataModel.colors["Всі"] ?? .gray
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var currencyInputFields: some View {
        HStack(spacing: 12) {
            InputField(title: "UAH", text: $amountUAH)
            Divider()
                .frame(height: 40)
                .background(Color.gray)
            InputField(title: "PLN", text: $amountPLN)
        }
    }
    
    private var categoryButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Категорія:")
                .font(.caption)
                .foregroundColor(.gray)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categoryDataModel.filterOptions.dropFirst(), id: \.self) { category in
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
    }
    
    private var commentField: some View {
        TextField("Коментар", text: $comment)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
    
    private func addTransaction() {
        guard let uah = Double(amountUAH),
              let pln = Double(amountPLN) else {
            print("Невірний формат суми")
            return
        }
        
        let newTransaction = Transaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.amountUAH = uah
        newTransaction.amountPLN = pln
        newTransaction.category = selectedCategory
        newTransaction.comment = comment
        newTransaction.date = Date()
        
        do {
            try viewContext.save()
            amountUAH = ""
            amountPLN = ""
            comment = ""
            isPresented = false
            print("Транзакцію додано успішно!")
        } catch {
            print("Помилка додавання транзакції: \(error.localizedDescription)")
        }
    }
}

// MARK: - InputField
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

// MARK: - CategoryExpenseSummaryView
struct CategoryExpenseSummaryView: View {
    let category: String
    let transactions: FetchedResults<Transaction>
    let color: Color
    
    var body: some View {
        let sumUAH = transactions.filter { $0.validCategory == category }.reduce(0) { $0 + $1.amountUAH }
        let sumPLN = transactions.filter { $0.validCategory == category }.reduce(0) { $0 + $1.amountPLN }
        let rate = sumPLN != 0 ? sumUAH / sumPLN : 0.0
        
        SummaryView(title: category, amountUAH: sumUAH, amountPLN: sumPLN, rate: rate, color: color)
    }
}

// MARK: - SummaryView
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

// MARK: - EditTransactionView
struct EditTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var transaction: Transaction

    @State private var editedAmountUAH: String
    @State private var editedAmountPLN: String
    @State private var selectedCategory: String
    @State private var editedComment: String

    init(transaction: Transaction) {
        self.transaction = transaction
        _editedAmountUAH = State(initialValue: String(format: "%.2f", transaction.amountUAH))
        _editedAmountPLN = State(initialValue: String(format: "%.2f", transaction.amountPLN))
        _selectedCategory = State(initialValue: transaction.category ?? "Їжа")
        _editedComment = State(initialValue: transaction.comment ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                inputSection(title: "UAH:", text: $editedAmountUAH)
                inputSection(title: "PLN:", text: $editedAmountPLN)
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
            Text(title)
                .font(.headline)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
    }
    
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Категорія:")
                .font(.headline)
            Picker("", selection: $selectedCategory) {
                ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" && $0 != "Поповнення" }, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var cardBackground: Color {
        return Color(NSColor.windowBackgroundColor)
    }
    
    private func closeView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveChanges() {
        guard let uah = Double(editedAmountUAH),
              let pln = Double(editedAmountPLN) else { return }
        
        transaction.amountUAH = uah
        transaction.amountPLN = pln
        transaction.category = selectedCategory
        transaction.comment = editedComment
        
        do {
            try viewContext.save()
            closeView()
        } catch {
            print("Помилка збереження: \(error.localizedDescription)")
        }
    }
}

// MARK: - CategoryHeaderView
struct CategoryHeaderView: View {
    let transactions: [Transaction]
    let color: Color
    
    var body: some View {
        let totalUAH = transactions.reduce(0) { $0 + $1.amountUAH }
        let totalPLN = transactions.reduce(0) { $0 + $1.amountPLN }
        let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
        
        VStack(spacing: 8) {
            Text("Загальна сума витрат в UAH: \(totalUAH, format: .number.precision(.fractionLength(2)))")
            Text("Загальна сума витрат в PLN: \(totalPLN, format: .number.precision(.fractionLength(2)))")
            Text("Курс: \(rate, format: .number.precision(.fractionLength(2)))")
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - ReplenishmentHeaderView
struct ReplenishmentHeaderView: View {
    let transactions: [Transaction]
    let color: Color
    
    var body: some View {
        let totalUAH = transactions.reduce(0) { $0 + $1.amountUAH }
        
        VStack(spacing: 8) {
            Text("Загальна сума поповнень в UAH: \(totalUAH, format: .number.precision(.fractionLength(2)))")
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - TransactionCell
struct TransactionCell: View {
    let transaction: Transaction
    let color: Color
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Text("\(transaction.amountUAH, format: .number.precision(.fractionLength(2)))₴")
                    .font(.headline)
                Text("\(transaction.amountPLN, format: .number.precision(.fractionLength(2)))zł")
                Text("Курс: \(transaction.amountPLN != 0 ? transaction.amountUAH / transaction.amountPLN : 0, format: .number.precision(.fractionLength(2)))")
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
        .frame(minWidth: 370, maxWidth: .infinity, minHeight: 35)
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - BudgetSummaryView (Підсумок бюджету для macOS)
struct BudgetSummaryView: View {
    let monthlyBudget: Double
    let transactions: FetchedResults<Transaction>
    let color: Color
    
    private let initialBalance: Double = 30165.86
    
    private var totalExpensesUAH: Double {
        transactions.filter {
            $0.validCategory != "Поповнення" &&
            $0.validCategory != "На інший рахунок"
        }
        .reduce(0) { $0 + $1.amountUAH }
    }
    private var totalExpensesPLN: Double {
        transactions.filter {
            $0.validCategory != "Поповнення" &&
            $0.validCategory != "На інший рахунок"
        }
        .reduce(0) { $0 + $1.amountPLN }
    }
    
    private var totalReplenishmentUAH: Double {
        transactions.filter { $0.validCategory == "Поповнення" }
            .reduce(0) { $0 + $1.amountUAH }
    }
    private var totalReplenishmentPLN: Double {
        transactions.filter { $0.validCategory == "Поповнення" }
            .reduce(0) { $0 + $1.amountPLN }
    }
    private var totalToOtherAccountUAH: Double {
        transactions.filter { $0.validCategory == "На інший рахунок" }
            .reduce(0) { $0 + $1.amountUAH }
    }
    private var totalToOtherAccountPLN: Double {
        transactions.filter { $0.validCategory == "На інший рахунок" }
            .reduce(0) { $0 + $1.amountPLN }
    }
    
    private var averageRate: Double {
        totalExpensesPLN != 0 ? totalExpensesUAH / totalExpensesPLN : 0.0
    }
    
    private var expectedBalanceUAH: Double { monthlyBudget - totalExpensesUAH }
    private var expectedBalancePLN: Double { averageRate != 0 ? expectedBalanceUAH / averageRate : 0.0 }
    
    private var actualBalanceUAH: Double { initialBalance + totalReplenishmentUAH - totalExpensesUAH - totalToOtherAccountUAH }
    private var actualBalancePLN: Double { averageRate != 0 ? actualBalanceUAH / averageRate : 0.0 }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(actualBalanceUAH, specifier: "%.2f") ₴")
                    .font(.system(size: 60, weight: .bold))
                Text("\(expectedBalanceUAH, specifier: "%.2f") ₴")
                    .font(.system(size: 30, weight: .medium))
            }
            .padding()
            .fixedSize()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
