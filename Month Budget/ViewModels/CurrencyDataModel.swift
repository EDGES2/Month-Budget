// Month Budget/ViewModels/CurrencyDataModel.swift
import SwiftUI

final class CurrencyDataModel: ObservableObject {
    @Published var availableCurrencies: [String: CurrencyInfo] = [
        "UAH": CurrencyInfo(code: "UAH", symbol: "₴"),
        "PLN": CurrencyInfo(code: "PLN", symbol: "zł"),
        "USD": CurrencyInfo(code: "USD", symbol: "$"),
        "EUR": CurrencyInfo(code: "EUR", symbol: "€")
    ]
    
    @Published var baseCurrency1: String = "UAH"
    @Published var baseCurrency2: String = "PLN"
    
    func symbol(for currency: String) -> String {
        return availableCurrencies[currency]?.symbol ?? ""
    }
}
