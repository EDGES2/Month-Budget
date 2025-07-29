// Month Budget/Services/TransactionService.swift
import Foundation
import CoreData

struct TransactionService {

    // MARK: - CRUD Operations

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
        newTransaction.date = Date()
        newTransaction.category = selectedCategory
        newTransaction.comment = comment
        newTransaction.firstAmount = firstAmount
        newTransaction.firstCurrencyCode = firstCurrencyCode

        // --- ОСНОВНА ЛОГІКА ОБРОБКИ ДРУГОЇ ВАЛЮТИ ---
        if secondAmount == 0 {
            // Випадок 1: Одно-валютна транзакція (наприклад, тільки в UAH).
            // Розраховуємо другу суму на основі останнього курсу.
            newTransaction.secondCurrencyCode = currencyManager.baseCurrency2 // Встановлюємо PLN
            
            let allTransactions = (try? context.fetch(Transaction.fetchRequest())) ?? []
            if let nearestTxn = currencyManager.nearestTransaction(
                from: currencyManager.baseCurrency1,
                to: currencyManager.baseCurrency2,
                forDate: newTransaction.date ?? Date(),
                transactions: allTransactions
            ), nearestTxn.secondAmount != 0 {
                let rate = nearestTxn.firstAmount / nearestTxn.secondAmount
                newTransaction.secondAmount = firstAmount / rate
            } else {
                newTransaction.secondAmount = 0 // Якщо курс не знайдено
            }
        } else {
            // Випадок 2: Дво-валютна транзакція.
            // Просто зберігаємо те, що ввів користувач.
            newTransaction.secondAmount = secondAmount
            newTransaction.secondCurrencyCode = secondCurrencyCode
        }
        
        do {
            try context.save()
            return true
        } catch {
            print("Помилка додавання транзакції: \(error.localizedDescription)")
            return false
        }
    }

    static func updateTransaction(
        _ transaction: Transaction,
        newFirstAmount: Double,
        newFirstCurrencyCode: String,
        newSecondAmount: Double,
        newSecondCurrencyCode: String,
        newCategory: String,
        newComment: String,
        currencyManager: CurrencyManager,
        in context: NSManagedObjectContext
    ) -> Bool {
        transaction.firstAmount = newFirstAmount
        transaction.firstCurrencyCode = newFirstCurrencyCode
        transaction.category = newCategory
        transaction.comment = newComment

        if newSecondAmount == 0 {
            let allTransactions = (try? context.fetch(Transaction.fetchRequest())) ?? []
            if let nearestTxn = currencyManager.nearestTransaction(
                from: newFirstCurrencyCode,
                to: currencyManager.baseCurrency2,
                forDate: transaction.date ?? Date(),
                transactions: allTransactions
            ), nearestTxn.secondAmount != 0 {
                let rate = nearestTxn.firstAmount / nearestTxn.secondAmount
                transaction.secondAmount = newFirstAmount / rate
            } else {
                transaction.secondAmount = 0
            }
            transaction.secondCurrencyCode = currencyManager.baseCurrency2
        } else {
            transaction.secondAmount = newSecondAmount
            transaction.secondCurrencyCode = newSecondCurrencyCode
        }
        
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

    // MARK: - Calculation Logic
    
    static func totalExpenses(for transactions: [Transaction], targetCurrency: String, currencyManager: CurrencyManager) -> Double {
        let expenseTransactions = transactions.filter { txn in
            let cat = txn.validCategory
            return cat != "Поповнення" && cat != "На інший рахунок" && cat != "API"
        }
        
        if targetCurrency == currencyManager.baseCurrency1 {
            return expenseTransactions.reduce(0) { $0 + $1.firstAmount }
        } else {
            return expenseTransactions.reduce(0) { $0 + currencyManager.convert(transaction: $1, to: targetCurrency, using: expenseTransactions) }
        }
    }

    static func totalReplenishment(for transactions: [Transaction], targetCurrency: String, currencyManager: CurrencyManager) -> Double {
        let replenishmentTransactions = transactions.filter { $0.validCategory == "Поповнення" }
        
        if targetCurrency == currencyManager.baseCurrency1 {
            return replenishmentTransactions.reduce(0) { $0 + $1.firstAmount }
        } else {
            return replenishmentTransactions.reduce(0) { $0 + currencyManager.convert(transaction: $1, to: targetCurrency, using: replenishmentTransactions) }
        }
    }

    static func totalToOtherAccount(for transactions: [Transaction], targetCurrency: String, currencyManager: CurrencyManager) -> Double {
        let transferTransactions = transactions.filter { $0.validCategory == "На інший рахунок" }
        
        if targetCurrency == currencyManager.baseCurrency1 {
            return transferTransactions.reduce(0) { $0 + $1.firstAmount }
        } else {
            return transferTransactions.reduce(0) { $0 + currencyManager.convert(transaction: $1, to: targetCurrency, using: transferTransactions) }
        }
    }
    
    static func exchangeRate(for transaction: Transaction) -> Double {
        guard transaction.secondAmount != 0 else { return 0 }
        return transaction.firstAmount / transaction.secondAmount
    }
}
