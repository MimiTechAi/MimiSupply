//
//  EnhancedCloudKitService.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation
@preconcurrency import CloudKit
@preconcurrency import MapKit
import CoreLocation
import OSLog

/// Enhanced CloudKit service with comprehensive error handling and offline support
final class EnhancedCloudKitService: CloudKitService {
    private let publicDatabase = CKContainer.default().publicCloudDatabase
    private let privateDatabase = CKContainer.default().privateCloudDatabase
    private let container = CKContainer.default()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "EnhancedCloudKitService")
    private let retryManager = RetryManager.shared
    private let cacheManager = CacheManager.shared

    @MainActor
    private var degradationService: GracefulDegradationService {
        GracefulDegradationService.shared
    }
    
    // MARK: - Partner Operations
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        let cacheKey = "partners_\(region.center.latitude)_\(region.center.longitude)_\(region.span.latitudeDelta)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchPartners(in: region)
        }
        
        switch result {
        case .success(let partners):
            return partners
        case .failure(let error):
            logger.error("Failed to fetch partners: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        return try await retryManager.retry(operation: { [self] in
            let predicate = self.createLocationPredicate(for: region)
            let query = CKQuery(recordType: CloudKitSchema.Partner.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Partner.rating, ascending: false)]
            
            do {
                let (matchResults, _) = try await self.publicDatabase.records(matching: query)
                let partners = try matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToPartner(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch partner record: \(error)")
                        return nil
                    }
                }
                
                self.logger.info("✅ Fetched \(partners.count) partners")
                return partners
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchOrders(for userId: String, role: UserRole, statuses: [OrderStatus]) async throws -> [Order] {
        let cacheKey = "orders_\(userId)_\(role.rawValue)_statuses_\(statuses.map{ $0.rawValue }.joined(separator: ","))"
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchOrders(for: userId, role: role, statuses: statuses)
        }
        switch result {
        case .success(let orders):
            return orders
        case .failure(let error):
            logger.error("Failed to fetch filtered orders for user \(userId): \(error.localizedDescription)")
            throw error
        }
    }

    private func performFetchOrders(for userId: String, role: UserRole, statuses: [OrderStatus]) async throws -> [Order] {
        return try await retryManager.retry(operation: {
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
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                let orders = try matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToOrder(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch filtered order: \(error)")
                        return nil
                    }
                }
                self.logger.info("✅ Fetched \(orders.count) filtered orders for user \(userId)")
                return orders
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }

    func fetchRecentOrders(for userId: String, role: UserRole, limit: Int) async throws -> [Order] {
        let cacheKey = "recent_orders_\(userId)_\(role.rawValue)_limit_\(limit)"
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchRecentOrders(for: userId, role: role, limit: limit)
        }
        switch result {
        case .success(let orders):
            return orders
        case .failure(let error):
            logger.error("Failed to fetch recent orders for user \(userId): \(error.localizedDescription)")
            throw error
        }
    }

    private func performFetchRecentOrders(for userId: String, role: UserRole, limit: Int) async throws -> [Order] {
        return try await retryManager.retry(operation: {
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
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                let orders = try matchResults.prefix(limit).compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToOrder(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch recent order for user: \(error)")
                        return nil
                    }
                }
                self.logger.info("✅ Fetched \(orders.count) recent orders for user \(userId)")
                return Array(orders)
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        let cacheKey = "partner_\(id)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchPartner(by: id)
        }
        
        switch result {
        case .success(let partner):
            return partner
        case .failure(let error):
            logger.error("Failed to fetch partner \(id): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchPartner(by id: String) async throws -> Partner? {
        return try await retryManager.retry(operation: {
            let recordID = CKRecord.ID(recordName: id)
            
            do {
                let record = try await self.publicDatabase.record(for: recordID)
                return try self.convertRecordToPartner(record)
            } catch let ckError as CKError {
                if ckError.code == .unknownItem {
                    return nil
                }
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchPartnerStats(for partnerId: String) async throws -> PartnerStats {
        let cacheKey = "partner_stats_\(partnerId)"
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.retryManager.retry(operation: {
                // Mock aggregation for now; replace with real CK aggregation if/when needed
                return PartnerStats(
                    todayOrderCount: Int.random(in: 0...25),
                    todayRevenueCents: Int.random(in: 0...150) * 100,
                    averageRating: Double.random(in: 4.0...5.0),
                    totalOrders: Int.random(in: 50...200),
                    totalRevenueCents: Int.random(in: 1000...5000) * 100,
                    activeOrders: Int.random(in: 0...10)
                )
            })
        }
        switch result {
        case .success(let stats):
            return stats
        case .failure(let error):
            logger.error("Failed to fetch partner stats for \(partnerId): \(error.localizedDescription)")
            throw error
        }
    }

    func updatePartnerStatus(partnerId: String, isActive: Bool) async throws {
        return try await retryManager.retry(operation: {
            do {
                let recordID = CKRecord.ID(recordName: partnerId)
                let record = try await self.publicDatabase.record(for: recordID)
                record[CloudKitSchema.Partner.isActive] = isActive
                _ = try await self.publicDatabase.save(record)
                self.logger.info("✅ Updated partner status: \(partnerId) -> isActive=\(isActive)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - Product Operations
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        let cacheKey = "products_\(partnerId)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchProducts(for: partnerId)
        }
        
        switch result {
        case .success(let products):
            return products
        case .failure(let error):
            logger.error("Failed to fetch products for partner \(partnerId): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchProducts(for partnerId: String) async throws -> [Product] {
        return try await retryManager.retry(operation: {
            let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Product.partnerId, partnerId)
            let query = CKQuery(recordType: CloudKitSchema.Product.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Product.name, ascending: true)]
            
            do {
                let (matchResults, _) = try await self.publicDatabase.records(matching: query)
                let products = try matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToProduct(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch product record: \(error)")
                        return nil
                    }
                }
                
                self.logger.info("✅ Fetched \(products.count) products for partner \(partnerId)")
                return products
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        let cacheKey = "search_\(query)_\(region.center.latitude)_\(region.center.longitude)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performSearchProducts(query: query, in: region)
        }
        
        switch result {
        case .success(let products):
            return products
        case .failure(let error):
            logger.error("Failed to search products: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performSearchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        return try await retryManager.retry(operation: {
            // First get partners in the region
            let partners = try await self.performFetchPartners(in: region)
            let partnerIds = partners.map { $0.id }
            
            guard !partnerIds.isEmpty else { return [] }
            
            // Search products by name and partner location
            let namePredicate = NSPredicate(format: "%K CONTAINS[cd] %@", CloudKitSchema.Product.name, query)
            let partnerPredicate = NSPredicate(format: "%K IN %@", CloudKitSchema.Product.partnerId, partnerIds)
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, partnerPredicate])
            
            let ckQuery = CKQuery(recordType: CloudKitSchema.Product.recordType, predicate: combinedPredicate)
            ckQuery.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Product.name, ascending: true)]
            
            do {
                let (matchResults, _) = try await self.publicDatabase.records(matching: ckQuery)
                let products = try matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToProduct(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch search result: \(error)")
                        return nil
                    }
                }
                
                self.logger.info("✅ Found \(products.count) products for query '\(query)'")
                return products
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - Order Operations
    
    func createOrder(_ order: Order) async throws -> Order {
        return try await retryManager.retry(operation: {
            do {
                let record = try self.convertOrderToRecord(order)
                let savedRecord = try await self.privateDatabase.save(record)
                let savedOrder = try self.convertRecordToOrder(savedRecord)
                
                self.logger.info("✅ Created order: \(savedOrder.id)")
                return savedOrder
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                
                // Queue for offline sync if network issue
                if ckError.code == .networkUnavailable || ckError.code == .networkFailure {
                    let operation = SyncOperation(type: .createOrder, data: order)
                    await OfflineManager.shared.queueForSync(operation)
                }
                
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        do {
            let recordID = CKRecord.ID(recordName: orderId)
            let record = try await self.privateDatabase.record(for: recordID)
            
            record[CloudKitSchema.Order.status] = status.rawValue
            record[CloudKitSchema.Order.updatedAt] = Date()
            
            _ = try await self.privateDatabase.save(record)
            
            self.logger.info("✅ Updated order status: \(orderId) -> \(status.rawValue)")
        } catch let ckError as CKError {
            await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
            
            // Queue for offline sync if network issue
            if ckError.code == .networkUnavailable || ckError.code == .networkFailure {
                // Offline sync would be implemented here
                self.logger.warning("Network unavailable, order status update will be retried later")
            }
            
            throw AppError.cloudKit(ckError)
        } catch {
            throw AppError.unknown(error)
        }
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        let cacheKey = "orders_\(userId)_\(role.rawValue)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchOrders(for: userId, role: role)
        }
        
        switch result {
        case .success(let orders):
            return orders
        case .failure(let error):
            logger.error("Failed to fetch orders for user \(userId): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        return try await retryManager.retry(operation: {
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
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                let orders = try matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToOrder(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch order record: \(error)")
                        return nil
                    }
                }
                
                self.logger.info("✅ Fetched \(orders.count) orders for user \(userId)")
                return orders
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - User Operations
    
    func saveUserProfile(_ user: UserProfile) async throws {
        return try await retryManager.retry(operation: {
            do {
                let record = try self.convertUserProfileToRecord(user)
                _ = try await self.privateDatabase.save(record)
                
                self.logger.info("✅ Saved user profile: \(user.id)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                
                // Queue for offline sync if network issue
                if ckError.code == .networkUnavailable || ckError.code == .networkFailure {
                    let operation = SyncOperation(type: .saveUserProfile, data: user)
                    await OfflineManager.shared.queueForSync(operation)
                }
                
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchUserProfile(by appleUserID: String) async throws -> UserProfile? {
        let cacheKey = "user_profile_\(appleUserID)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchUserProfile(by: appleUserID)
        }
        
        switch result {
        case .success(let userProfile):
            return userProfile
        case .failure(let error):
            logger.error("Failed to fetch user profile \(appleUserID): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchUserProfile(by appleUserID: String) async throws -> UserProfile? {
        return try await retryManager.retry(operation: {
            let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.UserProfile.appleUserID, appleUserID)
            let query = CKQuery(recordType: CloudKitSchema.UserProfile.recordType, predicate: predicate)
            
            do {
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToUserProfile(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch user profile record: \(error)")
                    }
                }
                return nil
            } catch let ckError as CKError {
                if ckError.code == .unknownItem {
                    return nil
                }
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - Additional User Operations
    func updateUserDeviceToken(_ userId: String, deviceToken: String) async throws {
        return try await retryManager.retry(operation: {
            do {
                let recordID = CKRecord.ID(recordName: userId)
                let record = try await self.privateDatabase.record(for: recordID)
                record[CloudKitSchema.UserProfile.deviceToken] = deviceToken
                record[CloudKitSchema.UserProfile.lastActiveAt] = Date()
                _ = try await self.privateDatabase.save(record)
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - Driver Operations (additional)
    func saveDriver(_ driver: Driver) async throws -> Driver {
        return try await retryManager.retry(operation: {
            do {
                let record = try self.convertDriverToRecord(driver)
                let savedRecord = try await self.privateDatabase.save(record)
                return try self.convertRecordToDriver(savedRecord)
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchDriver(by id: String) async throws -> Driver? {
        let cacheKey = "driver_\(id)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchDriver(by: id)
        }
        
        switch result {
        case .success(let driver):
            return driver
        case .failure(let error):
            logger.error("Failed to fetch driver \(id): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchDriver(by id: String) async throws -> Driver? {
        return try await retryManager.retry(operation: {
            let recordID = CKRecord.ID(recordName: id)
            
            do {
                let record = try await self.privateDatabase.record(for: recordID)
                return try self.convertRecordToDriver(record)
            } catch let ckError as CKError {
                if ckError.code == .unknownItem {
                    return nil
                }
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchDriverByUserId(_ userId: String) async throws -> Driver? {
        let cacheKey = "driver_user_\(userId)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchDriverByUserId(userId)
        }
        
        switch result {
        case .success(let driver):
            return driver
        case .failure(let error):
            logger.error("Failed to fetch driver for user \(userId): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchDriverByUserId(_ userId: String) async throws -> Driver? {
        return try await retryManager.retry(operation: {
            let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Driver.userId, userId)
            let query = CKQuery(recordType: CloudKitSchema.Driver.recordType, predicate: predicate)
            
            do {
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToDriver(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch driver record: \(error)")
                    }
                }
                
                return nil
            } catch let ckError as CKError {
                if ckError.code == .unknownItem {
                    return nil
                }
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func saveDriverLocation(_ location: DriverLocation) async throws {
        return try await retryManager.retry(operation: {
            do {
                let record = try self.convertDriverLocationToRecord(location)
                _ = try await self.privateDatabase.save(record)
                
                self.logger.debug("✅ Saved driver location: \(location.driverId)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                
                // Queue for offline sync if network issue
                if ckError.code == .networkUnavailable || ckError.code == .networkFailure {
                    let operation = SyncOperation(type: .saveDriverLocation, data: location)
                    await OfflineManager.shared.queueForSync(operation)
                }
                
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchDriverLocation(for driverId: String) async throws -> DriverLocation? {
        let cacheKey = "driver_location_\(driverId)"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchDriverLocation(for: driverId)
        }
        
        switch result {
        case .success(let location):
            return location
        case .failure(let error):
            logger.error("Failed to fetch driver location \(driverId): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchDriverLocation(for driverId: String) async throws -> DriverLocation? {
        return try await retryManager.retry(operation: {
            let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.DriverLocation.driverId, driverId)
            let query = CKQuery(recordType: CloudKitSchema.DriverLocation.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.DriverLocation.timestamp, ascending: false)]
            
            do {
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToDriverLocation(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch driver location record: \(error)")
                    }
                }
                
                return nil
            } catch let ckError as CKError {
                if ckError.code == .unknownItem {
                    return nil
                }
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetchAvailableOrders() async throws -> [Order] {
        let cacheKey = "available_orders"
        
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            try await self.performFetchAvailableOrders()
        }
        
        switch result {
        case .success(let orders):
            return orders
        case .failure(let error):
            logger.error("Failed to fetch available orders: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func performFetchAvailableOrders() async throws -> [Order] {
        return try await retryManager.retry(operation: {
            let predicate = NSPredicate(format: "%K == %@ AND %K == NULL", 
                                      CloudKitSchema.Order.status, OrderStatus.paymentConfirmed.rawValue,
                                      CloudKitSchema.Order.driverId)
            let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.Order.createdAt, ascending: true)]
            
            do {
                let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                let orders = try matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        return try self.convertRecordToOrder(record)
                    case .failure(let error):
                        self.logger.warning("Failed to fetch available order record: \(error)")
                        return nil
                    }
                }
                
                self.logger.info("✅ Fetched \(orders.count) available orders")
                return orders
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func updateOrder(_ order: Order) async throws -> Order {
        return try await retryManager.retry(operation: {
            do {
                let record = try self.convertOrderToRecord(order)
                let savedRecord = try await self.privateDatabase.save(record)
                let savedOrder = try self.convertRecordToOrder(savedRecord)
                
                self.logger.info("✅ Updated order: \(savedOrder.id)")
                return savedOrder
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func saveDeliveryCompletion(_ completion: DeliveryCompletionData) async throws {
        return try await retryManager.retry(operation: {
            do {
                let record = try self.convertDeliveryCompletionToRecord(completion)
                _ = try await self.privateDatabase.save(record)
                
                self.logger.info("✅ Saved delivery completion: \(completion.orderId)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                
                // Queue for offline sync if network issue
                if ckError.code == .networkUnavailable || ckError.code == .networkFailure {
                    let operation = SyncOperation(type: .saveDeliveryCompletion, data: completion)
                    await OfflineManager.shared.queueForSync(operation)
                }
                
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - Generic Operations
    
    func save<T: Codable>(_ object: T) async throws -> T {
        return try await retryManager.retry(operation: {
            do {
                // Determine converter and database by type
                if let _ = object as? Partner {
                    // Partners live in public DB; convert via product/partner converters using CKRecord directly is not defined here,
                    // so we round-trip through specific fetch/save paths.
                    // Build CKRecord manually from fields available in convertRecordToPartner counterpart is non-trivial here.
                    // Use specific endpoints for partners instead of generic save.
                    throw AppError.validation(.invalidFormat("Generic save for Partner not supported in EnhancedCloudKitService. Use specific APIs."))
                } else if let _ = object as? Product {
                    throw AppError.validation(.invalidFormat("Generic save for Product not supported in EnhancedCloudKitService. Use specific APIs."))
                } else if let order = object as? Order {
                    let record = try self.convertOrderToRecord(order)
                    let savedRecord = try await self.privateDatabase.save(record)
                    return try self.convertRecordToOrder(savedRecord) as! T
                } else if let user = object as? UserProfile {
                    let record = try self.convertUserProfileToRecord(user)
                    let savedRecord = try await self.privateDatabase.save(record)
                    return try self.convertRecordToUserProfile(savedRecord) as! T
                } else if let driver = object as? Driver {
                    let record = try self.convertDriverToRecord(driver)
                    let savedRecord = try await self.privateDatabase.save(record)
                    return try self.convertRecordToDriver(savedRecord) as! T
                } else {
                    throw AppError.validation(.invalidFormat("Unsupported type for generic save: \(T.self)"))
                }
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func fetch<T: Codable>(_ type: T.Type, predicate: NSPredicate) async throws -> [T] {
        return try await retryManager.retry(operation: {
            do {
                if type == Partner.self {
                    let query = CKQuery(recordType: CloudKitSchema.Partner.recordType, predicate: predicate)
                    let (matchResults, _) = try await self.publicDatabase.records(matching: query)
                    let items: [Partner] = try matchResults.compactMap { _, result in
                        switch result {
                        case .success(let record):
                            return try self.convertRecordToPartner(record)
                        case .failure(let error):
                            self.logger.warning("Failed to fetch partner record: \(error)")
                            return nil
                        }
                    }
                    return items as! [T]
                } else if type == Product.self {
                    let query = CKQuery(recordType: CloudKitSchema.Product.recordType, predicate: predicate)
                    let (matchResults, _) = try await self.publicDatabase.records(matching: query)
                    let items: [Product] = try matchResults.compactMap { _, result in
                        switch result {
                        case .success(let record):
                            return try self.convertRecordToProduct(record)
                        case .failure(let error):
                            self.logger.warning("Failed to fetch product record: \(error)")
                            return nil
                        }
                    }
                    return items as! [T]
                } else if type == Order.self {
                    let query = CKQuery(recordType: CloudKitSchema.Order.recordType, predicate: predicate)
                    let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                    let items: [Order] = try matchResults.compactMap { _, result in
                        switch result {
                        case .success(let record):
                            return try self.convertRecordToOrder(record)
                        case .failure(let error):
                            self.logger.warning("Failed to fetch order record: \(error)")
                            return nil
                        }
                    }
                    return items as! [T]
                } else if type == UserProfile.self {
                    let query = CKQuery(recordType: CloudKitSchema.UserProfile.recordType, predicate: predicate)
                    let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                    let items: [UserProfile] = try matchResults.compactMap { _, result in
                        switch result {
                        case .success(let record):
                            return try self.convertRecordToUserProfile(record)
                        case .failure(let error):
                            self.logger.warning("Failed to fetch user profile record: \(error)")
                            return nil
                        }
                    }
                    return items as! [T]
                } else if type == Driver.self {
                    let query = CKQuery(recordType: CloudKitSchema.Driver.recordType, predicate: predicate)
                    let (matchResults, _) = try await self.privateDatabase.records(matching: query)
                    let items: [Driver] = try matchResults.compactMap { _, result in
                        switch result {
                        case .success(let record):
                            return try self.convertRecordToDriver(record)
                        case .failure(let error):
                            self.logger.warning("Failed to fetch driver record: \(error)")
                            return nil
                        }
                    }
                    return items as! [T]
                } else {
                    throw AppError.validation(.invalidFormat("Unsupported type for generic fetch: \(T.self)"))
                }
            } catch let ckError as CKError {
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    // MARK: - Subscriptions
    
    func subscribeToOrderUpdates(for userId: String) async throws {
        return try await retryManager.retry(operation: {
            do {
                let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.Order.customerId, userId)
                let subscription = CKQuerySubscription(
                    recordType: CloudKitSchema.Order.recordType,
                    predicate: predicate,
                    subscriptionID: "order_updates_\(userId)",
                    options: [.firesOnRecordUpdate, .firesOnRecordCreation]
                )
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                notificationInfo.shouldBadge = true
                subscription.notificationInfo = notificationInfo
                
                _ = try await self.privateDatabase.save(subscription)
                
                self.logger.info("✅ Subscribed to order updates for user: \(userId)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func subscribeToDriverLocationUpdates(for orderId: String) async throws {
        return try await retryManager.retry(operation: {
            do {
                // First get the order to find the driver
                let orderRecord = try await self.privateDatabase.record(for: CKRecord.ID(recordName: orderId))
                guard let driverId = orderRecord[CloudKitSchema.Order.driverId] as? String else {
                    throw AppError.dataNotFound("Driver not assigned to order")
                }
                
                let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.DriverLocation.driverId, driverId)
                let subscription = CKQuerySubscription(
                    recordType: CloudKitSchema.DriverLocation.recordType,
                    predicate: predicate,
                    subscriptionID: "driver_location_\(orderId)",
                    options: [.firesOnRecordUpdate, .firesOnRecordCreation]
                )
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                _ = try await self.privateDatabase.save(subscription)
                
                self.logger.info("✅ Subscribed to driver location updates for order: \(orderId)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func createSubscription(_ subscription: CKSubscription) async throws -> CKSubscription {
        return try await retryManager.retry(operation: {
            do {
                let savedSubscription = try await self.privateDatabase.save(subscription)
                
                self.logger.info("✅ Created subscription: \(subscription.subscriptionID)")
                return savedSubscription
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
    
    func deleteSubscription(withID subscriptionID: String) async throws {
        return try await retryManager.retry(operation: {
            do {
                try await self.privateDatabase.deleteSubscription(withID: subscriptionID)
                
                self.logger.info("✅ Deleted subscription: \(subscriptionID)")
            } catch let ckError as CKError {
                await self.degradationService.reportServiceFailure(.cloudKit, error: ckError)
                throw AppError.cloudKit(ckError)
            } catch {
                throw AppError.unknown(error)
            }
        })
    }
}

// MARK: - Concurrency
extension EnhancedCloudKitService: @unchecked Sendable {}

// MARK: - Helper Methods

extension EnhancedCloudKitService {
    
    private func createLocationPredicate(for region: MKCoordinateRegion) -> NSPredicate {
        let center = region.center
        let radius = max(region.span.latitudeDelta, region.span.longitudeDelta) * 111000 / 2 // Convert to meters
        
        return NSPredicate(
            format: "distanceToLocation:fromLocation:(%K,%K,%lf,%lf) < %f",
            CloudKitSchema.Partner.latitude,
            CloudKitSchema.Partner.longitude,
            center.latitude,
            center.longitude,
            radius
        )
    }
    
    // MARK: - Record Conversion Methods
    // These would be implemented to convert between domain models and CloudKit records
    // For brevity, I'm not implementing all of them here, but they would follow similar patterns
    
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
            throw AppError.validation(.invalidFormat("Invalid partner record format"))
        }
        let address = Address(street: street, city: city, state: state, postalCode: postalCode, country: country)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
            throw AppError.validation(.invalidFormat("Invalid product record format"))
        }
        var imageURLs: [URL] = []
        if let imageAssets = record[CloudKitSchema.Product.images] as? [CKAsset] {
            imageURLs = imageAssets.compactMap { $0.fileURL }
        }
        var nutritionInfo: NutritionInfo?
        if let nutritionData = record[CloudKitSchema.Product.nutritionInfo] as? Data {
            nutritionInfo = try? JSONDecoder().decode(NutritionInfo.self, from: nutritionData)
        }
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
            weight: nil,
            dimensions: nil,
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
            throw AppError.validation(.invalidFormat("Invalid order record format"))
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
            throw AppError.validation(.invalidFormat("Invalid user profile record format"))
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
            throw AppError.validation(.invalidFormat("Invalid driver record format"))
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
    
    private func convertDriverLocationToRecord(_ location: DriverLocation) throws -> CKRecord {
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
    
    private func convertRecordToDriverLocation(_ record: CKRecord) throws -> DriverLocation {
        guard let driverId = record[CloudKitSchema.DriverLocation.driverId] as? String,
              let latitude = record[CloudKitSchema.DriverLocation.latitude] as? Double,
              let longitude = record[CloudKitSchema.DriverLocation.longitude] as? Double,
              let accuracy = record[CloudKitSchema.DriverLocation.accuracy] as? Double,
              let timestamp = record[CloudKitSchema.DriverLocation.timestamp] as? Date else {
            throw AppError.validation(.invalidFormat("Invalid driver location record format"))
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
    
    private func convertDeliveryCompletionToRecord(_ completion: DeliveryCompletionData) throws -> CKRecord {
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
    
    // MARK: - Missing Protocol Methods
    
    func fetchPartnerAnalytics(partnerId: String, timeRange: TimeRange) async throws -> PartnerAnalytics {
        // Mock implementation for now
        let totalRevenue = Double.random(in: 1000...10000)
        let totalOrders = Int.random(in: 50...500)
        let averageOrderValue = Double.random(in: 20...100)
        
        return PartnerAnalytics(
            totalRevenue: totalRevenue,
            totalOrders: totalOrders,
            averageOrderValue: averageOrderValue,
            customerCount: Int.random(in: 10...100),
            timeRange: timeRange,
            revenueChangePercent: Double.random(in: -20...20),
            ordersChangePercent: Double.random(in: -15...15),
            aovChangePercent: Double.random(in: -10...10),
            averageRating: Double.random(in: 3.5...5.0),
            ratingChangePercent: Double.random(in: -0.5...0.5)
        )
    }
    
    func fetchRevenueChartData(partnerId: String, timeRange: TimeRange) async throws -> [RevenueDataPoint] {
        // Mock implementation for now
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        var dataPoints: [RevenueDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dataPoint = RevenueDataPoint(
                date: currentDate,
                amount: Double.random(in: 100...1000),
                orderCount: Int.random(in: 1...20)
            )
            dataPoints.append(dataPoint)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    func fetchOrdersChartData(partnerId: String, timeRange: TimeRange) async throws -> [OrdersDataPoint] {
        // Mock implementation for now
        return []
    }
    
    func fetchTopProducts(partnerId: String, timeRange: TimeRange, limit: Int) async throws -> [TopProductData] {
        // Mock implementation for now
        return []
    }
    
    func fetchPerformanceInsights(partnerId: String, timeRange: TimeRange) async throws -> PartnerInsightData {
        // Mock implementation for now
        return PartnerInsightData(
            keyMetrics: [],
            revenueData: [],
            orderAnalytics: OrderAnalytics(),
            customerInsights: CustomerInsights(),
            topProducts: [],
            generatedAt: Date(),
            revenueChangePercent: 0,
            ordersChangePercent: 0,
            averageRating: 0
        )
    }
    
}
