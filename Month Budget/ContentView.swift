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
        "Приладдя для дому", "Благо", "Електроніка", "Інше"
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
        "Інше": Color(red: 0.29, green: 0.0, blue: 0.51)
    ]
}

// MARK: - ContentView (Головний вигляд додатку)
/// Основне представлення додатку, яке складається з бокової панелі та основного контенту.
struct ContentView: View {
    // Змінна для збереження обраного фільтра категорій.
    @State private var selectedFilter = "Всі"
    // Створення спостережуваного об'єкту для моделі даних категорій.
    @StateObject private var categoryDataModel = CategoryDataModel()
    
    var body: some View {
        HStack {
            Divider() // Вертикальний роздільник
            // Бокова панель з категоріями
            SidebarView(selectedFilter: $selectedFilter)
                .environmentObject(categoryDataModel)
            Divider()
            VStack {
                // Форма введення нових транзакцій
//                InputListView()
//                    .environmentObject(categoryDataModel)
                // Основний контент, що відображає транзакції відповідно до обраного фільтра
                MainContentView(selectedFilter: $selectedFilter)
                    .environmentObject(categoryDataModel)
            }
            Divider()
        }
    }
}

// MARK: - SidebarView (Бокова панель)
/// Представлення бокової панелі, яке містить логотип та список категорій.
struct SidebarView: View {
    @Binding var selectedFilter: String

    var body: some View {
        VStack {
            Spacer()
            // Логотип як кнопка
            Button(action: {
                withAnimation {
                    selectedFilter = "Логотип" // спеціальне значення для логотипу
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
            .buttonStyle(PlainButtonStyle()) // Видаляємо стандартний фон кнопки

            // Заголовок для списку категорій
            HStack {
                Text("Категорії:")
                    .font(.headline)
                Spacer()
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            Divider()
            CategoryFiltersView(selectedFilter: $selectedFilter)
        }
        .frame(width: 180)
    }
}


// MARK: - CategoryFiltersView (Фільтри категорій)
/// Представлення для відображення кнопок-фільтрів категорій, а також додаткових опцій для перейменування та управління категоріями.
struct CategoryFiltersView: View {
    // Прив'язка обраного фільтра
    @Binding var selectedFilter: String
    // Стан для відображення модального вікна перейменування категорії
    @State private var showRenameCategoryView = false
    // Стан для відображення модального вікна управління категоріями
    @State private var showCategoryManagementView = false
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    
    // Отримання всіх транзакцій (не сортуються)
    @FetchRequest(sortDescriptors: [])
    private var transactions: FetchedResults<Transaction>
    
    /// Список категорій, відсортованих за кількістю транзакцій. Перша категорія – "Всі".
    private var sortedCategories: [String] {
        let others = categoryDataModel.filterOptions.dropFirst().sorted { lhs, rhs in
            let lhsCount = transactions.filter { $0.validCategory == lhs }.count
            let rhsCount = transactions.filter { $0.validCategory == rhs }.count
            return lhsCount > rhsCount
        }
        return [categoryDataModel.filterOptions.first ?? "Всі", "Поповнення"] + others
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                // Відображення кнопок для кожної категорії
                ForEach(sortedCategories, id: \.self) { option in
                    Button(action: { withAnimation { selectedFilter = option } }) {
                        Text(option)
                            .categoryButtonStyle(
                                isSelected: selectedFilter == option,
                                color: categoryDataModel.colors[option] ?? .gray
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                // Кнопка для перейменування категорії, яка відображається лише коли вибрана конкретна категорія (не "Всі")
                if selectedFilter != "Всі" && selectedFilter != "Поповнення" {
                    Button("Перейменувати категорію") {
                        showRenameCategoryView = true
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top)
                    .sheet(isPresented: $showRenameCategoryView) {
                        RenameCategoryView(currentCategory: $selectedFilter)
                            .environmentObject(categoryDataModel)
                    }
                }
                // Кнопка для управління категоріями (додавання, видалення)
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

// MARK: - RenameCategoryView (Перейменування)
/// Представлення для перейменування вибраної категорії. Дозволяє змінити назву категорії та оновити пов'язані транзакції.
struct RenameCategoryView: View {
    // Доступ до контексту CoreData
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    // Прив'язка до поточної категорії, яка буде перейменована
    @Binding var currentCategory: String
    // Змінна для збереження нового імені
    @State private var newName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Перейменування категорії")) {
                    // Відображення поточної категорії
                    Text("Поточна категорія: \(currentCategory)")
                    // Поле для введення нового імені
                    TextField("Нове ім'я", text: $newName)
                }
                // Кнопка збереження змін
                Button("Зберегти") {
                    guard !newName.isEmpty else { return }
                    // Виклик функції для перейменування категорії
                    renameCategory(oldName: currentCategory, newName: newName, in: viewContext, categoryDataModel: categoryDataModel)
                    currentCategory = newName
                    dismiss()
                }
            }
            .navigationTitle("Перейменувати")
        }
    }
}

/// Функція для оновлення транзакцій і списку категорій при перейменуванні.
/// - Parameters:
///   - oldName: Стара назва категорії.
///   - newName: Нова назва категорії.
///   - context: Контекст CoreData.
///   - categoryDataModel: Модель даних категорій.
func renameCategory(oldName: String, newName: String, in context: NSManagedObjectContext, categoryDataModel: CategoryDataModel) {
    let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "category == %@", oldName)
    
    do {
        let transactionsToUpdate = try context.fetch(fetchRequest)
        // Оновлення категорії для кожної транзакції, що відповідає старій назві
        transactionsToUpdate.forEach { $0.category = newName }
        try context.save()
        print("Оновлено \(transactionsToUpdate.count) транзакцій з категорії \(oldName) на \(newName)")
        
        // Оновлення даних у моделі категорій
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
/// Представлення для додавання та видалення категорій. Дає можливість користувачу керувати списком категорій.
struct CategoryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @Environment(\.dismiss) var dismiss
    // Змінна для збереження імені нової категорії
    @State private var newCategoryName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Секція для додавання нової категорії
                Section(header: Text("Додати категорію")) {
                    HStack {
                        TextField("Нова категорія", text: $newCategoryName)
                        Button("Додати", action: addCategory)
                    }
                }
                
                // Секція для відображення існуючих категорій із можливістю видалення
                Section(header: Text("Існуючі категорії")) {
                    ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" && $0 != "Поповнення"}, id: \.self) { category in
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
    
    // MARK: - Private методи для управління категоріями
    
    /// Функція для додавання нової категорії до моделі даних
    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Перевірка, що ім'я не пусте і такої категорії ще немає
        guard !trimmed.isEmpty, !categoryDataModel.filterOptions.contains(trimmed) else { return }
        
        categoryDataModel.filterOptions.append(trimmed)
        categoryDataModel.colors[trimmed] = Color.gray
        newCategoryName = ""
    }
    
    /// Функція для видалення категорії. При видаленні транзакції переназначаються на категорію "Інше".
    private func deleteCategory(_ category: String) {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let transactionsToUpdate = try viewContext.fetch(fetchRequest)
            // Заміна видаляємої категорії на "Інше" для всіх транзакцій
            transactionsToUpdate.forEach { $0.category = "Інше" }
            try viewContext.save()
        } catch {
            print("Помилка переназначення транзакцій: \(error.localizedDescription)")
        }
        
        // Видалення категорії з моделі даних
        if let index = categoryDataModel.filterOptions.firstIndex(of: category) {
            categoryDataModel.filterOptions.remove(at: index)
        }
        categoryDataModel.colors.removeValue(forKey: category)
    }
}

// MARK: - InputListView (Компонент для введення транзакцій)
/// Представлення для введення нових транзакцій. Містить поля для введення сум, вибору категорії та коментаря.
struct InputListView: View {
    // Доступ до контексту CoreData
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    // Змінні для збереження введених даних
    @State private var amountUAH = ""
    @State private var amountPLN = ""
    @State private var selectedCategory = "Їжа"
    @State private var comment = ""
    
    // Фонова темна заливка для форми введення
    private let darkBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(spacing: 16) {
            // Секція форми для введення даних
            inputFormSection
            // Секція з кнопкою для додавання транзакції
            addButtonSection
        }
        .padding(12)
        .background(darkBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
    
    /// Секція з полями вводу та вибором категорії
    private var inputFormSection: some View {
        VStack(spacing: 12) {
            currencyInputFields
            categoryPickerSection
            commentField
        }
        .padding(.horizontal, 8)
    }
    
    /// Поля для введення сум в UAH та PLN
    private var currencyInputFields: some View {
        HStack(spacing: 12) {
            InputField(title: "UAH", text: $amountUAH)
            Divider()
                .frame(height: 40)
                .background(Color.gray)
            InputField(title: "PLN", text: $amountPLN)
        }
    }
    
    /// Секція з вибором категорії транзакції через Picker
    private var categoryPickerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "tag.fill")
                .foregroundColor(.gray)
            Picker("Категорія", selection: $selectedCategory) {
                // Пропускаємо перший елемент "Всі", бо він не призначений для нових транзакцій
                ForEach(categoryDataModel.filterOptions.dropFirst(), id: \.self) { category in
                    Text(category)
                        .tag(category)
                        .foregroundColor(.white)
                }
            }
            .pickerStyle(.menu)
            .padding(8)
            .background(
                // Фон вибірника з напівпрозорим кольором категорії "Всі"
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryDataModel.colors["Всі"]?.opacity(0.2) ?? Color.gray.opacity(0.2))
            )
            .overlay(
                // Обводка для вибірника
                RoundedRectangle(cornerRadius: 10)
                    .stroke(categoryDataModel.colors["Всі"]?.opacity(0.8) ?? Color.gray.opacity(0.8), lineWidth: 1)
            )
        }
    }
    
    /// Поле для введення коментаря до транзакції
    private var commentField: some View {
        TextField("Коментар", text: $comment)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
    
    /// Кнопка для додавання транзакції
    private var addButtonSection: some View {
        Button("Додати витрати", action: addTransaction)
    }
    
    /// Функція для створення та збереження нової транзакції в CoreData
    private func addTransaction() {
        // Перевірка правильності введених числових значень
        guard let uah = Double(amountUAH),
              let pln = Double(amountPLN) else {
            print("Невірний формат суми")
            return
        }
        
        // Створення нового об'єкту Transaction
        let newTransaction = Transaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.amountUAH = uah
        newTransaction.amountPLN = pln
        newTransaction.category = selectedCategory
        newTransaction.comment = comment
        newTransaction.date = Date()
        
        do {
            // Збереження транзакції в контексті CoreData
            try viewContext.save()
            // Очищення полів після успішного додавання
            amountUAH = ""
            amountPLN = ""
            comment = ""
            print("Транзакцію додано успішно!")
        } catch {
            print("Помилка додавання транзакції: \(error.localizedDescription)")
        }
    }
}


// MARK: - InputField (Компонент вводу)
/// Компонент для відображення заголовку і текстового поля вводу з базовим оформленням.
struct InputField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Заголовок поля вводу
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            // Текстове поле з округленою рамкою
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


// MARK: - ScaleButtonStyle (Стиль кнопки з ефектом масштабування)
/// Користувацький стиль кнопки, який забезпечує ефект масштабування при натисканні.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: Кінець структур для SIDEBAR




// MARK: - MainContentView (Основний контент транзакцій)
/// Представлення, яке відображає транзакції. Показує або загальний огляд витрат, або деталі конкретної категорії.
struct MainContentView: View {
    // Прив'язка для вибору фільтра категорії
    @Binding var selectedFilter: String
    // Змінна для збереження транзакції, яку потрібно редагувати
    @State private var selectedTransaction: Transaction?
    // Доступ до контексту CoreData
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    
    // Отримання даних транзакцій із CoreData, відсортованих за датою
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<Transaction>
    
    // Фіксований місячний бюджет (може бути використаний для порівняння з витратами)
    private let monthlyBudget: Double = 20000.0
    
    /// Обчислювана властивість, що повертає категорії, відсортовані за кількістю транзакцій (за спаданням)
    private var sortedCategories: [String] {
        categoryDataModel.filterOptions.dropFirst().sorted { lhs, rhs in
            let lhsCount = transactions.filter { $0.validCategory == lhs }.count
            let rhsCount = transactions.filter { $0.validCategory == rhs }.count
            return lhsCount > rhsCount
        }
    }
    
    /// Огляд сумарних витрат для всіх транзакцій
    private var totalSummary: some View {
        let totalUAH = transactions.reduce(0) { $0 + $1.amountUAH }
        let totalPLN = transactions.reduce(0) { $0 + $1.amountPLN }
        let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0
        
        return SummaryView(
            title: "Усі витрати",
            amountUAH: totalUAH,
            amountPLN: totalPLN,
            rate: rate,
            color: categoryDataModel.colors["Всі"] ?? .gray
        )
    }
    
    var body: some View {
            content
                .sheet(item: $selectedTransaction) { transaction in
                    EditTransactionView(transaction: transaction)
                        .environment(\.managedObjectContext, viewContext)
                }
        }
    
    /// Вибір між переглядом всіх категорій та деталями конкретної категорії
    @ViewBuilder
        private var content: some View {
            if selectedFilter == "Логотип" {
                budgetView
            } else if selectedFilter == "Всі" {
                allCategoriesView
            } else {
                categoryDetailView
            }
        }
    
    /// Представлення, що показує загальний огляд транзакцій за всіма категоріями
    private var allCategoriesView: some View {
        List {

            totalSummary
            // Відображення підсумку для кожної категорії
            ForEach(sortedCategories, id: \.self) { category in
                CategorySummaryView(
                    category: category,
                    transactions: transactions,
                    color: categoryDataModel.colors[category] ?? .gray
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    /// Представлення, що показує деталі транзакцій для вибраної категорії
    private var categoryDetailView: some View {
        // Фільтрація транзакцій за вибраною категорією
        let filteredTransactions = transactions.filter { $0.validCategory == selectedFilter }
        return VStack {
            // Заголовок категорії з інформацією про транзакції
            CategoryHeaderView(
                transactions: filteredTransactions,
                color: categoryDataModel.colors[selectedFilter] ?? .gray
            )
            List {
                // Відображення кожної транзакції у вигляді клітинки з можливістю редагування або видалення
                ForEach(filteredTransactions, id: \.wrappedId) { transaction in
                    TransactionCell(
                        transaction: transaction,
                        color: categoryDataModel.colors[transaction.validCategory] ?? .gray,
                        onEdit: { selectedTransaction = transaction },
                        onDelete: { deleteTransaction(transaction) }
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var budgetView: some View {
        List{
            BudgetSummaryView(
                monthlyBudget: monthlyBudget,
                transactions: transactions,
                color: categoryDataModel.colors["Всі"] ?? .gray
            )
        }
    }
    
    /// Функція для видалення транзакції з контексту CoreData
    private func deleteTransaction(_ transaction: Transaction) {
        viewContext.delete(transaction)
        do {
            try viewContext.save()
        } catch {
            print("Помилка видалення: \(error.localizedDescription)")
        }
    }
}

// MARK: - BudgetSummaryView (Підсумок бюджету)
struct BudgetSummaryView: View {
    let monthlyBudget: Double
    let transactions: FetchedResults<Transaction>
    let color: Color

    private var totalExpensesUAH: Double { transactions.reduce(0) { $0 + $1.amountUAH } }
    private var totalExpensesPLN: Double { transactions.reduce(0) { $0 + $1.amountPLN } }
    private var averageRate: Double { totalExpensesPLN != 0 ? totalExpensesUAH / totalExpensesPLN : 0.0 }
    private var finalBalanceUAH: Double { monthlyBudget - totalExpensesUAH }
    private var finalBalancePLN: Double { averageRate != 0 ? finalBalanceUAH / averageRate : 0.0 }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("Категорія")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("UAH")
                    .bold()
                    .frame(maxWidth: 100, alignment: .trailing)
                Text("PLN")
                    .bold()
                    .frame(maxWidth: 100, alignment: .trailing)
                Text("Курс")
                    .bold()
                    .frame(maxWidth: 80, alignment: .trailing)
                Spacer()
            }
            .font(.system(size: 16, design: .monospaced))
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.2))
            Divider()
            rowView(label: "Бюджет:", amountUAH: monthlyBudget, amountPLN: nil, rate: nil)
            rowView(label: "Баланс:", amountUAH: finalBalanceUAH, amountPLN: finalBalancePLN, rate: averageRate)
        }
        .padding(.vertical)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func rowView(label: String, amountUAH: Double?, amountPLN: Double?, rate: Double?) -> some View {
        HStack {
            Spacer()
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(amountUAH != nil ? "\(amountUAH!, format: .number.precision(.fractionLength(2)))" : "-")
                .frame(maxWidth: 100, alignment: .trailing)
            Text(amountPLN != nil ? "\(amountPLN!, format: .number.precision(.fractionLength(2)))" : "-")
                .frame(maxWidth: 100, alignment: .trailing)
            Text(rate != nil ? "\(rate!, format: .number.precision(.fractionLength(2)))" : "-")
                .frame(maxWidth: 80, alignment: .trailing)
            Spacer()
        }
        .font(.system(size: 14, design: .monospaced))
    }
}

    

// MARK: - Text Extension для стилізації кнопок категорій
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
            .shadow(color: color.opacity(isSelected ? 0.3 : 0.2), radius: isSelected ? 4 : 2, x: 0, y: isSelected ? 2 : 1)
            .contentShape(Rectangle())
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
    // Доступ до контексту CoreData
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    #if os(iOS)
    @Environment(\.dismiss) var dismiss
    #else
    @Environment(\.presentationMode) var presentationMode
    #endif

    // Спостереження за об'єктом транзакції для автоматичного оновлення
    @ObservedObject var transaction: Transaction

    // Локальні стани для редагування значень транзакції
    @State private var editedAmountUAH: String
    @State private var editedAmountPLN: String
    @State private var selectedCategory: String
    @State private var editedComment: String

    /// Ініціалізатор, що задає початкові значення для полів редагування з даних транзакції.
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
                // Секції для редагування полів транзакції
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
            ToolbarItem(placement: .navigationBarLeading) { Button("Скасувати") { closeView() } }
            ToolbarItem(placement: .navigationBarTrailing) { Button("Зберегти") { saveChanges() } }
            #else
            ToolbarItem(placement: .cancellationAction) { Button("Скасувати") { closeView() } }
            ToolbarItem(placement: .confirmationAction) { Button("Зберегти") { saveChanges() } }
            #endif
        }
    }
    
    // MARK: - Private підсекції
    
    /// Компонент для відображення заголовку та текстового поля вводу в секції редагування
    private func inputSection(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
    }
    
    /// Секція для вибору категорії редагованої транзакції
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Категорія:")
                .font(.headline)
            Picker("Категорія", selection: $selectedCategory) {
                // Використання динамічного списку категорій (крім "Всі")
                ForEach(categoryDataModel.filterOptions.filter { $0 != "Всі" }, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    /// Фоновий колір картки в залежності від платформи
    private var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    /// Функція для закриття модального вікна редагування
    private func closeView() {
        #if os(iOS)
        dismiss()
        #else
        presentationMode.wrappedValue.dismiss()
        #endif
    }
    
    /// Функція для збереження змін в транзакції та оновлення даних в CoreData
    private func saveChanges() {
        // Перевірка коректності числових значень
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

// MARK: - CategorySummaryView (Підсумок витрат за категорією)
struct CategorySummaryView: View {
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

// MARK: - Допоміжні компоненти та розширення

extension Transaction {
    var wrappedId: UUID { id ?? UUID() }
    var validCategory: String { category ?? "Інше" }
}
