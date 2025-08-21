import SwiftUI
import Charts

/// Performance monitoring dashboard for development and debugging
struct PerformanceDashboard: View {
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var startupOptimizer = StartupOptimizer.shared
    @StateObject private var animationMonitor = AnimationPerformanceMonitor()
    
    @State private var isMonitoring = false
    @State private var performanceHistory: [PerformanceSnapshot] = []
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Real-time metrics
                    realTimeMetricsSection
                    
                    // Startup performance
                    startupPerformanceSection
                    
                    // Memory usage chart
                    memoryUsageSection
                    
                    // Animation performance
                    animationPerformanceSection
                    
                    // Performance history
                    performanceHistorySection
                    
                    // Controls
                    controlsSection
                }
                .padding()
            }
            .navigationTitle("Performance Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                startMonitoring()
            }
            .onDisappear {
                stopMonitoring()
            }
        }
    }
    
    private var realTimeMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real-time Metrics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "Memory Usage",
                    value: String(format: "%.1f MB", memoryManager.currentMemoryUsage),
                    change: 0.0, // Performance metrics don't have change tracking
                    icon: "memorychip"
                )
                
                MetricCard(
                    title: "Memory Warning",
                    value: memoryManager.memoryWarningLevel.description,
                    change: 0.0,
                    icon: "exclamationmark.triangle",

                )
                
                MetricCard(
                    title: "Animation FPS",
                    value: String(format: "%.1f", animationMonitor.averageFPS),
                    change: 0.0,
                    icon: "speedometer",

                )
                
                MetricCard(
                    title: "Dropped Frames",
                    value: "\(animationMonitor.droppedFrames)",
                    change: 0.0,
                    icon: "drop.triangle"
                )
            }
        }
    }
    
    private var startupPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Startup Performance")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Startup Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f seconds", startupOptimizer.startupTime))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(startupOptimizer.startupTime < 2.5 ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(startupOptimizer.isInitialized ? "Initialized" : "Loading")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(startupOptimizer.isInitialized ? .green : .orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var memoryUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage Over Time")
                .font(.headline)
            
            if !performanceHistory.isEmpty {
                Chart(performanceHistory) { snapshot in
                    LineMark(
                        x: .value("Time", snapshot.timestamp),
                        y: .value("Memory", snapshot.memoryUsage)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let mb = value.as(Double.self) {
                                Text("\(Int(mb)) MB")
                            }
                        }
                    }
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        Text("No data available")
                            .foregroundColor(.secondary)
                    )
                    .cornerRadius(12)
            }
        }
    }
    
    private var animationPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Animation Performance")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Average FPS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", animationMonitor.averageFPS))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(fpsColor(animationMonitor.averageFPS))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Dropped Frames")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(animationMonitor.droppedFrames)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(animationMonitor.droppedFrames > 10 ? .red : .green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var performanceHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance History")
                .font(.headline)
            
            if !performanceHistory.isEmpty {
                ForEach(performanceHistory.suffix(5).reversed(), id: \.timestamp) { snapshot in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(snapshot.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Memory: \(String(format: "%.1f MB", snapshot.memoryUsage))")
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("FPS: \(String(format: "%.1f", snapshot.fps))")
                                .font(.body)
                            Text("Frames: \(snapshot.droppedFrames)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if snapshot.timestamp != performanceHistory.suffix(5).last?.timestamp {
                        Divider()
                    }
                }
            } else {
                Text("No performance history available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                if isMonitoring {
                    stopMonitoring()
                } else {
                    startMonitoring()
                }
            }) {
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMonitoring ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: {
                performanceHistory.removeAll()
            }) {
                Text("Clear History")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: {
                memoryManager.performLeakDetection()
            }) {
                Text("Check for Memory Leaks")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func startMonitoring() {
        isMonitoring = true
        animationMonitor.startMonitoring()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let snapshot = PerformanceSnapshot(
                timestamp: Date(),
                memoryUsage: memoryManager.currentMemoryUsage,
                fps: animationMonitor.averageFPS,
                droppedFrames: animationMonitor.droppedFrames
            )
            
            performanceHistory.append(snapshot)
            
            // Keep only last 100 snapshots
            if performanceHistory.count > 100 {
                performanceHistory.removeFirst()
            }
        }
    }
    
    private func stopMonitoring() {
        isMonitoring = false
        animationMonitor.stopMonitoring()
        timer?.invalidate()
        timer = nil
    }
    
    private func memoryColorForUsage(_ usage: Double) -> Color {
        if usage < 100 { return .green }
        if usage < 200 { return .orange }
        return .red
    }
    
    private func colorForWarningLevel(_ level: MemoryManager.MemoryWarningLevel) -> Color {
        switch level {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private func fpsColor(_ fps: Double) -> Color {
        if fps >= 90 { return .green }
        if fps >= 60 { return .orange }
        return .red
    }
}

// MARK: - Supporting Views
// MetricCard is defined in Features/Partner/AnalyticsDashboardView.swift

// MARK: - Data Models

struct PerformanceSnapshot: Identifiable {
    let id = UUID()
    let timestamp: Date
    let memoryUsage: Double
    let fps: Double
    let droppedFrames: Int
}

// MARK: - Extensions

extension MemoryManager.MemoryWarningLevel {
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceDashboard()
}