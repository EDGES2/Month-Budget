import SwiftUI
import CoreData

// MARK: - Модель даних категорій
/// Клас для зберігання даних, пов'язаних з категоріями транзакцій.
/// Використовується як ObservableObject для автоматичного оновлення представлень.
final class CategoryDataModel: ObservableObject {
    /// Список категорій для фільтрації транзакцій.
    @Published var filterOptions: [String] = [
        "Всі", "Поповнення", "Їжа", "Проживання", "Здоровʼя та краса",
        "Інтернет послуги", "Транспорт", "Розваги та спорт",
        "Приладдя для дому", "Благо", "Електроніка","На інший рахунок", "Інше"
    ]
    
    /// Словник відповідності категорій і кольорів, який використовується для стилізації UI.
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

// MARK: - MainAppView (Головний вигляд додатку)
/// Основне представлення додатку, яке складається з бокової панелі та основного контенту.
struct MainAppView: View {
    /// Змінна для збереження обраного фільтра категорій.
    @State private var selectedCategoryFilter = "Всі"
    /// Створення спостережуваного об'єкту для моделі даних категорій.
    @StateObject private var categoryDataModel = CategoryDataModel()
    
    var body: some View {
        HStack {
            Divider()
            SidebarView(selectedCategoryFilter: $selectedCategoryFilter)
                .environmentObject(categoryDataModel)
            Divider()
            VStack {
                // TransactionInputView() можна використовувати для введення нових транзакцій.
//                TransactionInputView()
//                    .environmentObject(categoryDataModel)
                TransactionsMainView(selectedCategoryFilter: $selectedCategoryFilter)
                    .environmentObject(categoryDataModel)
            }
            Divider()
        }
    }
}

// MARK: - SidebarView (Бокова панель)
/// Представлення бокової панелі, яке містить логотип та список категорій.
struct SidebarView: View {
    @Binding var selectedCategoryFilter: String

    var body: some View {
        VStack {
            Spacer()
            // Логотип як кнопка
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

            // Заголовок для списку категорій
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

// MARK: - CategoryFiltersView (Фільтри категорій)
/// Представлення для відображення кнопок-фільтрів категорій, а також додаткових опцій для перейменування та управління категоріями.
struct CategoryFiltersView: View {
    /// Прив'язка обраного фільтра
    @Binding var selectedCategoryFilter: String
    /// Стан для відображення модального вікна перейменування категорії
    @State private var showRenameCategoryView = false
    /// Стан для відображення модального вікна управління категоріями
    @State private var showCategoryManagementView = false
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    
    /// Отримання всіх транзакцій (без сортування)
    @FetchRequest(sortDescriptors: [])
    private var transactions: FetchedResults<Transaction>
    
    /// Список категорій, відсортованих за кількістю транзакцій.
    /// Перша категорія – "Всі", потім "Поповнення", а далі інші.
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
                // Відображення кнопок для кожної категорії
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
                // Кнопка для перейменування категорії (не для "Всі" та "Поповнення")
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
                // Кнопка для управління категоріями
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

// MARK: - ScaleButtonStyle (Стиль кнопки з ефектом масштабування)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - RenameCategoryView (Перейменування категорії)
/// Представлення для перейменування вибраної категорії.
struct RenameCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    /// Прив'язка до поточної категорії, яка буде перейменована
    @Binding var currentCategory: String
    /// Нове ім'я категорії
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

/// Функція для оновлення транзакцій та списку категорій при перейменуванні.
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

// MARK: - CategoryManagementView (Управління категоріями)
/// Представлення для додавання та видалення категорій.
struct CategoryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @Environment(\.dismiss) var dismiss
    /// Ім'я нової категорії
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
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Додати") { print("Натиснуто") }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Додати") { print("Натиснуто") }
                }
                #endif
            }
        }
    }
    
    /// Додавання нової категорії
    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !categoryDataModel.filterOptions.contains(trimmed) else { return }
        
        categoryDataModel.filterOptions.append(trimmed)
        categoryDataModel.colors[trimmed] = Color.gray
        newCategoryName = ""
    }
    
    /// Видалення категорії. Транзакції переназначаються на категорію "Інше".
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
}// MARK: Кінець структур для SIDEBAR




// MARK: - TransactionsMainView (Основний контент транзакцій)
/// Представлення, яке відображає транзакції. Показує або загальний огляд витрат, або деталі конкретної категорії.
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
    
    /// Список категорій, відсортований за кількістю транзакцій
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
    
    // MARK: - Subviews
    
    private var budgetSummaryListView: some View {
        ScrollView(.vertical) {
            VStack {
                BudgetSummaryView(
                    monthlyBudget: monthlyBudget,
                    transactions: transactions,
                    color: categoryDataModel.colors["Всі"] ?? .gray
                )
                TransactionInputView()
                    .environmentObject(categoryDataModel)
            }
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
    
    // MARK: - Summary Views
    
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
    
    // MARK: - Helpers
    
    private func deleteTransaction(_ transaction: Transaction) {
        viewContext.delete(transaction)
        do {
            try viewContext.save()
        } catch {
            print("Помилка видалення: \(error.localizedDescription)")
        }
    }
}

// MARK: - CategoryExpenseSummaryView (Підсумок витрат за категорією)
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

// MARK: - SummaryView (Загальний підсумок витрат)
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

// MARK: - EditTransactionView (Редагування транзакції)
/// Представлення для редагування існуючої транзакції. Дозволяє змінювати суму, категорію та коментар.
struct EditTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    #if os(iOS)
    @Environment(\.dismiss) var dismiss
    #else
    @Environment(\.presentationMode) var presentationMode
    #endif

    @ObservedObject var transaction: Transaction

    @State private var editedAmountUAH: String
    @State private var editedAmountPLN: String
    @State private var selectedCategory: String
    @State private var editedComment: String

    /// Ініціалізатор із початковими значеннями з транзакції
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
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Скасувати") { closeView() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Зберегти") { saveChanges() }
            }
            #else
            ToolbarItem(placement: .cancellationAction) {
                Button("Скасувати") { closeView() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Зберегти") { saveChanges() }
            }
            #endif
        }
    }
    
    // MARK: - Private підсекції
    
    /// Компонент вводу з заголовком
    private func inputSection(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
    }
    
    /// Секція для вибору категорії транзакції
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Категорія:")
                .font(.headline)
            Picker("Категорія", selection: $selectedCategory) {
                ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" && $0 != "Поповнення" }, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    /// Фоновий колір картки залежно від платформи
    private var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    /// Закриття представлення
    private func closeView() {
        #if os(iOS)
        dismiss()
        #else
        presentationMode.wrappedValue.dismiss()
        #endif
    }
    
    /// Збереження змін в транзакції
    private func saveChanges() {
        guard let uah = Double(editedAmountUAH),
              let pln = Double(editedAmountPLN) else { return }
        
        transaction.amountUAH = uah
        transaction.amountPLN = pln
        transaction.category = selectedCategory
        transaction.comment = editedComment
        transaction.date = Date()
        
        do {
            try viewContext.save()
            closeView()
        } catch {
            print("Помилка збереження: \(error.localizedDescription)")
        }
    }
}

// MARK: - CategoryHeaderView (Заголовок категорії)
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

// MARK: - ReplenishmentHeaderView (Заголовок для категорії "Поповнення")
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

// MARK: - TransactionCell (Ячейка транзакції)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Сума в UAH: \(transaction.amountUAH, format: .number.precision(.fractionLength(2)))")
                        .font(.headline)
                    Text("Сума в PLN: \(transaction.amountPLN, format: .number.precision(.fractionLength(2)))")
                    Text("Курс: \(transaction.amountPLN != 0 ? transaction.amountUAH / transaction.amountPLN : 0, format: .number.precision(.fractionLength(2)))")
                    Text("Дата: \(transaction.date ?? Date(), formatter: dateFormatter)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let comment = transaction.comment, !comment.isEmpty {
                    Text("Коментар: \(comment)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 300)
                }
            }
            HStack {
                Spacer()
                Button("Редагувати", action: onEdit)
                    .foregroundColor(.blue)
                Button("Видалити", action: onDelete)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - TransactionInputView (Введення транзакцій)
/// Представлення для введення нових транзакцій.
struct TransactionInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @State private var amountUAH = ""
    @State private var amountPLN = ""
    @State private var selectedCategory = "Їжа"
    @State private var comment = ""
    @State private var isPresented = false  // Контроль відображення форми

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

// MARK: - InputField (Компонент вводу)
/// Компонент для відображення заголовку та текстового поля вводу з базовим оформленням.
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

// MARK: - Text Extension для стилізації кнопок (TransactionInputView)
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

// MARK: - BudgetSummaryView (Покращений сучасний підсумок бюджету для macOS)
struct BudgetSummaryView: View {
    let monthlyBudget: Double
    let transactions: FetchedResults<Transaction>
    let color: Color

    // Початковий баланс – може бути заданим константою або отриманим із налаштувань
    private let initialBalance: Double = 30165.86

    // Загальні витрати (без "Поповнення" та "На інший рахунок")
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
    
    // Сума поповнень (тільки категорія "Поповнення")
    private var totalReplenishmentUAH: Double {
        transactions.filter { $0.validCategory == "Поповнення" }
            .reduce(0) { $0 + $1.amountUAH }
    }
    private var totalReplenishmentPLN: Double {
        transactions.filter { $0.validCategory == "Поповнення" }
            .reduce(0) { $0 + $1.amountPLN }
    }
    
    // Розрахунок середнього курсу (за витратами)
    private var averageRate: Double {
        totalExpensesPLN != 0 ? totalExpensesUAH / totalExpensesPLN : 0.0
    }
    
    // "Залишок очікуваний" = Бюджет - витрати (без поповнень)
    private var expectedBalanceUAH: Double { monthlyBudget - totalExpensesUAH }
    private var expectedBalancePLN: Double { averageRate != 0 ? expectedBalanceUAH / averageRate : 0.0 }
    
    // "Залишок фактичний" = Початковий баланс + поповнення - витрати (без поповнень)
    private var actualBalanceUAH: Double { initialBalance + totalReplenishmentUAH - totalExpensesUAH }
    private var actualBalancePLN: Double { averageRate != 0 ? actualBalanceUAH / averageRate : 0.0 }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("\(actualBalanceUAH, specifier: "%.2f") ₴")
                Text("\(expectedBalanceUAH, specifier: "%.2f") ₴")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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


