//
//  DriverDashboardViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import CoreLocation
import Combine

/// ViewModel for driver dashboard managing driver status, jobs, and earnings
@MainActor
@Observable
final class DriverDashboardViewModel {
    
    // MARK: - Published Properties
    
    var driverProfile: Driver?
    var isOnline: Bool = false
    var isAvailable: Bool = false
    var currentJob: Order?
    var availableJobs: [Order] = []
    var dailyEarnings: EarningsSummary?
    var weeklyEarnings: EarningsSummary?
    var isLoading: Bool = false
    var errorMessage: String?
    var showingJobCompletion: Bool = false
    
    // MARK: - Dependencies
    
    private let driverService: DriverService
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    private var jobStream: AsyncStream<Order>?
    private var locationUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(
        driverService: DriverService? = nil,
        locationService: LocationService? = nil
    ) {
        // Access AppContainer.shared properties on MainActor
        self.driverService = driverService ?? AppContainer.shared.driverService
        self.locationService = locationService ?? AppContainer.shared.locationService
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        Task {
            await loadDriverProfile()
            await loadCurrentJob()
            await loadEarnings()
            await startLocationUpdates()
        }
    }
    
    func onDisappear() {
        locationUpdateTask?.cancel()
        driverService.stopListeningForJobs()
    }
    
    // MARK: - Driver Status Management
    
    func toggleOnlineStatus() {
        guard let driverProfile = driverProfile else { return }
        
        Task {
            do {
                let newStatus = !isOnline
                try await driverService.updateOnlineStatus(newStatus, for: driverProfile.id)
                isOnline = newStatus
                
                if newStatus {
                    await startListeningForJobs()
                    await loadAvailableJobs()
                } else {
                    isAvailable = false
                    try await driverService.updateAvailabilityStatus(false, for: driverProfile.id)
                    driverService.stopListeningForJobs()
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func toggleAvailabilityStatus() {
        guard let driverProfile = driverProfile, isOnline else { return }
        
        Task {
            do {
                let newStatus = !isAvailable
                try await driverService.updateAvailabilityStatus(newStatus, for: driverProfile.id)
                isAvailable = newStatus
                
                if newStatus {
                    await loadAvailableJobs()
                } else {
                    availableJobs.removeAll()
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Job Management
    
    func acceptJob(_ job: Order) {
        guard let driverProfile = driverProfile else { return }
        
        Task {
            do {
                isLoading = true
                let acceptedJob = try await driverService.acceptJob(orderId: job.id, driverId: driverProfile.id)
                currentJob = acceptedJob
                
                // Remove accepted job from available jobs
                availableJobs.removeAll { $0.id == job.id }
                
                // Update availability to false when job is accepted
                isAvailable = false
                try await driverService.updateAvailabilityStatus(false, for: driverProfile.id)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func declineJob(_ job: Order) {
        guard let driverProfile = driverProfile else { return }
        
        Task {
            do {
                try await driverService.declineJob(orderId: job.id, driverId: driverProfile.id)
                availableJobs.removeAll { $0.id == job.id }
            } catch {
                handleError(error)
            }
        }
    }
    
    func updateJobStatus(_ status: OrderStatus) {
        guard let currentJob = currentJob else { return }
        
        Task {
            do {
                isLoading = true
                let updatedJob = try await driverService.updateJobStatus(orderId: currentJob.id, status: status)
                self.currentJob = updatedJob
                
                if status == .delivered {
                    // Job completed, reset current job and update availability
                    self.currentJob = nil
                    if let driverProfile = driverProfile {
                        isAvailable = true
                        try await driverService.updateAvailabilityStatus(true, for: driverProfile.id)
                    }
                    await loadEarnings() // Refresh earnings after completion
                }
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func completeDelivery(photoData: Data?, notes: String?) {
        guard let currentJob = currentJob else { return }
        
        Task {
            do {
                isLoading = true
                let _ = try await driverService.completeDelivery(
                    orderId: currentJob.id,
                    photoData: photoData,
                    completionNotes: notes
                )
                
                self.currentJob = nil
                
                // Update availability to accept new jobs
                if let driverProfile = driverProfile {
                    isAvailable = true
                    try await driverService.updateAvailabilityStatus(true, for: driverProfile.id)
                }
                
                await loadEarnings() // Refresh earnings
                showingJobCompletion = false
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    // MARK: - Data Loading
    
    func loadDriverProfile() async {
        do {
            driverProfile = try await driverService.getCurrentDriverProfile()
            if let profile = driverProfile {
                isOnline = profile.isOnline
                isAvailable = profile.isAvailable
            }
        } catch {
            handleError(error)
        }
    }
    
    func loadCurrentJob() async {
        guard let driverProfile = driverProfile else { return }
        
        do {
            currentJob = try await driverService.getCurrentJob(for: driverProfile.id)
        } catch {
            handleError(error)
        }
    }
    
    private func loadAvailableJobs() async {
        guard isOnline && isAvailable else {
            availableJobs.removeAll()
            return
        }
        
        do {
            availableJobs = try await driverService.fetchAvailableJobs()
        } catch {
            handleError(error)
        }
    }
    
    func loadEarnings() async {
        guard let driverProfile = driverProfile else { return }
        
        do {
            let today = Date()
            dailyEarnings = try await driverService.getDailyEarnings(for: today, driverId: driverProfile.id)
            
            let calendar = Calendar.current
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            weeklyEarnings = try await driverService.getWeeklyEarnings(for: startOfWeek, driverId: driverProfile.id)
        } catch {
            handleError(error)
        }
    }
    
    private func startListeningForJobs() async {
        guard let driverProfile = driverProfile else { return }
        
        do {
            let jobStream = try await driverService.startListeningForJobs(driverId: driverProfile.id)
            
            Task {
                for await job in jobStream {
                    // Add new jobs to available jobs if not already present
                    if !availableJobs.contains(where: { $0.id == job.id }) {
                        availableJobs.append(job)
                    }
                }
            }
        } catch {
            handleError(error)
        }
    }
    
    func startLocationUpdates() async {
        guard let driverProfile = driverProfile else { return }
        
        locationUpdateTask = Task {
            while !Task.isCancelled && isOnline {
                do {
                    let location = try await locationService.requestLocationPermission()
                    // Location permission granted, continue with location updates
                    
                    // Update location every 30 seconds while online
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                } catch {
                    // Log error but continue location updates
                    print("Location update failed: \(error)")
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        print("DriverDashboard Error: \(error)")
    }
}
