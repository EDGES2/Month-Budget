//
//  Transaction+CoreDataProperties.swift
//  Month Budget
//
//  Created by Kyrylo Tokariev on 11.03.2025.
//
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var amountUAH: Double
    @NSManaged public var amountPLN: Double
    @NSManaged public var date: Date?

}

extension Transaction : Identifiable {

}
