import SwiftUI
import CoreData

// MARK: - Sidebar та супутні компоненти
struct SidebarView: View {
    @Binding var selectedCategoryFilter: String
    @Binding var categoryFilterType: CategoryFilterType
    
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
                    .padding(.leading, 8)
                Spacer()
                Button(action: {
                    withAnimation {
                        switch categoryFilterType {
                        case .count: categoryFilterType = .alphabetical
                        case .alphabetical: categoryFilterType = .expenses
                        case .expenses: categoryFilterType = .count
                        }
                    }
                }) {
                    Image(systemName: filterIconName(for: categoryFilterType))
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            Divider()
            Categories(selectedCategoryFilter: $selectedCategoryFilter,
                       categoryFilterType: $categoryFilterType)
        }
        .frame(width: 180)
    }
}

struct Categories: View {
    @Binding var selectedCategoryFilter: String
    @Binding var categoryFilterType: CategoryFilterType
    @State private var showRenameCategory = false
    @State private var showCategoryMaker = false
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    
    @FetchRequest(sortDescriptors: [])
    private var transactions: FetchedResults<Transaction>
    
    private var sortedCategories: [String] {
        let baseCategories = categoryDataModel.filterOptions.filter { $0 != "Логотип" }
        let first = categoryDataModel.filterOptions.first ?? "Всі"
        let replenishment = "Поповнення"
        let api = "API"
        let others = baseCategories.filter { $0 != first && $0 != replenishment && $0 != api }
        
        switch categoryFilterType {
        case .count:
            let sortedOthers = others.sorted { lhs, rhs in
                let lhsCount = transactions.filter { $0.validCategory == lhs }.count
                let rhsCount = transactions.filter { $0.validCategory == rhs }.count
                return lhsCount > rhsCount
            }
            return [first, replenishment, api] + sortedOthers
        case .alphabetical:
            let sortedOthers = others.sorted()
            return [first, replenishment, api] + sortedOthers
        case .expenses:
            // У Sidebar всі транзакції мають валюту UAH – тому просто сумуємо firstAmount
            let sortedOthers = others.sorted { lhs, rhs in
                let lhsExpenses = transactions.filter { $0.validCategory == lhs }
                    .reduce(0) { total, txn in
                        total + txn.firstAmount
                    }
                let rhsExpenses = transactions.filter { $0.validCategory == rhs }
                    .reduce(0) { total, txn in
                        total + txn.firstAmount
                    }
                return lhsExpenses > rhsExpenses
            }
            return [first, replenishment, api] + sortedOthers
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(sortedCategories, id: \.self) { option in
                    Button(action: {
                        withAnimation { selectedCategoryFilter = option }
                    }) {
                        Text(option)
                            .categoryButtonStyle(
                                isSelected: selectedCategoryFilter == option,
                                color: categoryDataModel.colors[option] ?? .gray
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if selectedCategoryFilter != "Всі" && selectedCategoryFilter != "Поповнення" && selectedCategoryFilter != "API" {
                    Button("Перейменувати категорію") {
                        showRenameCategory = true
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top)
                    .sheet(isPresented: $showRenameCategory) {
                        RenameCategory(currentCategory: $selectedCategoryFilter)
                            .environmentObject(categoryDataModel)
                    }
                }
                Button("Управління категоріями") {
                    showCategoryMaker = true
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top)
                .sheet(isPresented: $showCategoryMaker) {
                    CategoryMaker()
                        .environmentObject(categoryDataModel)
                }
                Spacer()
            }
            .padding(.vertical)
            .frame(width: 180)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RenameCategory: View {
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

struct CategoryMaker: View {
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
