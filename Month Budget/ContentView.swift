import SwiftUI
import CoreData

// MARK: - Модель даних категорій
final class CategoryDataModel: ObservableObject {
    @Published var filterOptions: [String] = [
        "Всі", "Поповнення", "Їжа", "Проживання", "Здоровʼя та краса",
        "Інтернет послуги", "Транспорт", "Розваги та спорт",
        "Приладдя для дому", "Благо", "Електроніка", "На інший рахунок", "Інше"
    ]
    
    @Published var colors: [String: Color] = [
        "Всі": Color(red: 0.9, green: 0.9, blue: 0.9),
        "Поповнення": Color(red: 0.0, green: 0.7, blue: 0.2),
        "Їжа": Color(red: 1.0, green: 0.6, blue: 0.0),
        "Проживання": Color(red: 0.0, green: 0.48, blue: 1.0),
        "Здоровʼя та краса": Color(red: 1.0, green: 0.41, blue: 0.71),
        "Інтернет послуги": Color(red: 0.0, green: 0.98, blue: 1.0),
        "Транспорт": Color(red: 0.0, green: 0.8, blue: 0.4),
        "Розваги та спорт": Color(red: 0.58, green: 0.0, blue: 0.83),
        "Приладдя для дому": Color(red: 0.5, green: 0.5, blue: 0.5),
        "Благо": Color(red: 0.74, green: 0.98, blue: 0.79),
        "Електроніка": Color(red: 0.0, green: 0.5, blue: 0.5),
        "На інший рахунок": Color(red: 0.7, green: 0.2, blue: 0.3),
        "Інше": Color(red: 0.29, green: 0.0, blue: 0.51)
    ]
}

// MARK: - MainAppView
struct MainAppView: View {
    @State private var selectedCategoryFilter = "Всі"
    @StateObject private var categoryDataModel = CategoryDataModel()
    
    var body: some View {
        HStack {
            Divider()
            SidebarView(selectedCategoryFilter: $selectedCategoryFilter)
                .environmentObject(categoryDataModel)
            Divider()
            VStack {
                // TransactionInputView() можна використовувати для введення нових транзакцій.
                TransactionsMainView(selectedCategoryFilter: $selectedCategoryFilter)
                    .environmentObject(categoryDataModel)
            }
            Divider()
        }
    }
}

// MARK: - SidebarView
struct SidebarView: View {
    @Binding var selectedCategoryFilter: String

    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                withAnimation {
                    selectedCategoryFilter = "Логотип" // спеціальне значення для логотипу
                }
            }) {
                Image("1024centered-white-nobg")
                    .resizable()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(radius: 5)
                    .padding(.bottom, 10)
            }
            .buttonStyle(PlainButtonStyle())

            HStack {
                Text("Категорії:")
                    .font(.headline)
                Spacer()
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            Divider()
            CategoryFiltersView(selectedCategoryFilter: $selectedCategoryFilter)
        }
        .frame(width: 180)
    }
}

// MARK: - CategoryFiltersView
struct CategoryFiltersView: View {
    @Binding var selectedCategoryFilter: String
    @State private var showRenameCategoryView = false
    @State private var showCategoryManagementView = false
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    
    @FetchRequest(sortDescriptors: [])
    private var transactions: FetchedResults<Transaction>
    
    private var sortedCategories: [String] {
        let others = categoryDataModel.filterOptions
            .dropFirst()
            .filter { $0 != "Поповнення" }
            .sorted { lhs, rhs in
                let lhsCount = transactions.filter { $0.validCategory == lhs }.count
                let rhsCount = transactions.filter { $0.validCategory == rhs }.count
                return lhsCount > rhsCount
            }
        return [categoryDataModel.filterOptions.first ?? "Всі"] + ["Поповнення"] + others
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(sortedCategories, id: \.self) { option in
                    Button(action: { withAnimation { selectedCategoryFilter = option } }) {
                        Text(option)
                            .categoryButtonStyle(
                                isSelected: selectedCategoryFilter == option,
                                color: categoryDataModel.colors[option] ?? .gray
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if selectedCategoryFilter != "Всі" && selectedCategoryFilter != "Поповнення" {
                    Button("Перейменувати категорію") {
                        showRenameCategoryView = true
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top)
                    .sheet(isPresented: $showRenameCategoryView) {
                        RenameCategoryView(currentCategory: $selectedCategoryFilter)
                            .environmentObject(categoryDataModel)
                    }
                }
                Button("Управління категоріями") {
                    showCategoryManagementView = true
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top)
                .sheet(isPresented: $showCategoryManagementView) {
                    CategoryManagementView()
                        .environmentObject(categoryDataModel)
                }
                Spacer()
            }
            .padding(.vertical)
            .frame(width: 180)
        }
    }
}

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - RenameCategoryView
struct RenameCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @Binding var currentCategory: String
    @State private var newName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Перейменування категорії")) {
                    Text("Поточна категорія: \(currentCategory)")
                    TextField("Нове ім'я", text: $newName)
                }
                Button("Зберегти") {
                    guard !newName.isEmpty else { return }
                    renameCategory(oldName: currentCategory, newName: newName, in: viewContext, categoryDataModel: categoryDataModel)
                    currentCategory = newName
                    dismiss()
                }
            }
            .navigationTitle("Перейменувати")
        }
    }
}

func renameCategory(oldName: String, newName: String, in context: NSManagedObjectContext, categoryDataModel: CategoryDataModel) {
    let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "category == %@", oldName)
    
    do {
        let transactionsToUpdate = try context.fetch(fetchRequest)
        transactionsToUpdate.forEach { $0.category = newName }
        try context.save()
        print("Оновлено \(transactionsToUpdate.count) транзакцій з категорії \(oldName) на \(newName)")
        
        if let index = categoryDataModel.filterOptions.firstIndex(of: oldName) {
            categoryDataModel.filterOptions[index] = newName
        }
        if let oldColor = categoryDataModel.colors[oldName] {
            categoryDataModel.colors[newName] = oldColor
            categoryDataModel.colors.removeValue(forKey: oldName)
        }
    } catch {
        print("Помилка оновлення транзакцій: \(error.localizedDescription)")
    }
}

// MARK: - CategoryManagementView
struct CategoryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @Environment(\.dismiss) var dismiss
    @State private var newCategoryName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Додати категорію")) {
                    HStack {
                        TextField("Нова категорія", text: $newCategoryName)
                        Button("Додати", action: addCategory)
                    }
                }
                Section(header: Text("Існуючі категорії")) {
                    ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" && $0 != "Поповнення" }, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Button {
                                deleteCategory(category)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Управління категоріями")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Додати") { print("Натиснуто") }
                }
            }
        }
    }
    
    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !categoryDataModel.filterOptions.contains(trimmed) else { return }
        
        categoryDataModel.filterOptions.append(trimmed)
        categoryDataModel.colors[trimmed] = Color.gray
        newCategoryName = ""
    }
    
    private func deleteCategory(_ category: String) {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let transactionsToUpdate = try viewContext.fetch(fetchRequest)
            transactionsToUpdate.forEach { $0.category = "Інше" }
            try viewContext.save()
        } catch {
            print("Помилка переназначення транзакцій: \(error.localizedDescription)")
        }
        
        if let index = categoryDataModel.filterOptions.firstIndex(of: category) {
            categoryDataModel.filterOptions.remove(at: index)
        }
        categoryDataModel.colors.removeValue(forKey: category)
    }
}

// MARK: - TransactionsMainView
struct TransactionsMainView: View {
    @Binding var selectedCategoryFilter: String
    @State private var transactionToEdit: Transaction?
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<Transaction>
    
    private let monthlyBudget: Double = 20000.0
    
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
        content
            .sheet(item: $transactionToEdit) { transaction in
                EditTransactionView(transaction: transaction)
                    .environment(\.managedObjectContext, viewContext)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch selectedCategoryFilter {
        case "Логотип":
            budgetSummaryListView
        case "Всі":
            allCategoriesSummaryView
        case "Поповнення":
            totalRepliesSummaryView
        default:
            selectedCategoryDetailsView
        }
    }
    
    private var budgetSummaryListView: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .center, spacing: 10) {
                BudgetSummaryView(
                    monthlyBudget: monthlyBudget,
                    transactions: transactions,
                    color: categoryDataModel.colors["Всі"] ?? .gray
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
    }
    
    private var allCategoriesSummaryView: some View {
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
    
    private var totalRepliesSummaryView: some View {
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
    }
    
    private var selectedCategoryDetailsView: some View {
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
    
    private func deleteTransaction(_ transaction: Transaction) {
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

// MARK: - Text Extension для стилізації кнопок
extension Text {
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

// MARK: - Допоміжні компоненти та розширення
extension Transaction {
    var wrappedId: UUID { id ?? UUID() }
    var validCategory: String { category ?? "Інше" }
}

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
}
