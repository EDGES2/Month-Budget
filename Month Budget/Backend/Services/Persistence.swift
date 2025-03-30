import SwiftUI
import CoreData
import CryptoKit

// MARK: - Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        // Назва моделі Core Data має точно співпадати
        container = NSPersistentContainer(name: "Month_Budget")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Помилка завантаження Core Data: \(error), \(error.userInfo)")
            }
        }
    }
}

// MARK: - Модель даних категорій
final class CategoryDataModel: ObservableObject {
    @Published var filterOptions: [String] = [
        "Всі", "Поповнення", "API", "Їжа", "Проживання", "Здоровʼя та краса",
        "Інтернет послуги", "Транспорт", "Розваги та спорт",
        "Приладдя для дому", "Благо", "Електроніка", "На інший рахунок", "Інше"
    ]
    
    @Published var colors: [String: Color] = [
        "Всі": Color(red: 0.9, green: 0.9, blue: 0.9),
        "Поповнення": Color(red: 0.0, green: 0.7, blue: 0.2),
        "API": Color(red: 0.4, green: 0.4, blue: 0.9),
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

// MARK: - Enum для типів фільтрації
enum CategoryFilterType: String, CaseIterable {
    case count = "За кількістю транзакцій"
    case alphabetical = "За алфавітом"
    case expenses = "За витратами UAH"
}

// Допоміжна функція для іконок фільтрації
func filterIconName(for type: CategoryFilterType) -> String {
    switch type {
    case .count: return "number"
    case .alphabetical: return "textformat.abc"
    case .expenses: return "dollarsign.circle"
    }
}

// MARK: - Розширення для Transaction
extension Transaction {
    var wrappedId: UUID { id ?? UUID() }
    var validCategory: String { category ?? "Інше" }
}

// MARK: - TransactionService (бізнес-логіка)
struct TransactionService {
    static func renameCategory(oldName: String, newName: String, in context: NSManagedObjectContext, categoryDataModel: CategoryDataModel) {
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
    
    static func deleteTransaction(_ transaction: Transaction, in context: NSManagedObjectContext) {
        context.delete(transaction)
        do {
            try context.save()
        } catch {
            print("Помилка видалення: \(error.localizedDescription)")
        }
    }
    
    static func addTransaction(amountUAH: Double, amountPLN: Double, selectedCategory: String, comment: String, in context: NSManagedObjectContext) -> Bool {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.amountUAH = amountUAH
        newTransaction.amountPLN = amountPLN
        newTransaction.category = selectedCategory
        newTransaction.comment = comment
        newTransaction.date = Date()
        
        do {
            try context.save()
            print("Транзакцію додано успішно!")
            return true
        } catch {
            print("Помилка додавання транзакції: \(error.localizedDescription)")
            return false
        }
    }
    
    static func updateTransaction(_ transaction: Transaction, newAmountUAH: Double, newAmountPLN: Double, newCategory: String, newComment: String, in context: NSManagedObjectContext) -> Bool {
        // Якщо категорія змінилася, перетворити значення на додатні
        if transaction.category != newCategory {
            transaction.amountUAH = abs(newAmountUAH)
            transaction.amountPLN = abs(newAmountPLN)
        } else {
            transaction.amountUAH = newAmountUAH
            transaction.amountPLN = newAmountPLN
        }
        transaction.category = newCategory
        transaction.comment = newComment
        do {
            try context.save()
            return true
        } catch {
            print("Помилка збереження: \(error.localizedDescription)")
            return false
        }
    }


    
    static func importAPITransactions(apiTransactions: [TransactionAPI], in context: NSManagedObjectContext) {
        apiTransactions.forEach { apiTxn in
            // Генеруємо UUID з API id
            let apiUUID = UUID.uuidFromString(apiTxn.id)
            
            // Перевірка на наявність транзакції з таким id
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", apiUUID as CVarArg)
            
            if let count = try? context.count(for: fetchRequest), count > 0 {
                // Транзакція з таким id вже імпортована, переходимо до наступної
                return
            }
            
            // Створення нової транзакції
            let newTransaction = Transaction(context: context)
            newTransaction.id = apiUUID
            newTransaction.amountUAH = Double(apiTxn.amount) / 100.0
            newTransaction.amountPLN = Double(apiTxn.operationAmount) / 100.0
            newTransaction.category = "API"
            newTransaction.comment = apiTxn.description
            newTransaction.date = Date(timeIntervalSince1970: TimeInterval(apiTxn.time))
        }
        
        do {
            try context.save()
            print("API transactions imported successfully!")
        } catch {
            print("Error saving API transactions: \(error.localizedDescription)")
        }
    }
}

// MARK: - API-функції для транзакцій
extension TransactionService {
    /// Завантаження транзакцій з monobank API та їх імпорт у Core Data
    static func fetchAPITransactions(in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        // Отримуємо 1 число поточного місяця
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            print("Не вдалося визначити початок місяця")
            return
        }
        
        let monobankAPI = MonobankAPI()
        
        monobankAPI.fetchTransactions(from: startOfMonth.timeIntervalSince1970, to: now.timeIntervalSince1970) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let apiTransactions = try decoder.decode([TransactionAPI].self, from: data)
                        // Імпорт транзакцій у Core Data із встановленням категорії "API"
                        importAPITransactions(apiTransactions: apiTransactions, in: context)
                    } catch {
                        print("JSON Decode Error: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("Error fetching transactions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Видаляє всі транзакції категорії "API"
    static func deleteAllAPITransactions(in context: NSManagedObjectContext, transactions: FetchedResults<Transaction>) {
        transactions.filter { $0.validCategory == "API" }.forEach { transaction in
            context.delete(transaction)
        }
        do {
            try context.save()
        } catch {
            print("Помилка видалення всіх транзакцій: \(error.localizedDescription)")
        }
    }
}
extension UUID {
    /// Генерує UUID на основі API id (рядка) за допомогою MD5-хешування
    static func uuidFromString(_ string: String) -> UUID {
        // Обчислюємо MD5-хеш з даних рядка
        let data = Data(string.utf8)
        let hash = Insecure.MD5.hash(data: data)
        // Перетворюємо хеш у масив байтів
        var uuidBytes = Array(hash)
        
        // Налаштовуємо байти для відповідності стандарту UUID (версія 3, варіант 1)
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30 // Версія 3
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80 // Варіант
        
        // Створюємо UUID з отриманих байтів
        return uuidBytes.withUnsafeBytes { pointer in
            let bytes = pointer.bindMemory(to: uuid_t.self)
            return UUID(uuid: bytes.baseAddress!.pointee)
        }
    }
}

// MARK: - Структура для декодування транзакцій із API
struct TransactionAPI: Codable {
    let id: String
    let time: Int
    let description: String
    let amount: Int
    let operationAmount: Int
    let currencyCode: Int
    let balance: Int
    let category: Int  // Це поле міститиме значення "mcc"

    enum CodingKeys: String, CodingKey {
        case id, time, description, amount, operationAmount, currencyCode, balance
        case category = "mcc"
    }
}

// MARK: - Функція для тестування викликів API
func testMonobankAPI() {
    let api = MonobankAPI()
    api.fetchClientInfo { result in
        switch result {
        case .success(let data):
            if let json = String(data: data, encoding: .utf8) {
                print("Client Info: \(json)")
            }
        case .failure(let error):
            print("Error fetching client info: \(error.localizedDescription)")
        }
    }
}
