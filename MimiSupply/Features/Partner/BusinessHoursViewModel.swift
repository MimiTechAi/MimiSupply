import SwiftUI
import Combine

@MainActor
class BusinessHoursViewModel: ObservableObject {
    @Published var businessHours: [WeekDay: OpeningHours] = [:]
    @Published var specialHours: [SpecialHour] = []
    @Published var isCurrentlyOpen: Bool = false
    @Published var preparationTime: Int = 15
    @Published var deliveryRadius: Double = 5.0
    @Published var minimumOrderAmount: Double = 0.0
    @Published var isSaving: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingHolidayHours: Bool = false
    
    private let cloudKitService: CloudKitService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        authService: AuthenticationService = AuthenticationServiceImpl.shared
    ) {
        self.cloudKitService = cloudKitService
        self.authService = authService
        
        setupDefaultHours()
    }
    
    func loadBusinessHours() async {
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            let partner = try await cloudKitService.fetchPartner(by: currentUser.id)
            
            businessHours = partner?.openingHours ?? [:]
            isCurrentlyOpen = partner?.isActive ?? false
            preparationTime = partner?.estimatedDeliveryTime ?? 30
            deliveryRadius = partner?.deliveryRadius ?? 5.0
            minimumOrderAmount = Double(partner?.minimumOrderAmount ?? 0) / 100.0
            
            // Load special hours
            specialHours = try await cloudKitService.fetchSpecialHours(for: currentUser.id)
            
        } catch {
            handleError(error)
        }
    }
    
    func saveChanges() async {
        isSaving = true
        
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            let businessSettings = BusinessSettings(
                openingHours: businessHours,
                isActive: isCurrentlyOpen,
                preparationTime: preparationTime,
                deliveryRadius: deliveryRadius,
                minimumOrderAmount: Int(minimumOrderAmount * 100)
            )
            
            try await cloudKitService.updateBusinessSettings(
                partnerId: currentUser.id,
                settings: businessSettings
            )
            
            // Save special hours
            try await cloudKitService.updateSpecialHours(
                partnerId: currentUser.id,
                specialHours: specialHours
            )
            
        } catch {
            handleError(error)
        }
        
        isSaving = false
    }
    
    func toggleBusinessStatus(_ isOpen: Bool) {
        Task {
            do {
                guard let currentUser = await authService.currentUser else {
                    throw AppError.authentication(.notAuthenticated)
                }
                
                try await cloudKitService.updatePartnerStatus(
                    partnerId: currentUser.id,
                    isActive: isOpen
                )
                
            } catch {
                // Revert the toggle on error
                isCurrentlyOpen = !isOpen
                handleError(error)
            }
        }
    }
    
    func updateHours(for day: WeekDay, hours: OpeningHours) {
        businessHours[day] = hours
    }
    
    func addSpecialHour(_ specialHour: SpecialHour) {
        specialHours.append(specialHour)
    }
    
    func deleteSpecialHour(_ specialHour: SpecialHour) {
        specialHours.removeAll { $0.id == specialHour.id }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultHours() {
        let defaultOpenTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let defaultCloseTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        
        for day in WeekDay.allCases {
            businessHours[day] = .open(defaultOpenTime, defaultCloseTime)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - CloudKit Service Extensions
extension CloudKitService {
    func fetchSpecialHours(for partnerId: String) async throws -> [SpecialHour] {
        // Mock implementation - in real app, this would fetch from CloudKit
        return [
            SpecialHour(
                id: "holiday1",
                name: "Christmas Day",
                startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 25)) ?? Date(),
                endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 25)) ?? Date(),
                hours: .closed
            ),
            SpecialHour(
                id: "holiday2",
                name: "New Year's Day",
                startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date(),
                endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date(),
                hours: .open(
                    Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date(),
                    Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
                )
            )
        ]
    }
    
    func updateBusinessSettings(partnerId: String, settings: BusinessSettings) async throws {
        // Implementation would update business settings in CloudKit
        print("Updating business settings for partner: \(partnerId)")
        print("Settings: \(settings)")
    }
    
    func updateSpecialHours(partnerId: String, specialHours: [SpecialHour]) async throws {
        // Implementation would update special hours in CloudKit
        print("Updating special hours for partner: \(partnerId)")
        print("Special hours count: \(specialHours.count)")
    }
}

// MARK: - Supporting Types
struct BusinessSettings {
    let openingHours: [WeekDay: OpeningHours]
    let isActive: Bool
    let preparationTime: Int
    let deliveryRadius: Double
    let minimumOrderAmount: Int
}
