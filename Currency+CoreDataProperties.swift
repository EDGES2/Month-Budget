//
//  Currency+CoreDataProperties.swift
//  Month Budget
//
//  Created by Kyrylo Tokariev on 30.03.2025.
//
//

import Foundation
import CoreData


extension Currency {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Currency> {
        return NSFetchRequest<Currency>(entityName: "Currency")
    }

    @NSManaged public var code: String?
    @NSManaged public var symbol: String?
    @NSManaged public var exchangeRateToBase: Double
    @NSManaged public var relationship: Transaction?

}

extension Currency : Identifiable {

}
