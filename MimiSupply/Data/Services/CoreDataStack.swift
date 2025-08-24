//
//  CoreDataStack.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreData
import CloudKit

/// Core Data stack for offline data persistence
@MainActor
final class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MimiSupply")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        // Configure for concurrency
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Use MainActor for safe access to merge policy
        Task { @MainActor in
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        return container
    }()
    
    private init() {}
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func saveContext() async {
        await MainActor.run {
            save()
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        }
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