//
//  CartItemEntity+CoreDataProperties.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreData

extension CartItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CartItemEntity> {
        return NSFetchRequest<CartItemEntity>(entityName: "CartItemEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var productData: Data?
    @NSManaged public var quantity: Int32
    @NSManaged public var specialInstructions: String?
    @NSManaged public var addedAt: Date?

}