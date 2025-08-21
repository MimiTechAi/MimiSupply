//
//  LocaleFormatter.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation

/// Comprehensive locale-specific formatting utilities
final class LocaleFormatter {
    
    // MARK: - Singleton
    
    static let shared = LocaleFormatter()
    
    // MARK: - Private Properties
    
    @MainActor private let localizationManager = LocalizationManager.shared
    
    // MARK: - Formatters
    
    @MainActor private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = localizationManager.currentLocale
        return formatter
    }()
    
    @MainActor private lazy var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = localizationManager.currentLocale
        return formatter
    }()
    
    @MainActor private lazy var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = localizationManager.currentLocale
        return formatter
    }()
    
    @MainActor private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = localizationManager.currentLocale
        return formatter
    }()
    
    @MainActor private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = localizationManager.currentLocale
        formatter.timeStyle = .short
        return formatter
    }()
    
    @MainActor private lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = localizationManager.currentLocale
        formatter.unitsStyle = .full
        return formatter
    }()
    
    @MainActor private lazy var measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.locale = localizationManager.currentLocale
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Currency Formatting
    
    /// Format currency amount in cents
    @MainActor
    func formatCurrency(_ amountInCents: Int, currencyCode: String = "USD") -> String {
        currencyFormatter.currencyCode = currencyCode
        let decimalAmount = Double(amountInCents) / 100.0
        return currencyFormatter.string(from: NSNumber(value: decimalAmount)) ?? formatFallbackCurrency(decimalAmount, currencyCode: currencyCode)
    }
    
    /// Format currency with custom symbol
    @MainActor func formatCurrencyWithSymbol(_ amountInCents: Int, symbol: String) -> String {
        let decimalAmount = Double(amountInCents) / 100.0
        let numberString = decimalFormatter.string(from: NSNumber(value: decimalAmount)) ?? String(format: "%.2f", decimalAmount)
        
        if localizationManager.isRightToLeft {
            return "\(numberString) \(symbol)"
        } else {
            return "\(symbol)\(numberString)"
        }
    }
    
    // MARK: - Number Formatting
    
    /// Format decimal number
    @MainActor func formatNumber(_ number: Double, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        decimalFormatter.minimumFractionDigits = minimumFractionDigits
        decimalFormatter.maximumFractionDigits = maximumFractionDigits
        return decimalFormatter.string(from: NSNumber(value: number)) ?? String(format: "%.2f", number)
    }
    
    /// Format integer
    @MainActor func formatInteger(_ number: Int) -> String {
        decimalFormatter.minimumFractionDigits = 0
        decimalFormatter.maximumFractionDigits = 0
        return decimalFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Format percentage
    @MainActor func formatPercentage(_ value: Double) -> String {
        return percentFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f%%", value * 100)
    }
    
    // MARK: - Date and Time Formatting
    
    /// Format date with style
    @MainActor func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
    /// Format time with style
    @MainActor func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        timeFormatter.timeStyle = style
        return timeFormatter.string(from: date)
    }
    
    /// Format date and time
    @MainActor func formatDateTime(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        return dateFormatter.string(from: date)
    }
    
    /// Format relative date (e.g., "2 hours ago", "in 3 days")
    @MainActor func formatRelativeDate(_ date: Date) -> String {
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Format duration in minutes
    func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return String(format: LocalizationKeys.Common.minutes.localized, minutes)
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return String(format: LocalizationKeys.Common.hours.localized, hours)
            } else {
                let hoursString = String(format: LocalizationKeys.Common.hours.localized, hours)
                let minutesString = String(format: LocalizationKeys.Common.minutes.localized, remainingMinutes)
                return "\(hoursString) \(minutesString)"
            }
        }
    }
    
    // MARK: - Distance and Measurement Formatting
    
    /// Format distance in meters
    @MainActor func formatDistance(_ meters: Double) -> String {
        let locale = localizationManager.currentLocale
        let usesMetric = locale.usesMetricSystem
        
        if usesMetric {
            if meters < 1000 {
                return String(format: "%.0f m", meters)
            } else {
                let kilometers = meters / 1000
                return String(format: "%.1f km", kilometers)
            }
        } else {
            let feet = meters * 3.28084
            if feet < 5280 {
                return String(format: "%.0f ft", feet)
            } else {
                let miles = feet / 5280
                return String(format: "%.1f mi", miles)
            }
        }
    }
    
    /// Format weight
    @MainActor func formatWeight(_ grams: Double) -> String {
        let locale = localizationManager.currentLocale
        let usesMetric = locale.usesMetricSystem
        
        if usesMetric {
            if grams < 1000 {
                return String(format: "%.0f g", grams)
            } else {
                let kilograms = grams / 1000
                return String(format: "%.1f kg", kilograms)
            }
        } else {
            let ounces = grams * 0.035274
            if ounces < 16 {
                return String(format: "%.1f oz", ounces)
            } else {
                let pounds = ounces / 16
                return String(format: "%.1f lb", pounds)
            }
        }
    }
    
    /// Format temperature
    @MainActor func formatTemperature(_ celsius: Double) -> String {
        let locale = localizationManager.currentLocale
        let usesMetric = locale.usesMetricSystem
        
        if usesMetric {
            return String(format: "%.0f°C", celsius)
        } else {
            let fahrenheit = celsius * 9/5 + 32
            return String(format: "%.0f°F", fahrenheit)
        }
    }
    
    // MARK: - Address Formatting
    
    /// Format address based on locale conventions
    @MainActor func formatAddress(street: String?, city: String?, state: String?, postalCode: String?, country: String?) -> String {
        let locale = localizationManager.currentLocale
        let components = [street, city, state, postalCode, country].compactMap { $0 }
        
        // Different address formats for different regions
        switch locale.region?.identifier {
        case "US", "CA":
            // North American format: Street, City, State PostalCode
            return formatUSAddress(street: street, city: city, state: state, postalCode: postalCode)
        case "GB":
            // UK format: Street, City, PostalCode
            return formatUKAddress(street: street, city: city, postalCode: postalCode)
        case "DE", "FR", "IT", "ES":
            // European format: Street, PostalCode City
            return formatEuropeanAddress(street: street, city: city, postalCode: postalCode)
        case "JP":
            // Japanese format: PostalCode Prefecture City Street
            return formatJapaneseAddress(street: street, city: city, state: state, postalCode: postalCode)
        default:
            // Default format
            return components.joined(separator: ", ")
        }
    }
    
    // MARK: - Phone Number Formatting
    
    /// Format phone number based on locale
    @MainActor func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let locale = localizationManager.currentLocale
        
        switch locale.region?.identifier {
        case "US", "CA":
            return formatUSPhoneNumber(cleanNumber)
        case "GB":
            return formatUKPhoneNumber(cleanNumber)
        case "DE":
            return formatGermanPhoneNumber(cleanNumber)
        case "FR":
            return formatFrenchPhoneNumber(cleanNumber)
        case "JP":
            return formatJapanesePhoneNumber(cleanNumber)
        default:
            return phoneNumber
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateFormattersLocale()
            }
        }
    }
    
    @MainActor private func updateFormattersLocale() {
        let newLocale = localizationManager.currentLocale
        
        currencyFormatter.locale = newLocale
        decimalFormatter.locale = newLocale
        percentFormatter.locale = newLocale
        dateFormatter.locale = newLocale
        timeFormatter.locale = newLocale
        relativeDateFormatter.locale = newLocale
        measurementFormatter.locale = newLocale
    }
    
    private func formatFallbackCurrency(_ amount: Double, currencyCode: String) -> String {
        let symbol = currencySymbol(for: currencyCode)
        return String(format: "%@%.2f", symbol, amount)
    }
    
    private func currencySymbol(for code: String) -> String {
        switch code {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CNY": return "¥"
        case "KRW": return "₩"
        case "INR": return "₹"
        case "RUB": return "₽"
        case "BRL": return "R$"
        case "CAD": return "C$"
        case "AUD": return "A$"
        case "CHF": return "CHF"
        case "SEK": return "kr"
        case "NOK": return "kr"
        case "DKK": return "kr"
        case "PLN": return "zł"
        case "CZK": return "Kč"
        case "HUF": return "Ft"
        case "RON": return "lei"
        case "BGN": return "лв"
        case "HRK": return "kn"
        case "RSD": return "дин"
        case "BAM": return "KM"
        case "MKD": return "ден"
        case "ALL": return "L"
        case "TRY": return "₺"
        case "ILS": return "₪"
        case "AED": return "د.إ"
        case "SAR": return "ر.س"
        case "QAR": return "ر.ق"
        case "KWD": return "د.ك"
        case "BHD": return "د.ب"
        case "OMR": return "ر.ع"
        case "JOD": return "د.ا"
        case "LBP": return "ل.ل"
        case "EGP": return "ج.م"
        case "MAD": return "د.م"
        case "TND": return "د.ت"
        case "DZD": return "د.ج"
        case "LYD": return "د.ل"
        case "SDG": return "ج.س"
        case "SOS": return "S"
        case "ETB": return "Br"
        case "KES": return "KSh"
        case "UGX": return "USh"
        case "TZS": return "TSh"
        case "RWF": return "RF"
        case "BIF": return "FBu"
        case "DJF": return "Fdj"
        case "ERN": return "Nfk"
        case "MGA": return "Ar"
        case "MUR": return "Rs"
        case "SCR": return "Rs"
        case "KMF": return "CF"
        case "MZN": return "MT"
        case "AOA": return "Kz"
        case "ZMW": return "ZK"
        case "ZWL": return "Z$"
        case "BWP": return "P"
        case "SZL": return "L"
        case "LSL": return "L"
        case "NAD": return "N$"
        case "ZAR": return "R"
        case "GHS": return "₵"
        case "NGN": return "₦"
        case "XOF": return "CFA"
        case "XAF": return "FCFA"
        case "GMD": return "D"
        case "SLL": return "Le"
        case "LRD": return "L$"
        case "GNF": return "FG"
        case "CIV": return "CFA"
        case "BFA": return "CFA"
        case "MLI": return "CFA"
        case "NER": return "CFA"
        case "SEN": return "CFA"
        case "TGO": return "CFA"
        case "BEN": return "CFA"
        case "CMR": return "FCFA"
        case "CAF": return "FCFA"
        case "TCD": return "FCFA"
        case "COG": return "FCFA"
        case "GAB": return "FCFA"
        case "GNQ": return "FCFA"
        default: return code
        }
    }
    
    // Address formatting helpers
    private func formatUSAddress(street: String?, city: String?, state: String?, postalCode: String?) -> String {
        var components: [String] = []
        
        if let street = street { components.append(street) }
        
        var cityStateZip: [String] = []
        if let city = city { cityStateZip.append(city) }
        if let state = state { cityStateZip.append(state) }
        if let postalCode = postalCode { cityStateZip.append(postalCode) }
        
        if !cityStateZip.isEmpty {
            components.append(cityStateZip.joined(separator: " "))
        }
        
        return components.joined(separator: ", ")
    }
    
    private func formatUKAddress(street: String?, city: String?, postalCode: String?) -> String {
        let components = [street, city, postalCode].compactMap { $0 }
        return components.joined(separator: ", ")
    }
    
    private func formatEuropeanAddress(street: String?, city: String?, postalCode: String?) -> String {
        var components: [String] = []
        
        if let street = street { components.append(street) }
        
        if let postalCode = postalCode, let city = city {
            components.append("\(postalCode) \(city)")
        } else if let city = city {
            components.append(city)
        } else if let postalCode = postalCode {
            components.append(postalCode)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func formatJapaneseAddress(street: String?, city: String?, state: String?, postalCode: String?) -> String {
        var components: [String] = []
        
        if let postalCode = postalCode { components.append("〒\(postalCode)") }
        if let state = state { components.append(state) }
        if let city = city { components.append(city) }
        if let street = street { components.append(street) }
        
        return components.joined(separator: " ")
    }
    
    // Phone number formatting helpers
    private func formatUSPhoneNumber(_ number: String) -> String {
        guard number.count == 10 else { return number }
        let areaCode = String(number.prefix(3))
        let exchange = String(number.dropFirst(3).prefix(3))
        let subscriber = String(number.suffix(4))
        return "(\(areaCode)) \(exchange)-\(subscriber)"
    }
    
    private func formatUKPhoneNumber(_ number: String) -> String {
        guard number.count >= 10 else { return number }
        if number.hasPrefix("44") {
            let domestic = String(number.dropFirst(2))
            return "+44 \(formatUKDomesticNumber(domestic))"
        }
        return formatUKDomesticNumber(number)
    }
    
    private func formatUKDomesticNumber(_ number: String) -> String {
        guard number.count >= 10 else { return number }
        let areaCode = String(number.prefix(4))
        let subscriber = String(number.dropFirst(4))
        return "\(areaCode) \(subscriber)"
    }
    
    private func formatGermanPhoneNumber(_ number: String) -> String {
        guard number.count >= 10 else { return number }
        if number.hasPrefix("49") {
            return "+49 \(String(number.dropFirst(2)))"
        }
        return number
    }
    
    private func formatFrenchPhoneNumber(_ number: String) -> String {
        guard number.count == 10 else { return number }
        let groups = stride(from: 0, to: number.count, by: 2).map {
            String(number[number.index(number.startIndex, offsetBy: $0)..<number.index(number.startIndex, offsetBy: min($0 + 2, number.count))])
        }
        return groups.joined(separator: " ")
    }
    
    private func formatJapanesePhoneNumber(_ number: String) -> String {
        guard number.count >= 10 else { return number }
        if number.hasPrefix("81") {
            return "+81 \(String(number.dropFirst(2)))"
        }
        return number
    }
}

// MARK: - Locale Extensions

extension Locale {
    var usesMetricSystem: Bool {
        return (self as NSLocale).object(forKey: .usesMetricSystem) as? Bool ?? true
    }
}