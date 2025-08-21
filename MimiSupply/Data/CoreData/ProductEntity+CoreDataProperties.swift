//
//  ProductEntity+CoreDataProperties.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreData

extension ProductEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductEntity> {
        return NSFetchRequest<ProductEntity>(entityName: "ProductEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var partnerId: String?
    @NSManaged public var name: String?
    @NSManaged public var category: String?
    @NSManaged public var priceCents: Int32
    @NSManaged public var isAvailable: Bool
    @NSManaged public var productData: Data?
    @NSManaged public var lastUpdated: Date?

}