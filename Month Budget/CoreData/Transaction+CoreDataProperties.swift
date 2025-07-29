//
//  Transaction+CoreDataProperties.swift
//  Month Budget
//
//  Created by Kyrylo Tokariev on 30.03.2025.
//
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var category: String?
    @NSManaged public var comment: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var firstAmount: Double
    @NSManaged public var secondAmount: Double
    @NSManaged public var firstCurrencyCode: String?
    @NSManaged public var secondCurrencyCode: String?
    @NSManaged public var relationship: Currency?

}

extension Transaction : Identifiable {

}
