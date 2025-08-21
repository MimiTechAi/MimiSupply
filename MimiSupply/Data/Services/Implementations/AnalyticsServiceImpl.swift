import Foundation
import os.log
import os.signpost
import CloudKit

// MARK: - Analytics Service Implementation
@MainActor
final class AnalyticsServiceImpl: AnalyticsService, ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Analytics")
    private let performanceLog = OSLog(subsystem: "com.mimisupply.app", category: "Performance")
    private let eventQueue = DispatchQueue(label: "com.mimisupply.analytics", qos: .utility)
    private let userDefaults = UserDefaults.standard
    
    private var eventBuffer: [AnalyticsEventData] = []
    private var isFlushingEvents = false
    private let maxBufferSize = 100
    private let flushInterval: TimeInterval = 30.0
    
    private var flushTimer: Timer?
    private var sessionStartTime: Date?
    private var currentSessionID: String?
    
    // Privacy settings
    private var analyticsEnabled: Bool {
        userDefaults.bool(forKey: "analytics_enabled")
    }
    
    private var crashReportingEnabled: Bool {
        userDefaults.bool(forKey: "crash_reporting_enabled")
    }
    
    // MARK: - Initialization
    init() {
        setupAnalytics()
        startSession()
        schedulePeriodicFlush()
    }
    
    deinit {
        Task { @MainActor in
            endSession()
        }
        flushTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) async {
        guard analyticsEnabled else { return }
        
        let eventData = AnalyticsEventData(
            event: event,
            parameters: sanitizeParameters(parameters),
            sessionID: currentSessionID,
            userID: await getCurrentUserID()
        )
        
        await addEventToBuffer(eventData)
        logger.info("Event tracked: \(event.name)")
    }
    
    func trackScreenView(_ screenName: String, parameters: [String: Any]?) async {
        var params = parameters ?? [:]
        params["screen_name"] = screenName
        params["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        await trackEvent(.screenView, parameters: params)
        
        // Track engagement
        let engagement = UserEngagement(
            type: .screenView,
            metadata: ["screen_name": screenName]
        )
        await trackEngagement(engagement)
    }
    
    func setUserProperty(_ property: String, value: String?) async {
        guard analyticsEnabled else { return }
        guard isPropertyAllowed(property) else {
            logger.warning("User property '\(property)' not allowed - may contain PII")
            return
        }
        
        userDefaults.set(value, forKey: "user_property_\(property)")
        logger.info("User property set: \(property)")
    }
    
    func trackPerformanceMetric(_ metric: PerformanceMetric) async {
        guard analyticsEnabled else { return }
        
        let eventData = AnalyticsEventData(
            event: AnalyticsEvent(name: "performance_metric", category: .performance),
            parameters: [
                "metric_name": metric.name,
                "value": metric.value,
                "unit": metric.unit,
                "metadata": metric.metadata ?? [:]
            ],
            sessionID: currentSessionID,
            userID: await getCurrentUserID()
        )
        
        await addEventToBuffer(eventData)
        
        // Log to unified logging for debugging
        os_signpost(.event, log: performanceLog, name: "Performance Metric", 
                   "%{public}s: %{public}f %{public}s", 
                   metric.name, metric.value, metric.unit)
        
        logger.info("Performance metric tracked: \(metric.name) = \(metric.value) \(metric.unit)")
    }
    
    func trackError(_ error: Error, context: [String: Any]?) async {
        guard crashReportingEnabled else { return }
        
        let errorInfo = extractErrorInfo(error)
        var params = context ?? [:]
        params.merge(errorInfo) { _, new in new }
        
        await trackEvent(.errorOccurred, parameters: params)
        
        logger.error("Error tracked: \(error.localizedDescription)")
    }
    
    nonisolated func startPerformanceMeasurement(_ name: String) -> PerformanceMeasurement {
        return PerformanceMeasurement(name: name)
    }
    
    func trackFeatureFlag(_ flag: String, variant: String) async {
        let parameters = [
            "flag_name": flag,
            "variant": variant,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        await trackEvent(.featureFlagEvaluated, parameters: parameters)
        logger.info("Feature flag tracked: \(flag) = \(variant)")
    }
    
    func trackEngagement(_ engagement: UserEngagement) async {
        guard analyticsEnabled else { return }
        
        var parameters: [String: Any] = [
            "engagement_type": engagement.type.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: engagement.timestamp)
        ]
        
        if let duration = engagement.duration {
            parameters["duration"] = duration
        }
        
        if let value = engagement.value {
            parameters["value"] = value
        }
        
        if let metadata = engagement.metadata {
            parameters["metadata"] = metadata
        }
        
        let event = AnalyticsEvent(name: "user_engagement", category: .engagement)
        await trackEvent(event, parameters: parameters)
    }
    
    func flush() async {
        await flushEvents()
    }
    
    // MARK: - Private Methods
    private func setupAnalytics() {
        // Set default values if not already set
        if userDefaults.object(forKey: "analytics_enabled") == nil {
            userDefaults.set(true, forKey: "analytics_enabled")
        }
        
        if userDefaults.object(forKey: "crash_reporting_enabled") == nil {
            userDefaults.set(true, forKey: "crash_reporting_enabled")
        }
        
        // Setup crash handler
        setupCrashHandler()
    }
    
    private func setupCrashHandler() {
        NSSetUncaughtExceptionHandler(AnalyticsServiceImpl.uncaughtExceptionHandler)
        
        signal(SIGABRT, AnalyticsServiceImpl.signalHandler)
        signal(SIGILL, AnalyticsServiceImpl.signalHandler)
        signal(SIGSEGV, AnalyticsServiceImpl.signalHandler)
        signal(SIGFPE, AnalyticsServiceImpl.signalHandler)
        signal(SIGBUS, AnalyticsServiceImpl.signalHandler)
    }
    
    private static let uncaughtExceptionHandler: @convention(c) (NSException) -> Void = { exception in
        // Log crash without capturing context
        print("Uncaught exception: \(exception)")
    }
    
    private static let signalHandler: @convention(c) (Int32) -> Void = { signal in
        // Log signal without capturing context
        print("Signal received: \(signal)")
    }
    
    private func handleCrash(exception: NSException) async {
        let crashData = [
            "crash_type": "exception",
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown",
            "stack_trace": exception.callStackSymbols.joined(separator: "\n")
        ]
        
        await trackEvent(.crashReported, parameters: crashData)
        await flushEvents() // Immediate flush for crashes
    }
    
    private func handleCrash(signal: String) async {
        let crashData = [
            "crash_type": "signal",
            "signal": signal,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        await trackEvent(.crashReported, parameters: crashData)
        await flushEvents() // Immediate flush for crashes
    }
    
    private func startSession() {
        sessionStartTime = Date()
        currentSessionID = UUID().uuidString
        
        Task {
            let engagement = UserEngagement(type: .sessionStart)
            await trackEngagement(engagement)
        }
    }
    
    private func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        
        Task {
            let engagement = UserEngagement(
                type: .sessionEnd,
                duration: sessionDuration
            )
            await trackEngagement(engagement)
            await flushEvents()
        }
    }
    
    private func schedulePeriodicFlush() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.flushEvents()
            }
        }
    }
    
    private func addEventToBuffer(_ eventData: AnalyticsEventData) async {
        eventBuffer.append(eventData)
        
        if eventBuffer.count >= maxBufferSize {
            await flushEvents()
        }
    }
    
    private func flushEvents() async {
        guard !isFlushingEvents && !eventBuffer.isEmpty else { return }
        
        isFlushingEvents = true
        let eventsToFlush = eventBuffer
        eventBuffer.removeAll()
        
        do {
            // In a real implementation, you would send these to your analytics backend
            // For now, we'll log them and store locally for debugging
            try await persistEvents(eventsToFlush)
            logger.info("Flushed \(eventsToFlush.count) analytics events")
        } catch {
            // Re-add events to buffer if flush failed
            eventBuffer.insert(contentsOf: eventsToFlush, at: 0)
            logger.error("Failed to flush events: \(error.localizedDescription)")
        }
        
        isFlushingEvents = false
    }
    
    private func persistEvents(_ events: [AnalyticsEventData]) async throws {
        // Store events locally for debugging and offline support
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let analyticsPath = documentsPath.appendingPathComponent("analytics")
        
        try FileManager.default.createDirectory(at: analyticsPath, withIntermediateDirectories: true)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "events_\(timestamp).json"
        let filePath = analyticsPath.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(events)
        try data.write(to: filePath)
        
        // Clean up old files (keep only last 10 files)
        try cleanupOldAnalyticsFiles(in: analyticsPath)
    }
    
    private func cleanupOldAnalyticsFiles(in directory: URL) throws {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
        
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1! > date2!
        }
        
        // Keep only the 10 most recent files
        for file in sortedFiles.dropFirst(10) {
            try FileManager.default.removeItem(at: file)
        }
    }
    
    private func sanitizeParameters(_ parameters: [String: Any]?) -> [String: Any]? {
        guard let params = parameters else { return nil }
        
        var sanitized: [String: Any] = [:]
        
        for (key, value) in params {
            // Remove potentially sensitive data
            if isPotentiallyPII(key: key, value: value) {
                continue
            }
            
            // Ensure values are JSON serializable
            if let jsonValue = makeJSONSerializable(value) {
                sanitized[key] = jsonValue
            }
        }
        
        return sanitized.isEmpty ? nil : sanitized
    }
    
    private func isPotentiallyPII(key: String, value: Any) -> Bool {
        let piiKeys = ["email", "phone", "address", "name", "password", "token", "id"]
        let lowercaseKey = key.lowercased()
        
        return piiKeys.contains { lowercaseKey.contains($0) }
    }
    
    private func makeJSONSerializable(_ value: Any) -> Any? {
        switch value {
        case is String, is Int, is Double, is Bool:
            return value
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let array as [Any]:
            return array.compactMap { makeJSONSerializable($0) }
        case let dict as [String: Any]:
            var result: [String: Any] = [:]
            for (k, v) in dict {
                if let serializable = makeJSONSerializable(v) {
                    result[k] = serializable
                }
            }
            return result
        default:
            return String(describing: value)
        }
    }
    
    private func isPropertyAllowed(_ property: String) -> Bool {
        let allowedProperties = [
            "user_role", "app_version", "device_model", "os_version",
            "language", "region", "timezone", "theme_preference"
        ]
        
        return allowedProperties.contains(property)
    }
    
    private func extractErrorInfo(_ error: Error) -> [String: Any] {
        var info: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code
        ]
        
        if let appError = error as? AppError {
            info["app_error_type"] = String(describing: appError)
        }
        
        return info
    }
    
    private func getCurrentUserID() async -> String? {
        // Return a hashed or anonymized user ID, never the actual user ID
        do {
            guard let userID = try await AuthenticationServiceImpl.shared.getCurrentUserId() else {
                return nil
            }
            
            // Create a hash of the user ID for privacy
            return userID.sha256Hash
        } catch {
            logger.warning("Failed to get current user ID: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Analytics Event Data
private struct AnalyticsEventData: Codable {
    let event: AnalyticsEvent
    let parameters: [String: Any]?
    let sessionID: String?
    let userID: String?
    let timestamp: Date
    
    init(event: AnalyticsEvent, parameters: [String: Any]?, sessionID: String?, userID: String?) {
        self.event = event
        self.parameters = parameters
        self.sessionID = sessionID
        self.userID = userID
        self.timestamp = Date()
    }
    
    // Custom coding to handle Any values
    enum CodingKeys: String, CodingKey {
        case event, parameters, sessionID, userID, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(sessionID, forKey: .sessionID)
        try container.encodeIfPresent(userID, forKey: .userID)
        try container.encode(timestamp, forKey: .timestamp)
        
        if let params = parameters {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            let jsonString = String(data: jsonData, encoding: .utf8)
            try container.encodeIfPresent(jsonString, forKey: .parameters)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(AnalyticsEvent.self, forKey: .event)
        sessionID = try container.decodeIfPresent(String.self, forKey: .sessionID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        if let jsonString = try container.decodeIfPresent(String.self, forKey: .parameters),
           let jsonData = jsonString.data(using: .utf8) {
            parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        } else {
            parameters = nil
        }
    }
}

// MARK: - String Extension for Hashing
private extension String {
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Import CommonCrypto for hashing
import CommonCrypto