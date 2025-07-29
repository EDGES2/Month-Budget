// Month Budget/Services/CurrencyManager.swift
import SwiftUI
import CoreData

class CurrencyManager: ObservableObject {
    @Published var currencies: [String: CurrencyInfo] = [:]
    
    var baseCurrency1: String
    var baseCurrency2: String
    
    init(currencyDataModel: CurrencyDataModel) {
        self.baseCurrency1 = currencyDataModel.baseCurrency1
        self.baseCurrency2 = currencyDataModel.baseCurrency2
        self.currencies = currencyDataModel.availableCurrencies
    }
    
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
