//
//  DriverDashboardView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import CoreLocation

/// Driver dashboard with online/offline toggle, job management, and earnings tracking
struct DriverDashboardView: View {
    @State private var viewModel: DriverDashboardViewModel
    @State private var showingJobDetails = false
    @State private var selectedJob: Order?
    
    init() {
        self._viewModel = State(initialValue: DriverDashboardViewModel())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    statusCard
                    
                    // Current Job Card
                    if let currentJob = viewModel.currentJob {
                        currentJobCard(currentJob)
                    }
                    
                    // Available Jobs
                    if viewModel.isOnline && viewModel.isAvailable && !viewModel.availableJobs.isEmpty {
                        availableJobsSection
                    }
                    
                    // Earnings Summary
                    earningsSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                Task {
                    await viewModel.loadDriverProfile()
                    await viewModel.loadCurrentJob()
                    await viewModel.loadEarnings()
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
                JobDetailView(job: selectedJob) { action in
                    handleJobAction(job: selectedJob, action: action)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingJobCompletion) {
            if let currentJob = viewModel.currentJob {
                JobCompletionView(job: currentJob) { photoData, notes in
                    viewModel.completeDelivery(photoData: photoData, notes: notes)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Driver Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let driver = viewModel.driverProfile {
                        Text(driver.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    // Online/Offline Toggle
                    HStack {
                        Text("Online")
                            .font(.caption)
                        Toggle("", isOn: .constant(viewModel.isOnline))
                            .labelsHidden()
                            .onTapGesture {
                                viewModel.toggleOnlineStatus()
                            }
                    }
                    
                    // Available Toggle (only if online)
                    if viewModel.isOnline {
                        HStack {
                            Text("Available")
                                .font(.caption)
                            Toggle("", isOn: .constant(viewModel.isAvailable))
                                .labelsHidden()
                                .onTapGesture {
                                    viewModel.toggleAvailabilityStatus()
                                }
                        }
                    }
                }
            }
            
            // Status Indicators
            HStack(spacing: 16) {
                StatusIndicator(
                    title: "Status",
                    value: viewModel.isOnline ? "Online" : "Offline",
                    color: viewModel.isOnline ? .green : .gray
                )
                
                if viewModel.isOnline {
                    StatusIndicator(
                        title: "Availability",
                        value: viewModel.isAvailable ? "Available" : "Busy",
                        color: viewModel.isAvailable ? .blue : .orange
                    )
                }
                
                if let driver = viewModel.driverProfile {
                    StatusIndicator(
                        title: "Rating",
                        value: String(format: "%.1f", driver.rating),
                        color: .yellow
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Current Job Card
    
    private func currentJobCard(_ job: Order) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Delivery")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(job.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: job.status))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Order #\(job.id.prefix(8))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(job.deliveryAddress.singleLineAddress)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let instructions = job.deliveryInstructions {
                    Text("Instructions: \(instructions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(job.formattedTotal)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Action buttons based on job status
                jobActionButtons(for: job)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Available Jobs Section
    
    private var availableJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Jobs")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.availableJobs) { job in
                    AvailableJobCard(job: job) { action in
                        handleJobAction(job: job, action: action)
                    }
                }
            }
        }
    }
    
    // MARK: - Earnings Section
    
    private var earningsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Earnings")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Daily Earnings
                EarningsCard(
                    title: "Today",
                    amount: viewModel.dailyEarnings?.formattedTotalEarnings ?? "$0.00",
                    deliveries: viewModel.dailyEarnings?.totalDeliveries ?? 0
                )
                
                // Weekly Earnings
                EarningsCard(
                    title: "This Week",
                    amount: viewModel.weeklyEarnings?.formattedTotalEarnings ?? "$0.00",
                    deliveries: viewModel.weeklyEarnings?.totalDeliveries ?? 0
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func jobActionButtons(for job: Order) -> some View {
        HStack(spacing: 8) {
            switch job.status {
            case .driverAssigned, .readyForPickup:
                Button("Mark Picked Up") {
                    viewModel.updateJobStatus(.pickedUp)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
            case .pickedUp:
                Button("Start Delivery") {
                    viewModel.updateJobStatus(.delivering)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
            case .delivering:
                Button("Complete") {
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
