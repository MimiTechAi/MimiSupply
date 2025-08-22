//
//  DemoAuthService.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import Foundation
import Combine

/// Demo authentication service for testing different user roles
@MainActor
class DemoAuthService: ObservableObject {
    nonisolated(unsafe) static let shared = DemoAuthService()
    
    @Published var currentUser: DemoUser?
    @Published var isAuthenticated = false
    @Published var currentUserRole: UserRole?
    
    private init() {}
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws -> DemoUser {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        guard let user = DemoAccounts.findUser(email: email, password: password) else {
            throw DemoAuthError.invalidCredentials
        }
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.currentUserRole = user.role
        }
        
        return user
    }
    
    func quickLogin(role: UserRole) async throws -> DemoUser {
        let user: DemoUser
        
        switch role {
        case .customer:
            user = DemoAccounts.demoCustomers.first!
        case .partner:
            user = DemoAccounts.demoPartners.first!
        case .driver:
            user = DemoAccounts.demoDrivers.first!
        case .admin:
            throw DemoAuthError.roleNotSupported
        }
        
        return try await login(email: user.email, password: user.password)
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        currentUserRole = nil
    }
    
    // MARK: - Role-specific Methods
    
    func getPartnerInfo() -> Partner? {
        guard let user = currentUser,
              user.role == .partner,
              let partnerId = user.partnerId else {
            return nil
        }
        
        return GermanPartnerData.getPartner(by: partnerId)
    }
    
    func getDriverInfo() -> DemoDriverInfo? {
        guard let user = currentUser,
              user.role == .driver else {
            return nil
        }
        
        return user.driverInfo
    }
    
    func isCurrentUserPartner() -> Bool {
        return currentUser?.role == .partner
    }
    
    func isCurrentUserDriver() -> Bool {
        return currentUser?.role == .driver
    }
    
    func isCurrentUserCustomer() -> Bool {
        return currentUser?.role == .customer
    }
}

// MARK: - Demo Auth Errors
enum DemoAuthError: LocalizedError {
    case invalidCredentials
    case roleNotSupported
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Ungültige E-Mail oder Passwort"
        case .roleNotSupported:
            return "Diese Rolle wird in der Demo nicht unterstützt"
        case .networkError:
            return "Netzwerkfehler - bitte versuchen Sie es erneut"
        }
    }
}