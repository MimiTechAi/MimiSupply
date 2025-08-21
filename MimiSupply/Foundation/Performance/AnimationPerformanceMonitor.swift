//
//  AnimationPerformanceMonitor.swift
//  MimiSupply
//
//  Created by Cascade on 20.08.25.
//

import Foundation
import UIKit

public struct AnimationPerformanceReport {
    public let averageFPS: Double
    public let droppedFramePercentage: Double
    public let totalFrames: Int
    public let duration: TimeInterval
}

@MainActor
final class AnimationPerformanceMonitor: ObservableObject {
    // Published metrics for SwiftUI dashboards
    @Published private(set) var averageFPS: Double = 0
    @Published private(set) var droppedFrames: Int = 0
    
    // Internal state
    private var isMonitoring = false
    private var frameCount = 0
    private var startTime: CFAbsoluteTime = 0
    private var displayLink: CADisplayLink?
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        frameCount = 0
        droppedFrames = 0
        averageFPS = 0
        startTime = CFAbsoluteTimeGetCurrent()
        
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleDisplayLink() {
        guard isMonitoring else { return }
        frameCount += 1
        
        // Simplified dropped frame detection similar to tests
        if (displayLink?.duration ?? 0) > (1.0 / 60.0) {
            droppedFrames += 1
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed > 0 {
            averageFPS = Double(frameCount) / elapsed
        }
    }
    
    func getPerformanceReport() -> AnimationPerformanceReport {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let avg = elapsed > 0 ? Double(frameCount) / elapsed : 0
        let dropPct = frameCount > 0 ? (Double(droppedFrames) / Double(frameCount)) * 100.0 : 0
        return AnimationPerformanceReport(
            averageFPS: avg,
            droppedFramePercentage: dropPct,
            totalFrames: frameCount,
            duration: elapsed
        )
    }
}
