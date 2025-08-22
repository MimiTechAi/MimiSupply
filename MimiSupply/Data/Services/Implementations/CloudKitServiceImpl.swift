//
//  CloudKitServiceImpl.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 13.08.25.
//

import Foundation
import CloudKit
import MapKit
import CoreLocation

/// Implementation of CloudKitService for data synchronization
final class CloudKitServiceImpl: CloudKitService {
    
    // MARK: - Singleton
    static let shared = CloudKitServiceImpl()
    
    private let publicDatabase = CKContainer.default().publicCloudDatabase
    private let privateDatabase = CKContainer.default().privateCloudDatabase
    private let container = CKContainer.default()
    
    // MARK: - Partner Operations
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        let predicate = createLocationPredicate(for: region)
        let query = CKQuery(recordType: CloudKitSchema.Partner.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Partner.rating, ascending: false)]
        
        do {
            let (matchResults, _) = try await publicDatabase.records(matching: query)
            let partners = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToPartner(record)
                case .failure(let error):
                    print("Failed to fetch partner record: \(error)")
                    return nil
                }
            }
            return partners
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        let recordID = CKRecord.ID(recordName: id)
        
        do {
            let record = try await publicDatabase.record(for: recordID)
            return try convertRecordToPartner(record)
        } catch let ckError as CKError {
            if ckError.code == .unknownItem {
                return nil
            }
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Product Operations
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Product.partnerId, partnerId)
        let query = CKQuery(recordType: CloudKitSchema.Product.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Product.name, ascending: true)]
        
        do {
            let (matchResults, _) = try await publicDatabase.records(matching: query)
            let products = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToProduct(record)
                case .failure(let error):
                    print("Failed to fetch product record: \(error)")
                    return nil
                }
            }
            return products
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        // First get partners in the region
        let partners = try await fetchPartners(in: region)
        let partnerIds = partners.map { $0.id }
        
        guard !partnerIds.isEmpty else { return [] }
        
        // Search products by name and partner location
        let namePredicate = NSPredicate(format: "%K CONTAINS[cd] %@", CloudKitSchema.Product.name, query)
        let partnerPredicate = NSPredicate(format: "%K IN %@", CloudKitSchema.Product.partnerId, partnerIds)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, partnerPredicate])
        
        let ckQuery = CKQuery(recordType: CloudKitSchema.Product.recordType, predicate: combinedPredicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Product.name, ascending: true)]
        
        do {
            let (matchResults, _) = try await publicDatabase.records(matching: ckQuery)
            let products = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToProduct(record)
                case .failure(let error):
                    print("Failed to fetch product record: \(error)")
                    return nil
                }
            }
            return products
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Order Operations
    
    func createOrder(_ order: Order) async throws -> Order {
        let record = try convertOrderToRecord(order)
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            return try convertRecordToOrder(savedRecord)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        let recordID = CKRecord.ID(recordName: orderId)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            record[CloudKitSchema.Order.status] = status.rawValue
            record[CloudKitSchema.Order.updatedAt] = Date()
            
            _ = try await privateDatabase.save(record)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        let predicate: NSPredicate
        
        switch role {
        case .customer:
            predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.customerId, userId)
        case .driver:
            predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.driverId, userId)
        case .partner:
            predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.partnerId, userId)
        case .admin:
            predicate = NSPredicate(value: true) // Admin can see all orders
        }
        
        let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Order.createdAt, ascending: false)]
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            let orders = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToOrder(record)
                case .failure(let error):
                    print("Failed to fetch order record: \(error)")
                    return nil
                }
            }
            return orders
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func fetchOrders(for userId: String, role: UserRole, statuses: [OrderStatus]) async throws -> [Order] {
        // Base predicate by role
        let rolePredicate: NSPredicate
        switch role {
        case .customer:
            rolePredicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.customerId, userId)
        case .driver:
            rolePredicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.driverId, userId)
        case .partner:
            rolePredicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.partnerId, userId)
        case .admin:
            rolePredicate = NSPredicate(value: true)
        }

        let predicate: NSPredicate
        if statuses.isEmpty {
            predicate = rolePredicate
        } else {
            let statusValues = statuses.map { $0.rawValue }
            let statusPredicate = NSPredicate(format: "%K IN %@", CloudKitSchema.Order.status, statusValues)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [rolePredicate, statusPredicate])
        }

        let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Order.createdAt, ascending: false)]

        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            let orders = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToOrder(record)
                case .failure(let error):
                    print("Failed to fetch filtered order: \(error)")
                    return nil
                }
            }
            return orders
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func fetchRecentOrders(for userId: String, role: UserRole, limit: Int) async throws -> [Order] {
        // Base predicate by role
        let predicate: NSPredicate
        switch role {
        case .customer:
            predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.customerId, userId)
        case .driver:
            predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.driverId, userId)
        case .partner:
            predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.partnerId, userId)
        case .admin:
            predicate = NSPredicate(value: true)
        }

        let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Order.createdAt, ascending: false)]

        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            let orders = try matchResults.prefix(limit).compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToOrder(record)
                case .failure(let error):
                    print("Failed to fetch recent order for user: \(error)")
                    return nil
                }
            }
            return Array(orders)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - User Operations
    
    func saveUserProfile(_ user: UserProfile) async throws {
        let record = try convertUserProfileToRecord(user)
        
        do {
            _ = try await privateDatabase.save(record)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchUserProfile(by appleUserID: String) async throws -> UserProfile? {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.UserProfile.appleUserID, appleUserID)
        let query = CKQuery(recordType: CloudKitSchema.UserProfile.recordType, predicate: predicate)
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    return try convertRecordToUserProfile(record)
                case .failure(let error):
                    print("Failed to fetch user profile: \(error)")
                }
            }
            return nil
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func updateUserDeviceToken(_ userId: String, deviceToken: String) async throws {
        let recordID = CKRecord.ID(recordName: userId)
        do {
            let record = try await privateDatabase.record(for: recordID)
            record[CloudKitSchema.UserProfile.deviceToken] = deviceToken
            record[CloudKitSchema.UserProfile.lastActiveAt] = Date()
            _ = try await privateDatabase.save(record)
        } catch let ckError as CKError {
            if ckError.code == .unknownItem {
                throw CloudKitError.recordNotFound(CloudKitSchema.UserProfile.recordType)
            }
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Driver Operations
    
    func saveDriver(_ driver: Driver) async throws -> Driver {
        let record = try convertDriverToRecord(driver)
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            return try convertRecordToDriver(savedRecord)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchDriver(by id: String) async throws -> Driver? {
        let recordID = CKRecord.ID(recordName: id)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            return try convertRecordToDriver(record)
        } catch let ckError as CKError {
            if ckError.code == .unknownItem {
                return nil
            }
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchDriverByUserId(_ userId: String) async throws -> Driver? {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Driver.userId, userId)
        let query = CKQuery(recordType: CloudKitSchema.Driver.recordType, predicate: predicate)
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    return try convertRecordToDriver(record)
                case .failure(let error):
                    print("Failed to fetch driver by user ID: \(error)")
                }
            }
            return nil
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func saveDriverLocation(_ location: DriverLocation) async throws {
        let record = convertDriverLocationToRecord(location)
        
        do {
            _ = try await privateDatabase.save(record)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchDriverLocation(for driverId: String) async throws -> DriverLocation? {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.DriverLocation.driverId, driverId)
        let query = CKQuery(recordType: CloudKitSchema.DriverLocation.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.DriverLocation.timestamp, ascending: false)]
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    return convertRecordToDriverLocation(record)
                case .failure(let error):
                    print("Failed to fetch driver location: \(error)")
                }
            }
            return nil
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribeToOrderUpdates(for userId: String) async throws {
        // Implementation for order update subscriptions
        print("Subscribed to order updates for user: \(userId)")
    }
    
    func subscribeToGeneralNotifications() async throws {
        // Implementation for general notification subscriptions
        print("Subscribed to general notifications")
    }
    
    func subscribeToDriverLocationUpdates(for orderId: String) async throws {
        // First get the order to find the driver
        let orderRecordID = CKRecord.ID(recordName: orderId)
        
        do {
            let orderRecord = try await privateDatabase.record(for: orderRecordID)
            guard let driverId = orderRecord[CloudKitSchema.Order.driverId] as? String else {
                throw CloudKitError.recordNotFound("Driver not assigned to order")
            }
            
            let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.DriverLocation.driverId, driverId)
            let subscription = CKQuerySubscription(
                recordType: CloudKitSchema.DriverLocation.recordType,
                predicate: predicate,
                subscriptionID: "\(CloudKitSchema.Subscriptions.driverLocationUpdates)-\(orderId)",
                options: [.firesOnRecordUpdate, .firesOnRecordCreation]
            )
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            _ = try await privateDatabase.save(subscription)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Subscription Management
    
    func createSubscription(_ subscription: CKSubscription) async throws -> CKSubscription {
        do {
            return try await privateDatabase.save(subscription)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func deleteSubscription(withID subscriptionID: String) async throws {
        do {
            try await privateDatabase.deleteSubscription(withID: subscriptionID)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Additional Methods
    
    func fetchAvailableOrders() async throws -> [Order] {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.status, OrderStatus.created.rawValue)
        let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Order.createdAt, ascending: false)]
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            let orders = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToOrder(record)
                case .failure(let error):
                    print("Failed to fetch available order: \(error)")
                    return nil
                }
            }
            return orders
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func updateOrder(_ order: Order) async throws -> Order {
        let record = try convertOrderToRecord(order)
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            return try convertRecordToOrder(savedRecord)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func saveDeliveryCompletion(_ completion: DeliveryCompletionData) async throws {
        let record = convertDeliveryCompletionToRecord(completion)
        
        do {
            _ = try await privateDatabase.save(record)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchRecentOrders(limit: Int) async throws -> [Order] {
        let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Order.createdAt, ascending: false)]
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            let orders = try matchResults.prefix(limit).compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToOrder(record)
                case .failure(let error):
                    print("Failed to fetch recent order: \(error)")
                    return nil
                }
            }
            return Array(orders)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchPartnerStats(for partnerId: String) async throws -> PartnerStats {
        // Mock implementation - in production aggregate from CloudKit
        return PartnerStats(
            todayOrderCount: Int.random(in: 0...25),
            todayRevenueCents: Int.random(in: 0...150) * 100,
            averageRating: Double.random(in: 4.0...5.0),
            totalOrders: Int.random(in: 50...200),
            totalRevenueCents: Int.random(in: 1000...5000) * 100,
            activeOrders: Int.random(in: 0...10)
        )
    }
    
    func updatePartnerStatus(partnerId: String, isActive: Bool) async throws {
        let recordID = CKRecord.ID(recordName: partnerId)
        
        do {
            let record = try await publicDatabase.record(for: recordID)
            record[CloudKitSchema.Partner.isActive] = isActive
            _ = try await publicDatabase.save(record)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Generic Operations
    
    func save<T: Codable>(_ object: T) async throws -> T {
        // Convert object to CKRecord
        let record = try convertCodableToRecord(object)
        
        // Determine database based on object type
        let database: CKDatabase
        if object is Partner || object is Product {
            database = publicDatabase
        } else {
            database = privateDatabase
        }
        
        // Save record
        do {
            let savedRecord = try await database.save(record)
            return try convertRecordToCodable(savedRecord, type: T.self)
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetch<T: Codable>(_ type: T.Type, predicate: NSPredicate) async throws -> [T] {
        // Determine record type based on generic type
        let recordType: String
        let database: CKDatabase
        
        if type == Partner.self {
            recordType = CloudKitSchema.Partner.recordType
            database = publicDatabase
        } else if type == Product.self {
            recordType = CloudKitSchema.Product.recordType
            database = publicDatabase
        } else if type == Order.self {
            recordType = CloudKitSchema.Order.recordType
            database = privateDatabase
        } else if type == UserProfile.self {
            recordType = CloudKitSchema.UserProfile.recordType
            database = privateDatabase
        } else if type == Driver.self {
            recordType = CloudKitSchema.Driver.recordType
            database = privateDatabase
        } else {
            throw CloudKitError.syncFailed("Unsupported type for generic fetch")
        }
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let objects = try matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try convertRecordToCodable(record, type: type)
                case .failure(let error):
                    print("Failed to fetch record: \(error)")
                    return nil
                }
            }
            return objects
        } catch let ckError as CKError {
            throw CloudKitError.from(ckError)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Helper Methods for Generic Operations
    
    private func convertCodableToRecord<T: Codable>(_ object: T) throws -> CKRecord {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        
        let recordType = String(describing: type(of: object))
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["data"] = data
        
        return record
    }
    
    private func convertRecordToCodable<T: Codable>(_ record: CKRecord, type: T.Type) throws -> T {
        guard let data = record["data"] as? Data else {
            throw CloudKitError.syncFailed("Invalid record format for generic object")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    // MARK: - Record Conversion Methods
    
    private func createLocationPredicate(for region: MKCoordinateRegion) -> NSPredicate {
        let center = region.center
        let radius = max(region.span.latitudeDelta, region.span.longitudeDelta) * 111000 / 2 // Convert to meters
        
        return NSPredicate(format: "distanceToLocation:fromLocation:(%K,%K,%lf,%lf) < %f",
                          CloudKitSchema.Partner.latitude,
                          CloudKitSchema.Partner.longitude,
                          center.latitude,
                          center.longitude,
                          radius)
    }
    
    private func convertRecordToPartner(_ record: CKRecord) throws -> Partner {
        guard let name = record[CloudKitSchema.Partner.name] as? String,
              let categoryString = record[CloudKitSchema.Partner.category] as? String,
              let category = PartnerCategory(rawValue: categoryString),
              let description = record[CloudKitSchema.Partner.description] as? String,
              let street = record[CloudKitSchema.Partner.street] as? String,
              let city = record[CloudKitSchema.Partner.city] as? String,
              let state = record[CloudKitSchema.Partner.state] as? String,
              let postalCode = record[CloudKitSchema.Partner.postalCode] as? String,
              let country = record[CloudKitSchema.Partner.country] as? String,
              let latitude = record[CloudKitSchema.Partner.latitude] as? Double,
              let longitude = record[CloudKitSchema.Partner.longitude] as? Double,
              let phoneNumber = record[CloudKitSchema.Partner.phoneNumber] as? String,
              let email = record[CloudKitSchema.Partner.email] as? String,
              let createdAt = record[CloudKitSchema.Partner.createdAt] as? Date else {
            throw CloudKitError.syncFailed("Invalid partner record format")
        }
        
        let address = Address(street: street, city: city, state: state, postalCode: postalCode, country: country)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Parse opening hours JSON if available
        var openingHours: [WeekDay: OpeningHours] = [:]
        if let openingHoursData = record[CloudKitSchema.Partner.openingHours] as? Data {
            openingHours = (try? JSONDecoder().decode([WeekDay: OpeningHours].self, from: openingHoursData)) ?? [:]
        }
        
        return Partner(
            id: record.recordID.recordName,
            name: name,
            category: category,
            description: description,
            address: address,
            location: location,
            phoneNumber: phoneNumber,
            email: email,
            heroImageURL: (record[CloudKitSchema.Partner.heroImage] as? CKAsset)?.fileURL,
            logoURL: (record[CloudKitSchema.Partner.logo] as? CKAsset)?.fileURL,
            isVerified: record[CloudKitSchema.Partner.isVerified] as? Bool ?? false,
            isActive: record[CloudKitSchema.Partner.isActive] as? Bool ?? true,
            rating: record[CloudKitSchema.Partner.rating] as? Double ?? 0.0,
            reviewCount: record[CloudKitSchema.Partner.reviewCount] as? Int ?? 0,
            openingHours: openingHours,
            deliveryRadius: record[CloudKitSchema.Partner.deliveryRadius] as? Double ?? 5.0,
            minimumOrderAmount: record[CloudKitSchema.Partner.minimumOrderAmount] as? Int ?? 0,
            estimatedDeliveryTime: record[CloudKitSchema.Partner.estimatedDeliveryTime] as? Int ?? 30,
            createdAt: createdAt
        )
    }
    
    private func convertRecordToProduct(_ record: CKRecord) throws -> Product {
        guard let partnerId = record[CloudKitSchema.Product.partnerId] as? String,
              let name = record[CloudKitSchema.Product.name] as? String,
              let description = record[CloudKitSchema.Product.description] as? String,
              let priceCents = record[CloudKitSchema.Product.priceCents] as? Int,
              let categoryString = record[CloudKitSchema.Product.category] as? String,
              let category = ProductCategory(rawValue: categoryString),
              let createdAt = record[CloudKitSchema.Product.createdAt] as? Date,
              let updatedAt = record[CloudKitSchema.Product.updatedAt] as? Date else {
            throw CloudKitError.syncFailed("Invalid product record format")
        }
        
        // Convert image assets to URLs
        var imageURLs: [URL] = []
        if let imageAssets = record[CloudKitSchema.Product.images] as? [CKAsset] {
            imageURLs = imageAssets.compactMap { $0.fileURL }
        }
        
        // Parse nutrition info if available
        var nutritionInfo: NutritionInfo?
        if let nutritionData = record[CloudKitSchema.Product.nutritionInfo] as? Data {
            nutritionInfo = try? JSONDecoder().decode(NutritionInfo.self, from: nutritionData)
        }
        
        // Parse allergens
        var allergens: [Allergen] = []
        if let allergenStrings = record[CloudKitSchema.Product.allergens] as? [String] {
            allergens = allergenStrings.compactMap { Allergen(rawValue: $0) }
        }
        
        return Product(
            id: record.recordID.recordName,
            partnerId: partnerId,
            name: name,
            description: description,
            priceCents: priceCents,
            originalPriceCents: record[CloudKitSchema.Product.originalPriceCents] as? Int,
            category: category,
            imageURLs: imageURLs,
            isAvailable: record[CloudKitSchema.Product.isAvailable] as? Bool ?? true,
            stockQuantity: record[CloudKitSchema.Product.stockQuantity] as? Int,
            nutritionInfo: nutritionInfo,
            allergens: allergens,
            tags: record[CloudKitSchema.Product.tags] as? [String] ?? [],
            weight: nil, // TODO: Implement weight parsing
            dimensions: nil, // TODO: Implement dimensions parsing
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }    

    private func convertOrderToRecord(_ order: Order) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitSchema.Order.recordType, recordID: CKRecord.ID(recordName: order.id))
        
        record[CloudKitSchema.Order.customerId] = order.customerId
        record[CloudKitSchema.Order.partnerId] = order.partnerId
        record[CloudKitSchema.Order.driverId] = order.driverId
        record[CloudKitSchema.Order.status] = order.status.rawValue
        record[CloudKitSchema.Order.subtotalCents] = order.subtotalCents
        record[CloudKitSchema.Order.deliveryFeeCents] = order.deliveryFeeCents
        record[CloudKitSchema.Order.platformFeeCents] = order.platformFeeCents
        record[CloudKitSchema.Order.taxCents] = order.taxCents
        record[CloudKitSchema.Order.tipCents] = order.tipCents
        record[CloudKitSchema.Order.totalCents] = order.totalCents
        record[CloudKitSchema.Order.deliveryInstructions] = order.deliveryInstructions
        record[CloudKitSchema.Order.estimatedDeliveryTime] = order.estimatedDeliveryTime
        record[CloudKitSchema.Order.actualDeliveryTime] = order.actualDeliveryTime
        record[CloudKitSchema.Order.paymentMethod] = order.paymentMethod.rawValue
        record[CloudKitSchema.Order.paymentStatus] = order.paymentStatus.rawValue
        record[CloudKitSchema.Order.createdAt] = order.createdAt
        record[CloudKitSchema.Order.updatedAt] = order.updatedAt
        
        // Encode complex objects as JSON
        let encoder = JSONEncoder()
        record[CloudKitSchema.Order.items] = try encoder.encode(order.items)
        record[CloudKitSchema.Order.deliveryAddress] = try encoder.encode(order.deliveryAddress)
        
        return record
    }
    
    private func convertRecordToOrder(_ record: CKRecord) throws -> Order {
        guard let customerId = record[CloudKitSchema.Order.customerId] as? String,
              let partnerId = record[CloudKitSchema.Order.partnerId] as? String,
              let statusString = record[CloudKitSchema.Order.status] as? String,
              let status = OrderStatus(rawValue: statusString),
              let subtotalCents = record[CloudKitSchema.Order.subtotalCents] as? Int,
              let deliveryFeeCents = record[CloudKitSchema.Order.deliveryFeeCents] as? Int,
              let platformFeeCents = record[CloudKitSchema.Order.platformFeeCents] as? Int,
              let taxCents = record[CloudKitSchema.Order.taxCents] as? Int,
              let tipCents = record[CloudKitSchema.Order.tipCents] as? Int,
              let _ = record[CloudKitSchema.Order.totalCents] as? Int,
              let paymentMethodString = record[CloudKitSchema.Order.paymentMethod] as? String,
              let paymentMethod = PaymentMethod(rawValue: paymentMethodString),
              let paymentStatusString = record[CloudKitSchema.Order.paymentStatus] as? String,
              let paymentStatus = PaymentStatus(rawValue: paymentStatusString),
              let createdAt = record[CloudKitSchema.Order.createdAt] as? Date,
              let updatedAt = record[CloudKitSchema.Order.updatedAt] as? Date,
              let itemsData = record[CloudKitSchema.Order.items] as? Data,
              let addressData = record[CloudKitSchema.Order.deliveryAddress] as? Data else {
            throw CloudKitError.syncFailed("Invalid order record format")
        }
        
        let decoder = JSONDecoder()
        let items = try decoder.decode([OrderItem].self, from: itemsData)
        let deliveryAddress = try decoder.decode(Address.self, from: addressData)
        
        return Order(
            id: record.recordID.recordName,
            customerId: customerId,
            partnerId: partnerId,
            driverId: record[CloudKitSchema.Order.driverId] as? String,
            items: items,
            status: status,
            subtotalCents: subtotalCents,
            deliveryFeeCents: deliveryFeeCents,
            platformFeeCents: platformFeeCents,
            taxCents: taxCents,
            tipCents: tipCents,
            deliveryAddress: deliveryAddress,
            deliveryInstructions: record[CloudKitSchema.Order.deliveryInstructions] as? String,
            estimatedDeliveryTime: (record[CloudKitSchema.Order.estimatedDeliveryTime] as? Date) ?? createdAt,
            actualDeliveryTime: record[CloudKitSchema.Order.actualDeliveryTime] as? Date,
            paymentMethod: paymentMethod,
            paymentStatus: paymentStatus,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }    

    private func convertUserProfileToRecord(_ user: UserProfile) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitSchema.UserProfile.recordType, recordID: CKRecord.ID(recordName: user.id))
        
        record[CloudKitSchema.UserProfile.appleUserID] = user.appleUserID
        record[CloudKitSchema.UserProfile.email] = user.email
        record[CloudKitSchema.UserProfile.role] = user.role.rawValue
        record[CloudKitSchema.UserProfile.phoneNumber] = user.phoneNumber
        record[CloudKitSchema.UserProfile.isVerified] = user.isVerified
        record[CloudKitSchema.UserProfile.createdAt] = user.createdAt
        record[CloudKitSchema.UserProfile.lastActiveAt] = user.lastActiveAt
        
        // Encode PersonNameComponents as JSON
        if let fullName = user.fullName {
            let encoder = JSONEncoder()
            record[CloudKitSchema.UserProfile.fullName] = try encoder.encode(fullName)
        }
        
        return record
    }
    
    private func convertRecordToUserProfile(_ record: CKRecord) throws -> UserProfile {
        guard let appleUserID = record[CloudKitSchema.UserProfile.appleUserID] as? String,
              let roleString = record[CloudKitSchema.UserProfile.role] as? String,
              let role = UserRole(rawValue: roleString),
              let createdAt = record[CloudKitSchema.UserProfile.createdAt] as? Date,
              let lastActiveAt = record[CloudKitSchema.UserProfile.lastActiveAt] as? Date else {
            throw CloudKitError.syncFailed("Invalid user profile record format")
        }
        
        var fullNameComponents: PersonNameComponents?
        if let fullNameData = record[CloudKitSchema.UserProfile.fullName] as? Data {
            fullNameComponents = try? JSONDecoder().decode(PersonNameComponents.self, from: fullNameData)
        }
        
        return UserProfile(
            id: record.recordID.recordName,
            appleUserID: appleUserID,
            email: record[CloudKitSchema.UserProfile.email] as? String,
            fullName: fullNameComponents,
            role: role,
            phoneNumber: record[CloudKitSchema.UserProfile.phoneNumber] as? String,
            profileImageURL: (record[CloudKitSchema.UserProfile.profileImage] as? CKAsset)?.fileURL,
            isVerified: record[CloudKitSchema.UserProfile.isVerified] as? Bool ?? false,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt,
            driverProfile: nil,
            partnerProfile: nil
        )
    }
    
    private func convertDriverLocationToRecord(_ location: DriverLocation) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "\(location.driverId)-\(Int(location.timestamp.timeIntervalSince1970))")
        let record = CKRecord(recordType: CloudKitSchema.DriverLocation.recordType, recordID: recordID)
        
        record[CloudKitSchema.DriverLocation.driverId] = location.driverId
        record[CloudKitSchema.DriverLocation.latitude] = location.location.latitude
        record[CloudKitSchema.DriverLocation.longitude] = location.location.longitude
        record[CloudKitSchema.DriverLocation.heading] = location.heading
        record[CloudKitSchema.DriverLocation.speed] = location.speed
        record[CloudKitSchema.DriverLocation.accuracy] = location.accuracy
        record[CloudKitSchema.DriverLocation.timestamp] = location.timestamp
        
        return record
    }
    
    private func convertRecordToDriverLocation(_ record: CKRecord) -> DriverLocation? {
        guard let driverId = record[CloudKitSchema.DriverLocation.driverId] as? String,
              let latitude = record[CloudKitSchema.DriverLocation.latitude] as? Double,
              let longitude = record[CloudKitSchema.DriverLocation.longitude] as? Double,
              let accuracy = record[CloudKitSchema.DriverLocation.accuracy] as? Double,
              let timestamp = record[CloudKitSchema.DriverLocation.timestamp] as? Date else {
            return nil
        }
        
        let location = Coordinate(latitude: latitude, longitude: longitude)
        
        return DriverLocation(
            driverId: driverId,
            location: location,
            heading: record[CloudKitSchema.DriverLocation.heading] as? Double,
            speed: record[CloudKitSchema.DriverLocation.speed] as? Double,
            accuracy: accuracy,
            timestamp: timestamp
        )
    }

    
    
    // MARK: - Helper Methods for Driver
    
    private func convertDriverToRecord(_ driver: Driver) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitSchema.Driver.recordType, recordID: CKRecord.ID(recordName: driver.id))
        
        record[CloudKitSchema.Driver.userId] = driver.userId
        record[CloudKitSchema.Driver.name] = driver.name
        record[CloudKitSchema.Driver.phoneNumber] = driver.phoneNumber
        record[CloudKitSchema.Driver.vehicleType] = driver.vehicleType.rawValue
        record[CloudKitSchema.Driver.licensePlate] = driver.licensePlate
        record[CloudKitSchema.Driver.isOnline] = driver.isOnline
        record[CloudKitSchema.Driver.isAvailable] = driver.isAvailable
        record[CloudKitSchema.Driver.rating] = driver.rating
        record[CloudKitSchema.Driver.completedDeliveries] = driver.completedDeliveries
        record[CloudKitSchema.Driver.verificationStatus] = driver.verificationStatus.rawValue
        record[CloudKitSchema.Driver.createdAt] = driver.createdAt
        
        if let location = driver.currentLocation {
            record[CloudKitSchema.Driver.currentLatitude] = location.latitude
            record[CloudKitSchema.Driver.currentLongitude] = location.longitude
        }
        
        return record
    }
    
    private func convertRecordToDriver(_ record: CKRecord) throws -> Driver {
        guard let userId = record[CloudKitSchema.Driver.userId] as? String,
              let name = record[CloudKitSchema.Driver.name] as? String,
              let phoneNumber = record[CloudKitSchema.Driver.phoneNumber] as? String,
              let vehicleTypeString = record[CloudKitSchema.Driver.vehicleType] as? String,
              let vehicleType = VehicleType(rawValue: vehicleTypeString),
              let licensePlate = record[CloudKitSchema.Driver.licensePlate] as? String,
              let isOnline = record[CloudKitSchema.Driver.isOnline] as? Bool,
              let isAvailable = record[CloudKitSchema.Driver.isAvailable] as? Bool,
              let rating = record[CloudKitSchema.Driver.rating] as? Double,
              let completedDeliveries = record[CloudKitSchema.Driver.completedDeliveries] as? Int,
              let verificationStatusString = record[CloudKitSchema.Driver.verificationStatus] as? String,
              let verificationStatus = VerificationStatus(rawValue: verificationStatusString),
              let createdAt = record[CloudKitSchema.Driver.createdAt] as? Date else {
            throw CloudKitError.syncFailed("Invalid driver record format")
        }
        
        var currentLocation: Coordinate?
        if let latitude = record[CloudKitSchema.Driver.currentLatitude] as? Double,
           let longitude = record[CloudKitSchema.Driver.currentLongitude] as? Double {
            currentLocation = Coordinate(latitude: latitude, longitude: longitude)
        }
        
        return Driver(
            id: record.recordID.recordName,
            userId: userId,
            name: name,
            phoneNumber: phoneNumber,
            profileImageURL: (record[CloudKitSchema.Driver.profileImage] as? CKAsset)?.fileURL,
            vehicleType: vehicleType,
            licensePlate: licensePlate,
            isOnline: isOnline,
            isAvailable: isAvailable,
            currentLocation: currentLocation,
            rating: rating,
            completedDeliveries: completedDeliveries,
            verificationStatus: verificationStatus,
            createdAt: createdAt
        )
    }
    
    private func convertDeliveryCompletionToRecord(_ completion: DeliveryCompletionData) -> CKRecord {
        let record = CKRecord(recordType: CloudKitSchema.DeliveryCompletion.recordType, recordID: CKRecord.ID(recordName: completion.id))
        
        record[CloudKitSchema.DeliveryCompletion.orderId] = completion.orderId
        record[CloudKitSchema.DeliveryCompletion.driverId] = completion.driverId
        record[CloudKitSchema.DeliveryCompletion.completedAt] = completion.completedAt
        record[CloudKitSchema.DeliveryCompletion.notes] = completion.notes
        record[CloudKitSchema.DeliveryCompletion.customerRating] = completion.customerRating
        record[CloudKitSchema.DeliveryCompletion.customerFeedback] = completion.customerFeedback
        
        if let photoData = completion.photoData {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(completion.id)-photo.jpg")
            try? photoData.write(to: tempURL)
            record[CloudKitSchema.DeliveryCompletion.photoAsset] = CKAsset(fileURL: tempURL)
        }
        return record
    }
}

// MARK: - CloudKit Schema Extension

// DeliveryCompletion schema is now defined in CloudKitSchema.swift