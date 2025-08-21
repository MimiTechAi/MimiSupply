//
//  TimeRange.swift
//  MimiSupply
//
//  Created by Kiro on 16.08.25.
//

import Foundation

/// Time range options for analytics and reporting
enum TimeRange: String, CaseIterable, Codable {
    case day = "day"
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day:
            return "Today"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .quarter:
            return "This Quarter"
        case .year:
            return "This Year"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
            
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return (startOfMonth, endOfMonth)
            
        case .quarter:
            let currentQuarter = calendar.component(.quarter, from: now)
            let startOfYear = calendar.dateInterval(of: .year, for: now)!.start
            let startOfQuarter = calendar.date(byAdding: .month, value: (currentQuarter - 1) * 3, to: startOfYear)!
            let endOfQuarter = calendar.date(byAdding: .month, value: 3, to: startOfQuarter)!
            return (startOfQuarter, endOfQuarter)
            
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)!.start
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!
            return (startOfYear, endOfYear)
        }
    }
}