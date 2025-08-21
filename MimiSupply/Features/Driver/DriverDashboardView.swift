//
//  DriverDashboardView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import CoreLocation
import MapKit

/// Enhanced driver dashboard with comprehensive job management, navigation, and earnings tracking
struct DriverDashboardView: View {
    @State private var viewModel: DriverDashboardViewModel
    @State private var showingJobDetails = false
    @State private var selectedJob: Order?
    @State private var showingNavigation = false
    @State private var showingEarningsDetail = false
    @State private var showingVehicleStatus = false
    @State private var showingCommunication = false
    
    init() {
        self._viewModel = State(initialValue: DriverDashboardViewModel())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Status Card with Quick Actions
                    enhancedStatusCard
                    
                    // Current Job Card with Navigation
                    if let currentJob = viewModel.currentJob {
                        enhancedCurrentJobCard(currentJob)
                    }
                    
                    // Job Queue (Multiple jobs)
                    if !viewModel.jobQueue.isEmpty {
                        jobQueueSection
                    }
                    
                    // Available Jobs with Smart Filtering
                    if viewModel.isOnline && viewModel.isAvailable && !viewModel.availableJobs.isEmpty {
                        enhancedAvailableJobsSection
                    }
                    
                    // Enhanced Earnings with Performance Metrics
                    enhancedEarningsSection
                    
                    // Quick Action Grid
                    quickActionGrid
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Fahrer Dashboard")
            .refreshable {
                Task {
                    await viewModel.refreshAllData()
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .sheet(isPresented: $showingJobDetails) {
            if let selectedJob = selectedJob {
                EnhancedJobDetailView(job: selectedJob) { action in
                    handleJobAction(job: selectedJob, action: action)
                }
            }
        }
        .sheet(isPresented: $showingNavigation) {
            if let currentJob = viewModel.currentJob {
                DriverNavigationView(job: currentJob)
            }
        }
        .sheet(isPresented: $showingEarningsDetail) {
            DriverEarningsDetailView(
                dailyEarnings: viewModel.dailyEarnings,
                weeklyEarnings: viewModel.weeklyEarnings,
                monthlyEarnings: viewModel.monthlyEarnings
            )
        }
        .sheet(isPresented: $showingVehicleStatus) {
            VehicleStatusView(
                vehicleInfo: viewModel.vehicleInfo,
                onUpdate: { updatedInfo in
                    viewModel.updateVehicleInfo(updatedInfo)
                }
            )
        }
        .sheet(isPresented: $showingCommunication) {
            if let currentJob = viewModel.currentJob {
                DriverCommunicationView(job: currentJob)
            }
        }
        .sheet(isPresented: $viewModel.showingJobCompletion) {
            if let currentJob = viewModel.currentJob {
                EnhancedJobCompletionView(job: currentJob) { photoData, notes, rating in
                    viewModel.completeDelivery(photoData: photoData, notes: notes, customerRating: rating)
                }
            }
        }
        .alert("Warnung", isPresented: $viewModel.showingBreakReminder) {
            Button("Pause einlegen") {
                viewModel.startBreak()
            }
            Button("Später erinnern") { }
        } message: {
            Text("Du arbeitest seit \(viewModel.workingHours) Stunden. Gönn dir eine Pause!")
        }
        .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Enhanced Status Card
    
    private var enhancedStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let driver = viewModel.driverProfile {
                        Text(driver.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Enhanced Status Controls
                VStack(spacing: 12) {
                    HStack {
                        Text("Online")
                            .font(.caption)
                        Toggle("", isOn: .constant(viewModel.isOnline))
                            .labelsHidden()
                            .onTapGesture {
                                viewModel.toggleOnlineStatus()
                            }
                    }
                    
                    if viewModel.isOnline {
                        HStack {
                            Text("Verfügbar")
                                .font(.caption)
                            Toggle("", isOn: .constant(viewModel.isAvailable))
                                .labelsHidden()
                                .onTapGesture {
                                    viewModel.toggleAvailabilityStatus()
                                }
                        }
                    }
                    
                    // Break Status
                    if viewModel.isOnBreak {
                        Button("Pause beenden") {
                            viewModel.endBreak()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
            }
            
            // Enhanced Status Indicators with Performance Metrics
            HStack(spacing: 16) {
                StatusIndicator(
                    title: "Status",
                    value: viewModel.statusText,
                    color: viewModel.statusColor
                )
                
                if viewModel.isOnline {
                    StatusIndicator(
                        title: "Heute",
                        value: "\(viewModel.todayDeliveries) Lieferungen",
                        color: .blue
                    )
                }
                
                if let driver = viewModel.driverProfile {
                    StatusIndicator(
                        title: "Rating",
                        value: String(format: "%.1f⭐", driver.rating),
                        color: .yellow
                    )
                }
                
                StatusIndicator(
                    title: "Arbeitszeit",
                    value: "\(viewModel.workingHours)h",
                    color: viewModel.workingHours > 8 ? .red : .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Enhanced Current Job Card
    
    private func enhancedCurrentJobCard(_ job: Order) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Aktuelle Lieferung")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack {
                    Text(job.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: job.status))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    // ETA
                    if let eta = viewModel.estimatedTimeOfArrival {
                        Text("ETA: \(eta.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Enhanced Job Info with Customer Details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Auftrag #\(job.id.prefix(8))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(job.formattedTotal)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                // Pickup Location
                if job.status == .driverAssigned || job.status == .readyForPickup {
                    LocationInfoCard(
                        title: "Abholung",
                        address: viewModel.pickupAddress?.singleLineAddress ?? "Restaurant",
                        icon: "bag",
                        color: .blue
                    )
                }
                
                // Delivery Location
                LocationInfoCard(
                    title: "Lieferung",
                    address: job.deliveryAddress.singleLineAddress,
                    icon: "house",
                    color: .green
                )
                
                if let instructions = job.deliveryInstructions {
                    Text("📝 \(instructions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            // Enhanced Action Buttons
            HStack(spacing: 12) {
                // Navigation Button
                Button(action: { showingNavigation = true }) {
                    HStack {
                        Image(systemName: "location")
                        Text("Navigation")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Communication Button
                Button(action: { showingCommunication = true }) {
                    HStack {
                        Image(systemName: "message")
                        Text("Kontakt")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Status Action Button
                jobActionButtons(for: job)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Job Queue Section
    
    private var jobQueueSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Job-Warteschlange (\(viewModel.jobQueue.count))")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(viewModel.jobQueue) { job in
                JobQueueCard(job: job) { action in
                    handleJobAction(job: job, action: action)
                }
            }
        }
    }
    
    // MARK: - Enhanced Available Jobs Section
    
    private var enhancedAvailableJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Verfügbare Aufträge")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Smart Filter Toggle
                Button(action: { viewModel.toggleSmartFilter() }) {
                    HStack {
                        Image(systemName: viewModel.smartFilterEnabled ? "brain.head.profile" : "line.horizontal.3.decrease")
                        Text(viewModel.smartFilterEnabled ? "Smart" : "Alle")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewModel.smartFilterEnabled ? Color.purple : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
            
            if viewModel.smartFilterEnabled {
                Text("🧠 Optimiert für deine Route und Präferenzen")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.availableJobs) { job in
                    EnhancedAvailableJobCard(
                        job: job,
                        distance: viewModel.getDistance(to: job),
                        estimatedEarnings: viewModel.getEstimatedEarnings(for: job)
                    ) { action in
                        handleJobAction(job: job, action: action)
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Earnings Section
    
    private var enhancedEarningsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Verdienste & Performance")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Details") {
                    showingEarningsDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                // Enhanced Daily Earnings
                EnhancedEarningsCard(
                    title: "Heute",
                    amount: viewModel.dailyEarnings?.formattedTotalEarnings ?? "€0,00",
                    breakdown: viewModel.dailyEarnings?.breakdown ?? "",
                    deliveries: viewModel.dailyEarnings?.totalDeliveries ?? 0,
                    color: .green
                )
                
                // Weekly Earnings
                EnhancedEarningsCard(
                    title: "Diese Woche",
                    amount: viewModel.weeklyEarnings?.formattedTotalEarnings ?? "€0,00",
                    breakdown: viewModel.weeklyEarnings?.breakdown ?? "",
                    deliveries: viewModel.weeklyEarnings?.totalDeliveries ?? 0,
                    color: .blue
                )
            }
            
            // Performance Metrics
            HStack(spacing: 16) {
                DriverPerformanceMetricCard(
                    title: "Pünktlichkeit",
                    value: "\(Int(viewModel.onTimeDeliveryRate * 100))%",
                    change: viewModel.onTimeDeliveryTrend,
                    icon: "clock"
                )
                
                DriverPerformanceMetricCard(
                    title: "Kundenbewertung",
                    value: String(format: "%.1f", viewModel.averageCustomerRating),
                    change: viewModel.ratingTrend,
                    icon: "star"
                )
                
                DriverPerformanceMetricCard(
                    title: "Effizienz",
                    value: String(format: "%.1f/h", viewModel.deliveriesPerHour),
                    change: viewModel.efficiencyTrend,
                    icon: "speedometer"
                )
            }
        }
    }
    
    // MARK: - Quick Action Grid
    
    private var quickActionGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schnellzugriff")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                DriverQuickActionButton(
                    title: "Fahrzeug",
                    icon: "car",
                    color: .blue,
                    badgeCount: viewModel.vehicleAlerts
                ) {
                    showingVehicleStatus = true
                }
                
                DriverQuickActionButton(
                    title: "Support",
                    icon: "headphones",
                    color: .orange
                ) {
                    viewModel.contactSupport()
                }
                
                DriverQuickActionButton(
                    title: "Notfall",
                    icon: "exclamationmark.triangle",
                    color: .red
                ) {
                    viewModel.triggerEmergency()
                }
                
                DriverQuickActionButton(
                    title: "Pause",
                    icon: "pause.circle",
                    color: viewModel.isOnBreak ? .green : .gray
                ) {
                    if viewModel.isOnBreak {
                        viewModel.endBreak()
                    } else {
                        viewModel.startBreak()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods (gleich wie vorher)
    
    private func jobActionButtons(for job: Order) -> some View {
        HStack(spacing: 8) {
            switch job.status {
            case .driverAssigned, .readyForPickup:
                Button("Abgeholt") {
                    viewModel.updateJobStatus(.pickedUp)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
            case .pickedUp:
                Button("Unterwegs") {
                    viewModel.updateJobStatus(.delivering)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
            case .delivering:
                Button("Abgeschlossen") {
                    viewModel.showingJobCompletion = true
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
            default:
                EmptyView()
            }
        }
    }
    
    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .driverAssigned, .readyForPickup:
            return .blue
        case .pickedUp, .delivering:
            return .orange
        case .delivered:
            return .green
        case .cancelled:
            return .red
        default:
            return .gray
        }
    }
    
    private func handleJobAction(job: Order, action: JobAction) {
        switch action {
        case .accept:
            viewModel.acceptJob(job)
        case .decline:
            viewModel.declineJob(job)
        case .viewDetails:
            selectedJob = job
            showingJobDetails = true
        }
    }
}

// MARK: - Enhanced Supporting Views

struct LocationInfoCard: View {
    let title: String
    let address: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(address)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct JobQueueCard: View {
    let job: Order
    let onAction: (JobAction) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Auftrag #\(job.id.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(job.deliveryAddress.city)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("ETA: \(job.estimatedDeliveryTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(job.formattedTotal)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Button("Details") {
                    onAction(.viewDetails)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EnhancedAvailableJobCard: View {
    let job: Order
    let distance: String?
    let estimatedEarnings: String?
    let onAction: (JobAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Auftrag #\(job.id.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let estimatedEarnings = estimatedEarnings {
                    Text(estimatedEarnings)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📍 \(job.deliveryAddress.city)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let distance = distance {
                        Text("🚗 \(distance)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Text(job.formattedTotal)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Button("Annehmen") {
                    onAction(.accept)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Button("Ablehnen") {
                    onAction(.decline)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Spacer()
                
                Button("Details") {
                    onAction(.viewDetails)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct EnhancedEarningsCard: View {
    let title: String
    let amount: String
    let breakdown: String
    let deliveries: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(amount)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            if !breakdown.isEmpty {
                Text(breakdown)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text("\(deliveries) Lieferungen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct DriverPerformanceMetricCard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack(spacing: 2) {
                Image(systemName: change > 0 ? "arrow.up" : change < 0 ? "arrow.down" : "minus")
                    .font(.caption2)
                    .foregroundColor(change > 0 ? .green : change < 0 ? .red : .gray)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DriverQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let badgeCount: Int?
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, badgeCount: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.badgeCount = badgeCount
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    if let badgeCount = badgeCount, badgeCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("\(badgeCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct AvailableJobCard: View {
    let job: Order
    let onAction: (JobAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Order #\(job.id.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(job.formattedTotal)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Text(job.deliveryAddress.singleLineAddress)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Button("Accept") {
                    onAction(.accept)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Button("Decline") {
                    onAction(.decline)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Spacer()
                
                Button("Details") {
                    onAction(.viewDetails)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EarningsCard: View {
    let title: String
    let amount: String
    let deliveries: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(amount)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(deliveries) deliveries")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

enum JobAction {
    case accept
    case decline
    case viewDetails
}

// MARK: - Preview

struct DriverDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DriverDashboardView()
    }
}