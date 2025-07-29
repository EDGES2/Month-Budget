import CoreData

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
