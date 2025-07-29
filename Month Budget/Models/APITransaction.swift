// Month Budget/Models/APITransaction.swift
import Foundation

struct APITransaction: Codable {
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
