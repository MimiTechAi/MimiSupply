//
//  PartnerEntity+CoreDataProperties.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreData

extension PartnerEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PartnerEntity> {
        return NSFetchRequest<PartnerEntity>(entityName: "PartnerEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var category: String?
    @NSManaged public var partnerData: Data?
    @NSManaged public var lastUpdated: Date?

}