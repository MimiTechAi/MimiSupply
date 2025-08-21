//
//  DemoLoginView.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import SwiftUI

struct DemoLoginView: View {
    @State private var selectedRole: UserRole = .customer
    @State private var loginMessage = ""
    @State private var showingAlert = false
    
    private let emeraldGreen = Color(red: 0.31, green: 0.78, blue: 0.47)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [emeraldGreen.opacity(0.1), emeraldGreen.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(emeraldGreen)
                            
                            Text("MimiSupply Demo")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Wähle deinen Demo-Zugang")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // Role Selection
                        VStack(spacing: 20) {
                            Text("Demo-Rolle auswählen")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                ForEach([UserRole.customer, UserRole.partner, UserRole.driver], id: \.self) { role in
                                    RoleCard(
                                        role: role,
                                        isSelected: selectedRole == role
                                    ) {
                                        selectedRole = role
                                    }
                                }
                            }
                        }
                        
                        // Demo Accounts Section
                        VStack(spacing: 15) {
                            Text("Verfügbare Demo-Konten")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVStack(spacing: 10) {
                                ForEach(getAccountsForRole(selectedRole), id: \.id) { account in
                                    DemoAccountCard(account: account) {
                                        loginWithAccount(account)
                                    }
                                }
                            }
                        }
                        
                        // Quick Login Info
                        VStack(spacing: 10) {
                            Text("Demo-Zugangsdaten")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Kunden:")
                                        .fontWeight(.semibold)
                                    Text("kunde@test.de / kunde123")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Partner:")
                                        .fontWeight(.semibold)
                                    Text("mcdonalds@partner.de / partner123")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Fahrer:")
                                        .fontWeight(.semibold)
                                    Text("fahrer1@test.de / fahrer123")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Demo Login", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(loginMessage)
            }
        }
    }
    
    private func getAccountsForRole(_ role: UserRole) -> [DemoUser] {
        switch role {
        case .customer:
            return DemoAccounts.demoCustomers
        case .partner:
            return DemoAccounts.demoPartners
        case .driver:
            return DemoAccounts.demoDrivers
        case .admin:
            return []
        }
    }
    
    private func loginWithAccount(_ account: DemoUser) {
        // Hier würdest du den Login-Service aufrufen
        loginMessage = """
        Demo-Login erfolgreich!
        
        Rolle: \(account.role.displayName)
        Name: \(account.name)
        E-Mail: \(account.email)
        
        In einer echten App würdest du jetzt zur entsprechenden Hauptansicht weitergeleitet.
        """
        showingAlert = true
    }
}

// MARK: - Role Card
private struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    private let emeraldGreen = Color(red: 0.31, green: 0.78, blue: 0.47)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: roleIcon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : emeraldGreen)
                
                Text(role.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? emeraldGreen : Color.white)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var roleIcon: String {
        switch role {
        case .customer: return "person.fill"
        case .partner: return "storefront.fill"
        case .driver: return "car.fill"
        case .admin: return "person.badge.key.fill"
        }
    }
}

// MARK: - Demo Account Card
struct DemoAccountCard: View {
    let account: DemoUser
    let action: () -> Void
    
    private let emeraldGreen = Color(red: 0.31, green: 0.78, blue: 0.47)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Avatar
                Image(systemName: avatarIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(emeraldGreen)
                    .clipShape(Circle())
                
                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(account.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let info = additionalInfo {
                        Text(info)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Login Icon
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(emeraldGreen)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var avatarIcon: String {
        switch account.role {
        case .customer: return "person.fill"
        case .partner: return "storefront.fill"
        case .driver: return "car.fill"
        case .admin: return "person.badge.key.fill"
        }
    }
    
    private var additionalInfo: String? {
        switch account.role {
        case .partner:
            return account.businessCategory?.displayName
        case .driver:
            if let driverInfo = account.driverInfo {
                return "\(driverInfo.vehicleType) • ⭐ \(driverInfo.formattedRating)"
            }
            return nil
        default:
            return nil
        }
    }
}

#Preview {
    DemoLoginView()
}