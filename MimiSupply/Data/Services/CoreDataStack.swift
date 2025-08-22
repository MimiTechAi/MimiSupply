//
//  CoreDataStack.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreData
import CloudKit

// @MainActor ensures that global mutable Core Data policies and context are only accessed from the main thread, making merge policy assignments concurrency safe.
@MainActor
@preconcurrency final class CoreDataStack: ObservableObject, @unchecked Sendable {
    
    nonisolated(unsafe) static let shared = CoreDataStack()
    
    // MARK: - Thread Safety
    private let queue = DispatchQueue(label: "com.mimisupply.coredata", qos: .userInitiated)
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "MimiSupplyDataModel")
        
        // Configure CloudKit integration
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        // Enable CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        // CloudKit container identifier is set in the data model, not here
        
        container.loadPersistentStores { _, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        // Enable automatic merging from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Set merge policy for conflict resolution
        if #available(iOS 16.0, *) {
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        } else {
            // For iOS < 16, use the constant directly
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Background Context
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save Operations
    
    func save() {
        queue.sync {
            let context = persistentContainer.viewContext
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Failed to save Core Data context: \(error)")
                }
            }
        }
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        queue.sync {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Failed to save Core Data context: \(error)")
                }
            }
        }
    }
    
    // MARK: - CloudKit Sync Status
    
    func checkCloudKitStatus() async -> CKAccountStatus {
        do {
            return try await CKContainer.default().accountStatus()
        } catch {
            print("Failed to check CloudKit status: \(error)")
            return .couldNotDetermine
        }
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflicts() {
        let context = viewContext
        
        // Implement custom conflict resolution logic here
        // This is called when CloudKit sync conflicts occur
        
        context.perform {
            // Process any pending changes
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Failed to resolve conflicts: \(error)")
                }
            }
        }
    }
    
    // MARK: - Data Migration
    
    func performMigrationIfNeeded() {
        // Implement data migration logic for schema changes
        // This ensures smooth updates when the data model changes
    }
    
    private init() {
        // Setup remote change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        // Handle remote changes from CloudKit
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Cart Management

extension CoreDataStack {
    
    /// Save cart items locally for offline access
    func saveCartItems(_ items: [CartItem]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let context = self.newBackgroundContext()
            
            context.perform {
                // Clear existing cart items
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CartItemEntity")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteRequest)
                    
                    // Save new cart items
                    for item in items {
                        let entity = CartItemEntity(context: context)
                        entity.id = item.id
                        entity.productData = try JSONEncoder().encode(item.product)
                        entity.quantity = Int32(item.quantity)
                        entity.specialInstructions = item.specialInstructions
                        entity.addedAt = item.addedAt
                    }
                    
                    try context.save()
                } catch {
                    print("Failed to save cart items: \(error)")
                }
            }
        }
    }
    
    /// Load cart items from local storage
    func loadCartItems() -> [CartItem] {
        return queue.sync {
            let context = viewContext
            let fetchRequest: NSFetchRequest<CartItemEntity> = CartItemEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { entity in
                    guard let id = entity.id,
                          let productData = entity.productData,
                          let addedAt = entity.addedAt,
                          let product = try? JSONDecoder().decode(Product.self, from: productData) else {
                        return nil
                    }
                    
                    return CartItem(
                        id: id,
                        product: product,
                        quantity: Int(entity.quantity),
                        specialInstructions: entity.specialInstructions,
                        addedAt: addedAt
                    )
                }
            } catch {
                print("Failed to load cart items: \(error)")
                return []
            }
        }
    }
    
    /// Clear all cart items
    func clearCart() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let context = self.newBackgroundContext()
            
            context.perform {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CartItemEntity")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteRequest)
                    try context.save()
                } catch {
                    print("Failed to clear cart: \(error)")
                }
            }
        }
    }
}

// MARK: - Offline Data Management

extension CoreDataStack {
    
    /// Cache partners for offline access
    func cachePartners(_ partners: [Partner]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let context = self.newBackgroundContext()
            
            context.perform {
                for partner in partners {
                    let fetchRequest: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", partner.id)
                    
                    do {
                        let existingEntities = try context.fetch(fetchRequest)
                        let entity = existingEntities.first ?? PartnerEntity(context: context)
                        
                        entity.id = partner.id
                        entity.name = partner.name
                        entity.category = partner.category.rawValue
                        entity.partnerData = try JSONEncoder().encode(partner)
                        entity.lastUpdated = Date()
                        
                    } catch {
                        print("Failed to cache partner \(partner.id): \(error)")
                    }
                }
                
                self.saveContext(context)
            }
        }
    }
    
    /// Load cached partners for offline use
    func loadCachedPartners() -> [Partner] {
        return queue.sync {
            let context = viewContext
            let fetchRequest: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { entity in
                    guard let partnerData = entity.partnerData,
                          let partner = try? JSONDecoder().decode(Partner.self, from: partnerData) else {
                        return nil
                    }
                    return partner
                }
            } catch {
                print("Failed to load cached partners: \(error)")
                return []
            }
        }
    }
    
    /// Cache products for offline access
    func cacheProducts(_ products: [Product], for partnerId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let context = self.newBackgroundContext()
            
            context.perform {
                for product in products {
                    let fetchRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", product.id)
                    
                    do {
                        let existingEntities = try context.fetch(fetchRequest)
                        let entity = existingEntities.first ?? ProductEntity(context: context)
                        
                        entity.id = product.id
                        entity.partnerId = product.partnerId
                        entity.name = product.name
                        entity.category = product.category.rawValue
                        entity.priceCents = Int32(product.priceCents)
                        entity.isAvailable = product.isAvailable
                        entity.productData = try JSONEncoder().encode(product)
                        entity.lastUpdated = Date()
                        
                    } catch {
                        print("Failed to cache product \(product.id): \(error)")
                    }
                }
                
                self.saveContext(context)
            }
        }
    }
    
    /// Load cached products for offline use
    func loadCachedProducts(for partnerId: String) -> [Product] {
        return queue.sync {
            let context = viewContext
            let fetchRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "partnerId == %@", partnerId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { entity in
                    guard let productData = entity.productData,
                          let product = try? JSONDecoder().decode(Product.self, from: productData) else {
                        return nil
                    }
                    return product
                }
            } catch {
                print("Failed to load cached products: \(error)")
                return []
            }
        }
    }
}
