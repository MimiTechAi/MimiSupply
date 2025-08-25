//
//  InteractiveCharts.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Charts

// MARK: - Interactive Chart Components

@available(iOS 16.0, *)
struct InteractiveLineChart<DataPoint: Identifiable>: View where DataPoint: Hashable {
    let data: [DataPoint]
    let xValue: KeyPath<DataPoint, Date>
    let yValue: KeyPath<DataPoint, Double>
    let title: String
    let color: Color
    
    @State private var selectedDataPoint: DataPoint?
    @State private var plotWidth: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and selected value display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let selected = selectedDataPoint {
                        Text("\(selected[keyPath: yValue], specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                    }
                }
                
                Spacer()
                
                // Interactive legend
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text("Values")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Interactive chart
            Chart(data) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint[keyPath: xValue]),
                    y: .value("Value", dataPoint[keyPath: yValue])
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                .opacity(isAnimating ? 1.0 : 0.0)
                
                AreaMark(
                    x: .value("Date", dataPoint[keyPath: xValue]),
                    y: .value("Value", dataPoint[keyPath: yValue])
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isAnimating ? 0.8 : 0.0)
                
                // Selected point indicator
                if let selected = selectedDataPoint,
                   selected.id == dataPoint.id {
                    PointMark(
                        x: .value("Date", dataPoint[keyPath: xValue]),
                        y: .value("Value", dataPoint[keyPath: yValue])
                    )
                    .foregroundStyle(color)
                    .symbolSize(100)
                }
            }
            .frame(height: 200)
            .chartBackground { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSelection(at: value.location, geometry: geometry, proxy: proxy)
                                }
                        )
                        .onAppear {
                            plotWidth = geometry.size.width
                        }
                }
            }
            .chartAngleSelection(value: .constant(nil))
            .animation(.easeInOut(duration: 1.0), value: isAnimating)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                    isAnimating = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private func updateSelection(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let xPosition = location.x / geometry.size.width
        
        // Find the closest data point
        guard !data.isEmpty else { return }
        
        let sortedData = data.sorted { $0[keyPath: xValue] < $1[keyPath: xValue] }
        let totalDuration = sortedData.last![keyPath: xValue].timeIntervalSince(sortedData.first![keyPath: xValue])
        let selectedTime = sortedData.first![keyPath: xValue].addingTimeInterval(totalDuration * xPosition)
        
        selectedDataPoint = sortedData.min { dataPoint1, dataPoint2 in
            abs(dataPoint1[keyPath: xValue].timeIntervalSince(selectedTime)) <
            abs(dataPoint2[keyPath: xValue].timeIntervalSince(selectedTime))
        }
    }
}

@available(iOS 16.0, *)
struct InteractiveBarChart<DataPoint: Identifiable>: View where DataPoint: Hashable {
    let data: [DataPoint]
    let xValue: KeyPath<DataPoint, String>
    let yValue: KeyPath<DataPoint, Double>
    let title: String
    let colors: [Color]
    
    @State private var selectedDataPoint: DataPoint?
    @State private var animationProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(selected[keyPath: xValue])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(selected[keyPath: yValue], specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Interactive bar chart
            Chart(data.enumerated().map { IndexedDataPoint(index: $0, dataPoint: $1) }, id: \.dataPoint.id) { indexedPoint in
                BarMark(
                    x: .value("Category", indexedPoint.dataPoint[keyPath: xValue]),
                    y: .value("Value", indexedPoint.dataPoint[keyPath: yValue] * animationProgress)
                )
                .foregroundStyle(getColor(for: indexedPoint.index))
                .opacity(selectedDataPoint?.id == indexedPoint.dataPoint.id ? 1.0 : 0.8)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartBackground { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            updateSelection(at: location, geometry: geometry, proxy: proxy)
                        }
                }
            }
            .animation(.easeOut(duration: 1.0), value: animationProgress)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    animationProgress = 1.0
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private struct IndexedDataPoint {
        let index: Int
        let dataPoint: DataPoint
    }
    
    private func getColor(for index: Int) -> Color {
        return colors[index % colors.count]
    }
    
    private func updateSelection(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let xPosition = location.x / geometry.size.width
        let barWidth = geometry.size.width / CGFloat(data.count)
        let selectedIndex = Int(xPosition / (barWidth / geometry.size.width))
        
        if selectedIndex >= 0 && selectedIndex < data.count {
            selectedDataPoint = data[selectedIndex]
        }
    }
}

@available(iOS 16.0, *)
struct InteractivePieChart<DataPoint: Identifiable>: View where DataPoint: Hashable {
    let data: [DataPoint]
    let valueKeyPath: KeyPath<DataPoint, Double>
    let labelKeyPath: KeyPath<DataPoint, String>
    let title: String
    let colors: [Color]
    
    @State private var selectedSegment: DataPoint?
    @State private var animationProgress: Double = 0
    
    private var totalValue: Double {
        data.reduce(0) { $0 + $1[keyPath: valueKeyPath] }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let selected = selectedSegment {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(selected[keyPath: labelKeyPath])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(selected[keyPath: valueKeyPath], specifier: "%.1f")%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            HStack(spacing: 24) {
                // Pie chart
                ZStack {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, dataPoint in
                        PieSlice(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            isSelected: selectedSegment?.id == dataPoint.id
                        )
                        .fill(colors[index % colors.count])
                        .scaleEffect(selectedSegment?.id == dataPoint.id ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedSegment?.id)
                        .onTapGesture {
                            selectedSegment = dataPoint
                        }
                    }
                }
                .frame(width: 200, height: 200)
                .scaleEffect(animationProgress)
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animationProgress)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, dataPoint in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colors[index % colors.count])
                                .frame(width: 12, height: 12)
                            
                            Text(dataPoint[keyPath: labelKeyPath])
                                .font(.caption)
                                .foregroundColor(selectedSegment?.id == dataPoint.id ? .primary : .secondary)
                            
                            Spacer()
                            
                            Text("\(dataPoint[keyPath: valueKeyPath], specifier: "%.1f")%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedSegment?.id == dataPoint.id ? .primary : .secondary)
                        }
                        .padding(.vertical, 2)
                        .onTapGesture {
                            selectedSegment = dataPoint
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let previousSum = data.prefix(index).reduce(0) { $0 + $1[keyPath: valueKeyPath] }
        return Angle.degrees((previousSum / totalValue) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let sum = data.prefix(index + 1).reduce(0) { $0 + $1[keyPath: valueKeyPath] }
        return Angle.degrees((sum / totalValue) * 360 - 90)
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let isSelected: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let adjustedRadius = isSelected ? radius * 0.9 : radius
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: adjustedRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Real-time Chart

@available(iOS 16.0, *)
struct RealTimeChart<DataPoint: Identifiable>: View where DataPoint: Hashable {
    let data: [DataPoint]
    let xValue: KeyPath<DataPoint, Date>
    let yValue: KeyPath<DataPoint, Double>
    let title: String
    let color: Color
    let updateInterval: TimeInterval
    
    @State private var isUpdating = false
    @State private var lastUpdateTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isUpdating ? .green : .gray)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: isUpdating)
                    
                    Text(isUpdating ? "Live" : "Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Chart(data.suffix(50)) { dataPoint in // Show last 50 points
                LineMark(
                    x: .value("Time", dataPoint[keyPath: xValue]),
                    y: .value("Value", dataPoint[keyPath: yValue])
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", dataPoint[keyPath: xValue]),
                    y: .value("Value", dataPoint[keyPath: yValue])
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 150)
            .chartXScale(domain: .automatic(includesZero: false))
            .chartYScale(domain: .automatic(includesZero: false))
            .animation(.easeInOut(duration: 0.5), value: data.count)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onReceive(Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isUpdating.toggle()
            }
            lastUpdateTime = Date()
        }
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
struct InteractiveCharts_Previews: PreviewProvider {
    static let sampleLineData = [
        ChartDataPoint(date: Date().addingTimeInterval(-86400 * 6), value: 120, label: "Day 1"),
        ChartDataPoint(date: Date().addingTimeInterval(-86400 * 5), value: 150, label: "Day 2"),
        ChartDataPoint(date: Date().addingTimeInterval(-86400 * 4), value: 110, label: "Day 3"),
        ChartDataPoint(date: Date().addingTimeInterval(-86400 * 3), value: 180, label: "Day 4"),
        ChartDataPoint(date: Date().addingTimeInterval(-86400 * 2), value: 160, label: "Day 5"),
        ChartDataPoint(date: Date().addingTimeInterval(-86400 * 1), value: 190, label: "Day 6"),
        ChartDataPoint(date: Date(), value: 200, label: "Today")
    ]
    
    static let sampleBarData = [
        ChartDataPoint(date: Date(), value: 25, label: "Products"),
        ChartDataPoint(date: Date(), value: 35, label: "Services"),
        ChartDataPoint(date: Date(), value: 20, label: "Support"),
        ChartDataPoint(date: Date(), value: 20, label: "Marketing")
    ]
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                InteractiveLineChart(
                    data: sampleLineData,
                    xValue: \.date,
                    yValue: \.value,
                    title: "Revenue Trend",
                    color: .emerald
                )
                
                InteractiveBarChart(
                    data: sampleBarData,
                    xValue: \.label,
                    yValue: \.value,
                    title: "Department Performance",
                    colors: [.emerald, .blue, .orange, .purple]
                )
                
                InteractivePieChart(
                    data: sampleBarData,
                    valueKeyPath: \.value,
                    labelKeyPath: \.label,
                    title: "Budget Distribution",
                    colors: [.emerald, .blue, .orange, .purple]
                )
            }
            .padding()
        }
    }
}