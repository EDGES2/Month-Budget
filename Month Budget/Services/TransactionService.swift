// Month Budget/Services/TransactionService.swift
import Foundation
import CoreData

struct TransactionService {

    // MARK: - CRUD Operations

    /**
     Додає нову транзакцію до Core Data.
     */
    static func addTransaction(
        firstAmount: Double,
        firstCurrencyCode: String,
        secondAmount: Double,
        secondCurrencyCode: String,
        selectedCategory: String,
        comment: String,
        currencyManager: CurrencyManager,
        in context: NSManagedObjectContext
    ) -> Bool {
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

    /**
     Оновлює існуючу транзакцію.
     */
    static func updateTransaction(
        _ transaction: Transaction,
        newFirstAmount: Double,
        newFirstCurrencyCode: String,
        newSecondAmount: Double,
        newSecondCurrencyCode: String,
        newCategory: String,
        newComment: String,
        transactions: [Transaction],
        currencyManager: CurrencyManager,
        in context: NSManagedObjectContext
    ) -> Bool {
        transaction.firstAmount = newFirstAmount
        
        if newSecondCurrencyCode != currencyManager.baseCurrency2 {
            if let nearestTxn = currencyManager.nearestTransaction(
                from: newFirstCurrencyCode,
                to: currencyManager.baseCurrency2,
                forDate: transaction.date ?? Date(),
                transactions: transactions
            ),
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

    /**
     Видаляє транзакцію.
     */
    static func deleteTransaction(_ transaction: Transaction, in context: NSManagedObjectContext) {
        context.delete(transaction)
        do {
            try context.save()
        } catch {
            print("Помилка видалення: \(error.localizedDescription)")
        }
    }

    // MARK: - Calculation Logic

    /**
     Підраховує загальну суму витрат (без категорій "Поповнення", "На інший рахунок" та "API").
     */
    static func totalExpenses(
        for transactions: [Transaction],
        targetCurrency: String,
        currencyManager: CurrencyManager
    ) -> Double {
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

    /**
     Підраховує загальну суму поповнень.
     */
    static func totalReplenishment(
        for transactions: [Transaction],
        targetCurrency: String,
        currencyManager: CurrencyManager
    ) -> Double {
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

    /**
     Підраховує загальну суму переказів на інший рахунок.
     */
    static func totalToOtherAccount(
        for transactions: [Transaction],
        targetCurrency: String,
        currencyManager: CurrencyManager
    ) -> Double {
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

    /**
     Обчислює очікуваний баланс на основі бюджету та витрат.
     */
    static func expectedBalance(
        budget: Double,
        for transactions: [Transaction],
        targetCurrency: String,
        currencyManager: CurrencyManager
    ) -> Double {
        let expenses = totalExpenses(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        return budget - expenses
    }

    /**
     Обчислює фактичний баланс на основі початкового балансу, поповнень та витрат.
     */
    static func actualBalance(
        initialBalance: Double,
        for transactions: [Transaction],
        targetCurrency: String,
        currencyManager: CurrencyManager
    ) -> Double {
        let expenses = totalExpenses(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        let replenishments = totalReplenishment(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        let transfers = totalToOtherAccount(for: transactions, targetCurrency: targetCurrency, currencyManager: currencyManager)
        return initialBalance + replenishments - expenses - transfers
    }
    
    // MARK: - Exchange Rate Calculations
    
    /**
     Обчислює курс обміну для однієї транзакції.
     */
    static func exchangeRate(for transaction: Transaction) -> Double {
        guard transaction.secondAmount != 0 else { return 0 }
        return transaction.firstAmount / transaction.secondAmount
    }
    
    /**
     Обчислює середній курс обміну для масиву транзакцій.
     */
    static func averageExchangeRateForCategory(transactions: [Transaction]) -> Double {
        let rates = transactions.compactMap { txn -> Double? in
            let rate = exchangeRate(for: txn)
            return rate != 0 ? rate : nil
        }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    /**
     Обчислює загальний середній курс обміну по всіх категоріях.
     */
    static func overallAverageExchangeRate(for transactions: [Transaction]) -> Double {
        let grouped = Dictionary(grouping: transactions, by: { $0.validCategory })
        let categoryAverages = grouped.compactMap { (_, txns) -> Double? in
            let avg = averageExchangeRateForCategory(transactions: txns)
            return avg != 0 ? avg : nil
        }
        guard !categoryAverages.isEmpty else { return 0 }
        return categoryAverages.reduce(0, +) / Double(categoryAverages.count)
    }
}
