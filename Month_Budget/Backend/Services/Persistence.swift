import SwiftUI
import CoreData
import CryptoKit

// MARK: - Currency Model

struct CurrencyInfo {
    let code: String       // Наприклад, "UAH", "PLN"
    let symbol: String     // Наприклад, "₴", "zł"
}

/// Модель даних валют – універсальний модуль з варіантами
final class CurrencyDataModel: ObservableObject {
    // Словник доступних валют
    @Published var availableCurrencies: [String: CurrencyInfo] = [
        "UAH": CurrencyInfo(code: "UAH", symbol: "₴"),
        "PLN": CurrencyInfo(code: "PLN", symbol: "zł"),
        "USD": CurrencyInfo(code: "USD", symbol: "$"),
        "EUR": CurrencyInfo(code: "EUR", symbol: "€")
    ]
    
    // Базові валюти (перший – для операцій, другий – для конвертації)
    @Published var baseCurrency1: String = "UAH"
    @Published var baseCurrency2: String = "PLN"
    
    // Допоміжна функція для отримання символу валюти
    func symbol(for currency: String) -> String {
        return availableCurrencies[currency]?.symbol ?? ""
    }
}

/// Менеджер валют, що використовує дані з CurrencyDataModel
class CurrencyManager: ObservableObject {
    @Published var currencies: [String: CurrencyInfo] = [:]
    
    var baseCurrency1: String
    var baseCurrency2: String
    
    init(currencyDataModel: CurrencyDataModel) {
        self.baseCurrency1 = currencyDataModel.baseCurrency1
        self.baseCurrency2 = currencyDataModel.baseCurrency2
        
        // Ініціалізуємо словник валют з даних CurrencyDataModel
        self.currencies = currencyDataModel.availableCurrencies
    }
    
    /// Знаходить курс конвертації з валюти from у валюту to за даними транзакцій.
    func conversionRate(from: String, to: String, transactions: [Transaction]) -> Double? {
        let filtered = transactions.filter { txn in
            txn.firstCurrencyCode == from && txn.secondCurrencyCode == to && txn.secondAmount != 0
        }
        
        let sorted = filtered.sorted {
            ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast)
        }
        
        if let txn = sorted.first {
            return txn.firstAmount / txn.secondAmount
        }
        return nil
    }
    
    /// Конвертує транзакцію до цільової валюти
    func convert(transaction: Transaction, to targetCurrency: String, using transactions: [Transaction]) -> Double {
        if transaction.secondCurrencyCode == targetCurrency {
            return transaction.secondAmount
        } else {
            if let rate = conversionRate(from: baseCurrency1, to: targetCurrency, transactions: transactions), rate != 0 {
                return transaction.firstAmount / rate
            }
        }
        return 0
    }
    
    /// Повертає транзакцію з заданими валютами, дата якої найбільше наближена до заданої дати.
    func nearestTransaction(from: String, to: String, forDate date: Date, transactions: [Transaction]) -> Transaction? {
        let filtered = transactions.filter { txn in
            txn.firstCurrencyCode == from && txn.secondCurrencyCode == to && txn.secondAmount != 0
        }
        return filtered.min(by: {
            let diff1 = abs(($0.date ?? Date.distantPast).timeIntervalSince(date))
            let diff2 = abs(($1.date ?? Date.distantPast).timeIntervalSince(date))
            return diff1 < diff2
        })
    }
}

// MARK: - Persistence Controller

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Month_Budget")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Помилка завантаження Core Data: \(error), \(error.userInfo)")
            }
        }
    }
}

// MARK: - Обчислення для транзакцій

extension PersistenceController {
    
    // Підрахунок витрат (без категорій "Поповнення", "На інший рахунок" та "API")
    func totalExpenses(for transactions: [Transaction],
                       targetCurrency: String,
                       currencyManager: CurrencyManager) -> Double {
        let expenseTransactions = transactions.filter { txn in
            let cat = txn.validCategory
            return cat != "Поповнення" && cat != "На інший рахунок" && cat != "API"
        }
        
        if targetCurrency == currencyManager.baseCurrency1 {
            return expenseTransactions.reduce(0) { total, txn in
                total + txn.firstAmount
            }
        } else {
            return expenseTransactions.reduce(0) { total, txn in
                total + currencyManager.convert(transaction: txn, to: targetCurrency, using: expenseTransactions)
            }
        }
    }
    
    // Підрахунок поповнень
    func totalReplenishment(for transactions: [Transaction],
                            targetCurrency: String,
                            currencyManager: CurrencyManager) -> Double {
        let replenishmentTransactions = transactions.filter { $0.validCategory == "Поповнення" }
        
        if targetCurrency == currencyManager.baseCurrency1 {
            return replenishmentTransactions.reduce(0) { total, txn in
                total + txn.firstAmount
            }
        } else {
            return replenishmentTransactions.reduce(0) { total, txn in
                total + currencyManager.convert(transaction: txn, to: targetCurrency, using: replenishmentTransactions)
            }
        }
    }
    
    // Підрахунок транзакцій "На інший рахунок"
    func totalToOtherAccount(for transactions: [Transaction],
                             targetCurrency: String,
                             currencyManager: CurrencyManager) -> Double {
        let transferTransactions = transactions.filter { $0.validCategory == "На інший рахунок" }
        
        if targetCurrency == currencyManager.baseCurrency1 {
            return transferTransactions.reduce(0) { total, txn in
                total + txn.firstAmount
            }
        } else {
            return transferTransactions.reduce(0) { total, txn in
                total + currencyManager.convert(transaction: txn, to: targetCurrency, using: transferTransactions)
            }
        }
    }
    
    // Обчислення очікуваного балансу у вказаній валюті
    func expectedBalance(budget: Double,
                         for transactions: [Transaction],
                         targetCurrency: String,
                         currencyManager: CurrencyManager) -> Double {
        let expenses = totalExpenses(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        return budget - expenses
    }
    
    // Обчислення фактичного балансу у вказаній валюті
    func actualBalance(initialBalance: Double,
                       for transactions: [Transaction],
                       targetCurrency: String,
                       currencyManager: CurrencyManager) -> Double {
        let expenses = totalExpenses(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        let replenishments = totalReplenishment(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        let transfers = totalToOtherAccount(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        return initialBalance + replenishments - expenses - transfers
    }
    
    // Обчислення курсу обміну для окремої транзакції
    func exchangeRate(for transaction: Transaction) -> Double {
        guard transaction.secondAmount != 0 else { return 0 }
        return transaction.firstAmount / transaction.secondAmount
    }
    
    // Середній курс обміну для транзакцій певної категорії
    func averageExchangeRateForCategory(transactions: [Transaction]) -> Double {
        let rates = transactions.compactMap { txn -> Double? in
            let rate = exchangeRate(for: txn)
            return rate != 0 ? rate : nil
        }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
    
    // Загальний середній курс обміну по всіх категоріях
    func overallAverageExchangeRate(for transactions: [Transaction]) -> Double {
        let grouped = Dictionary(grouping: transactions, by: { $0.validCategory })
        let categoryAverages = grouped.compactMap { (_, txns) -> Double? in
            let avg = averageExchangeRateForCategory(transactions: txns)
            return avg != 0 ? avg : nil
        }
        guard !categoryAverages.isEmpty else { return 0 }
        return categoryAverages.reduce(0, +) / Double(categoryAverages.count)
    }
}

// MARK: - Модель даних категорій (залишається без змін)

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
    
    // Приклад: функція додавання транзакції, яка тепер використовує універсальні валютні налаштування.
    static func addTransaction(firstAmount: Double,
                               firstCurrencyCode: String,
                               secondAmount: Double,
                               secondCurrencyCode: String,
                               selectedCategory: String,
                               comment: String,
                               currencyManager: CurrencyManager,
                               in context: NSManagedObjectContext) -> Bool {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        
        // Використовуємо базову валюту для першої суми
        newTransaction.firstCurrencyCode = currencyManager.baseCurrency1
        newTransaction.firstAmount = firstAmount
        newTransaction.category = selectedCategory
        newTransaction.comment = comment
        
        let currentDate = Date()
        newTransaction.date = currentDate
        
        // Якщо код другої валюти відрізняється від базової валюти для конвертації,
        // виконуємо конвертацію, інакше – просто присвоюємо значення.
        if secondCurrencyCode != currencyManager.baseCurrency2 {
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "secondCurrencyCode == %@ AND date < %@", currencyManager.baseCurrency2, currentDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = 3
            
            do {
                let results = try context.fetch(request)
                if let prevTransaction = results.first, prevTransaction.secondAmount != 0 {
                    let rate = prevTransaction.firstAmount / prevTransaction.secondAmount
                    newTransaction.secondAmount = firstAmount / rate
                } else {
                    newTransaction.secondAmount = secondAmount
                }
            } catch {
                print("Помилка отримання попередньої транзакції: \(error)")
                newTransaction.secondAmount = secondAmount
            }
            newTransaction.secondCurrencyCode = currencyManager.baseCurrency2
        } else {
            newTransaction.secondAmount = secondAmount
            newTransaction.secondCurrencyCode = currencyManager.baseCurrency2
        }
        
        do {
            try context.save()
            print("Транзакцію додано успішно!")
            return true
        } catch {
            print("Помилка додавання транзакції: \(error.localizedDescription)")
            return false
        }
    }
    
    // Функція оновлення транзакції
    static func updateTransaction(_ transaction: Transaction,
                                  newFirstAmount: Double,
                                  newFirstCurrencyCode: String,
                                  newSecondAmount: Double,
                                  newSecondCurrencyCode: String,
                                  newCategory: String,
                                  newComment: String,
                                  transactions: [Transaction],
                                  currencyManager: CurrencyManager,
                                  in context: NSManagedObjectContext) -> Bool {
        transaction.firstAmount = newFirstAmount
        
        if newSecondCurrencyCode != currencyManager.baseCurrency2 {
            if let nearestTxn = currencyManager.nearestTransaction(from: newFirstCurrencyCode,
                                                                   to: currencyManager.baseCurrency2,
                                                                   forDate: transaction.date ?? Date(),
                                                                   transactions: transactions),
               nearestTxn.secondAmount != 0 {
                let rate = nearestTxn.firstAmount / nearestTxn.secondAmount
                transaction.secondAmount = newFirstAmount / rate
            } else {
                transaction.secondAmount = newSecondAmount
            }
            transaction.secondCurrencyCode = currencyManager.baseCurrency2
        } else {
            transaction.secondAmount = newSecondAmount
            transaction.secondCurrencyCode = newSecondCurrencyCode
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
    
    static func deleteTransaction(_ transaction: Transaction, in context: NSManagedObjectContext) {
        context.delete(transaction)
        do {
            try context.save()
        } catch {
            print("Помилка видалення: \(error.localizedDescription)")
        }
    }
    
    private static func mapMonobankCurrencyCode(_ code: Int) -> String {
        // Мапінг кодів валют Monobank до універсальних валют
        switch code {
        case 980:
            return "UAH"
        case 985:
            return "PLN"
        case 840:
            return "USD"
        case 978:
            return "EUR"
        default:
            return "UAH"
        }
    }
    
    // Функція імпорту API транзакцій з використанням універсальних валютних налаштувань
    static func importAPITransactions(apiTransactions: [TransactionAPI],
                                      in context: NSManagedObjectContext,
                                      currencyManager: CurrencyManager) {
        var allTransactions: [Transaction] = []
        do {
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            allTransactions = try context.fetch(request)
        } catch {
            print("Помилка отримання транзакцій: \(error.localizedDescription)")
        }
        
        apiTransactions.forEach { apiTxn in
            let apiUUID = UUID.uuidFromString(apiTxn.id)
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", apiUUID as CVarArg)
            
            if let count = try? context.count(for: fetchRequest), count > 0 {
                return
            }
            
            let newTransaction = Transaction(context: context)
            newTransaction.id = apiUUID
            
            // Першу валюту задаємо згідно з налаштуванням (наприклад, UAH)
            newTransaction.firstCurrencyCode = currencyManager.baseCurrency1
            
            let amount = Double(apiTxn.amount) / 100.0
            let opAmount = Double(apiTxn.operationAmount) / 100.0
            
            newTransaction.date = Date(timeIntervalSince1970: TimeInterval(apiTxn.time))
            
            var convertedSecondAmount: Double = 0
            var targetCurrencyCode = ""
            // Якщо базова валюта для конвертації відрізняється від основної,
            // пробуємо конвертувати з baseCurrency1 у baseCurrency2
            if currencyManager.baseCurrency2 != currencyManager.baseCurrency1 {
                if let nearestTxn = currencyManager.nearestTransaction(from: currencyManager.baseCurrency1,
                                                                       to: currencyManager.baseCurrency2,
                                                                       forDate: newTransaction.date ?? Date(),
                                                                       transactions: allTransactions),
                   nearestTxn.secondAmount != 0 {
                    let rate = nearestTxn.firstAmount / nearestTxn.secondAmount
                    convertedSecondAmount = amount / rate
                } else {
                    convertedSecondAmount = opAmount
                }
                targetCurrencyCode = currencyManager.baseCurrency2
            } else {
                convertedSecondAmount = opAmount
                targetCurrencyCode = currencyManager.baseCurrency2
            }
            
            if amount > 0 {
                newTransaction.firstAmount = amount
                newTransaction.secondAmount = convertedSecondAmount
                newTransaction.category = "Поповнення"
            } else {
                newTransaction.firstAmount = abs(amount)
                newTransaction.secondAmount = abs(convertedSecondAmount)
                newTransaction.category = "API"
            }
            
            newTransaction.secondCurrencyCode = targetCurrencyCode
            newTransaction.comment = apiTxn.description
        }
        
        do {
            try context.save()
            print("API transactions imported successfully!")
        } catch {
            print("Error saving API transactions: \(error.localizedDescription)")
        }
    }
    
    static func fetchAPITransactions(in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            print("Не вдалося визначити початок місяця")
            return
        }
        
        let monobankAPI = MonobankAPI()
        
        monobankAPI.fetchTransactions(from: startOfMonth.timeIntervalSince1970,
                                      to: now.timeIntervalSince1970) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let apiTransactions = try decoder.decode([TransactionAPI].self, from: data)
                        // Створюємо CurrencyManager на основі CurrencyDataModel
                        let currencyDataModel = CurrencyDataModel()
                        let currencyManager = CurrencyManager(currencyDataModel: currencyDataModel)
                        importAPITransactions(apiTransactions: apiTransactions, in: context, currencyManager: currencyManager)
                    } catch {
                        print("JSON Decode Error: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("Error fetching transactions: \(error.localizedDescription)")
                }
            }
        }
    }
    
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

// MARK: - Допоміжні розширення та моделі

extension UUID {
    static func uuidFromString(_ string: String) -> UUID {
        let data = Data(string.utf8)
        let hash = Insecure.MD5.hash(data: data)
        var uuidBytes = Array(hash)
        
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        
        return uuidBytes.withUnsafeBytes { pointer in
            let bytes = pointer.bindMemory(to: uuid_t.self)
            return UUID(uuid: bytes.baseAddress!.pointee)
        }
    }
}

struct TransactionAPI: Codable {
    let id: String
    let time: Int
    let description: String
    let amount: Int
    let operationAmount: Int
    let currencyCode: Int
    let balance: Int
    let category: Int

    enum CodingKeys: String, CodingKey {
        case id, time, description, amount, operationAmount, currencyCode, balance
        case category = "mcc"
    }
}

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
