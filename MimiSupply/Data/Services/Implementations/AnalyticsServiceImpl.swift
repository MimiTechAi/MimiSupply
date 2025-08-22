import Foundation
import os.log
import os.signpost
import CloudKit
import CommonCrypto
// Assuming AnalyticsParameterValue and AnalyticsParameters are defined in the shared AnalyticsService module or imported implicitly

// MARK: - Analytics Service Implementation
/// `AnalyticsServiceImpl` does not conform to `Sendable` because it contains multiple mutable properties
/// such as `eventBuffer`, `isFlushingEvents`, and `flushTimer` which are accessed in a non-concurrent-safe manner.
/// The class uses `UserDefaults` and timers which are not `Sendable` and concurrency is managed by restricting
/// access to these mutable properties on the main actor or specific queues. This avoids data races without requiring `Sendable`.
final class AnalyticsServiceImpl: AnalyticsService, ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Analytics")
    private let performanceLog = OSLog(subsystem: "com.mimisupply.app", category: "Performance")
    private let eventQueue = DispatchQueue(label: "com.mimisupply.analytics", qos: .utility)
    @MainActor private let userDefaults = UserDefaults.standard
    
    /// Access to `eventBuffer` is confined to the main actor to prevent data races.
    @MainActor private var eventBuffer: [AnalyticsEventData] = []
    @MainActor private var isFlushingEvents = false
    private let maxBufferSize = 100
    private let flushInterval: TimeInterval = 30.0
    
    /// `flushTimer` is only used on the main actor.
    @MainActor private var flushTimer: Timer?
    /// Not Sendable, confined to main actor
    @MainActor private var sessionStartTime: Date?
    
    /// Confined to main actor to avoid concurrency issues
    @MainActor private var currentSessionID: String?
    
    // Privacy settings
    @MainActor private var analyticsEnabled: Bool {
        get async {
            userDefaults.bool(forKey: "analytics_enabled")
        }
    }
    
    @MainActor private var crashReportingEnabled: Bool {
        get async {
            userDefaults.bool(forKey: "crash_reporting_enabled")
        }
    }
    
    // MARK: - Initialization
    init() {
        Task { [weak self] in
            await self?.setupAnalytics()
            await self?.startSession()
            await self?.schedulePeriodicFlush()
        }
    }
    
    deinit {
        Task { [weak self] in
            await self?.endSession()
        }
        Task { @MainActor [weak self] in
            self?.flushTimer?.invalidate()
        }
    }
    
    // MARK: - Public Methods

    func trackEvent(_ event: AnalyticsEvent, parameters: AnalyticsParameters? = nil) async {
        guard await analyticsEnabled else { return }
        
        let sanitizedParameters = sanitizeParameters(parameters)
        
        let userId = await getCurrentUserID()
        let sessionId = await MainActor.run { currentSessionID }
        
        let eventData = AnalyticsEventData(
            event: event,
            parameters: sanitizedParameters,
            sessionID: sessionId,
            userID: userId
        )
        
        await addEventToBuffer(eventData)
        logger.info("Event tracked: \(event.name)")
    }
    
    func trackScreenView(_ screenName: String, parameters: AnalyticsParameters? = nil) async {
        var params = parameters ?? [:]
        // Wrap screenName as AnalyticsParameterValue
        params["screen_name"] = .string(screenName)
        // Add timestamp as ISO8601 string wrapped in AnalyticsParameterValue
        params["timestamp"] = .string(ISO8601DateFormatter().string(from: Date()))
        
        await trackEvent(.screenView, parameters: params)
        
        // Track engagement
        let engagement = UserEngagement(
            type: .screenView,
            metadata: ["screen_name": screenName]
        )
        await trackEngagement(engagement)
    }
    
    func setUserProperty(_ property: String, value: String?) async {
        guard await analyticsEnabled else { return }
        guard isPropertyAllowed(property) else {
            logger.warning("User property '\(property)' not allowed - may contain PII")
            return
        }
        
        await MainActor.run { @MainActor in
            userDefaults.set(value, forKey: "user_property_\(property)")
        }
        logger.info("User property set: \(property)")
    }
    
    func trackPerformanceMetric(_ metric: PerformanceMetric) async {
        guard await analyticsEnabled else { return }
        
        // Map metric properties to AnalyticsParameters
        var params: AnalyticsParameters = [
            "metric_name": .string(metric.name),
            "value": .double(metric.value),
            "unit": .string(metric.unit)
        ]
        if let metadata = metric.metadata {
            // Wrap metadata dictionary values to AnalyticsParameterValue as strings (lossy fallback)
            var metadataParams: AnalyticsParameters = [:]
            for (key, value) in metadata {
                metadataParams[key] = .string(String(describing: value)) // lossy fallback for unknown types
            }
            if !metadataParams.isEmpty {
                for (metaKey, metaValue) in metadataParams {
                    params["metadata_\(metaKey)"] = metaValue
                }
            }
        }
        
        let sessionId = await MainActor.run { currentSessionID }
        let userId = await getCurrentUserID()
        
        let eventData = AnalyticsEventData(
            event: AnalyticsEvent(name: "performance_metric", category: .performance),
            parameters: sanitizeParameters(params),
            sessionID: sessionId,
            userID: userId
        )
        
        await addEventToBuffer(eventData)
        
        // Log to unified logging for debugging
        os_signpost(.event, log: performanceLog, name: "Performance Metric",
                   "%{public}s: %{public}f %{public}s",
                   metric.name, metric.value, metric.unit)
        
        logger.info("Performance metric tracked: \(metric.name) = \(metric.value) \(metric.unit)")
    }
    
    func trackError(_ error: Error, context: AnalyticsParameters? = nil) async {
        guard await crashReportingEnabled else { return }
        
        let errorInfo = extractErrorInfo(error)
        var params = context ?? [:]
        // Map errorInfo dictionary [String: Any] to AnalyticsParameters by wrapping values as .string(String(describing: value))
        let errorInfoParams: AnalyticsParameters = errorInfo.reduce(into: AnalyticsParameters()) { partialResult, pair in
            partialResult[pair.key] = .string(String(describing: pair.value))
        }
        for (k, v) in errorInfoParams {
            params[k] = v
        }
        
        await trackEvent(.errorOccurred, parameters: params)
        
        logger.error("Error tracked: \(error.localizedDescription)")
    }
    
    nonisolated func startPerformanceMeasurement(_ name: String) -> PerformanceMeasurement {
        return PerformanceMeasurement(name: name)
    }
    
    func trackFeatureFlag(_ flag: String, variant: String) async {
        let parameters: AnalyticsParameters = [
            "flag_name": .string(flag),
            "variant": .string(variant),
            "timestamp": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        await trackEvent(.featureFlagEvaluated, parameters: parameters)
        logger.info("Feature flag tracked: \(flag) = \(variant)")
    }
    
    func trackEngagement(_ engagement: UserEngagement) async {
        guard await analyticsEnabled else { return }
        
        var parameters: AnalyticsParameters = [
            "engagement_type": .string(engagement.type.rawValue),
            "timestamp": .string(ISO8601DateFormatter().string(from: engagement.timestamp))
        ]
        
        if let duration = engagement.duration {
            parameters["duration"] = .double(duration)
        }
        
        if let value = engagement.value {
            parameters["value"] = .string(String(describing: value)) // lossy fallback for unknown types
        }
        
        if let metadata = engagement.metadata {
            // Wrap metadata dictionary values to AnalyticsParameterValue as strings (lossy fallback)
            var metadataParams: AnalyticsParameters = [:]
            for (key, value) in metadata {
                metadataParams[key] = .string(String(describing: value)) // lossy fallback
            }
            if !metadataParams.isEmpty {
                for (metaKey, metaValue) in metadataParams {
                    parameters["metadata_\(metaKey)"] = metaValue
                }
            }
        }
        
        let event = AnalyticsEvent(name: "user_engagement", category: .engagement)
        await trackEvent(event, parameters: parameters)
    }
    
    func flush() async {
        await flushEvents()
    }
    
    // MARK: - Private Methods
    private func setupAnalytics() async {
        await MainActor.run { @MainActor in
            // Set default values if not already set
            if userDefaults.object(forKey: "analytics_enabled") == nil {
                userDefaults.set(true, forKey: "analytics_enabled")
            }
            
            if userDefaults.object(forKey: "crash_reporting_enabled") == nil {
                userDefaults.set(true, forKey: "crash_reporting_enabled")
            }
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
        // Log crash without capturing context or referencing self
        print("Uncaught exception: \(exception)")
    }
    
    private static let signalHandler: @convention(c) (Int32) -> Void = { signal in
        // Log signal without capturing context or referencing self
        print("Signal received: \(signal)")
    }
    
    private func handleCrash(exception: NSException) async {
        let crashData: AnalyticsParameters = [
            "crash_type": .string("exception"),
            "name": .string(exception.name.rawValue),
            "reason": .string(exception.reason ?? "Unknown"),
            "stack_trace": .string(exception.callStackSymbols.joined(separator: "\n"))
        ]
        
        await trackEvent(.crashReported, parameters: crashData)
        await flushEvents() // Immediate flush for crashes
    }
    
    private func handleCrash(signal: String) async {
        let crashData: AnalyticsParameters = [
            "crash_type": .string("signal"),
            "signal": .string(signal),
            "timestamp": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        await trackEvent(.crashReported, parameters: crashData)
        await flushEvents() // Immediate flush for crashes
    }
    
    private func startSession() async {
        await MainActor.run { @MainActor in
            sessionStartTime = Date()
            currentSessionID = UUID().uuidString
        }
        
        let engagement = UserEngagement(type: .sessionStart)
        await trackEngagement(engagement)
    }
    
    private func endSession() async {
        let startTime: Date? = await MainActor.run { sessionStartTime }
        guard let startTimeUnwrapped = startTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTimeUnwrapped)
        
        let engagement = UserEngagement(
            type: .sessionEnd,
            duration: sessionDuration
        )
        await trackEngagement(engagement)
        await flushEvents()
    }
    
    private func schedulePeriodicFlush() async {
        await MainActor.run { @MainActor [weak self] in
            guard let self = self else { return }
            self.flushTimer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.flushEvents()
                }
            }
        }
    }
    
    @MainActor
    private func addEventToBuffer(_ eventData: AnalyticsEventData) async {
        eventBuffer.append(eventData)
        
        if eventBuffer.count >= maxBufferSize {
            await flushEvents()
        }
    }
    
    @MainActor
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
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        // Keep only the 10 most recent files
        for file in sortedFiles.dropFirst(10) {
            try FileManager.default.removeItem(at: file)
        }
    }
    
    private func sanitizeParameters(_ parameters: AnalyticsParameters?) -> AnalyticsParameters? {
        guard let params = parameters else { return nil }
        
        var sanitized: AnalyticsParameters = [:]
        
        for (key, value) in params {
            // Remove potentially sensitive data
            if isPotentiallyPII(key: key, value: value) {
                continue
            }
            
            sanitized[key] = value
        }
        
        return sanitized.isEmpty ? nil : sanitized
    }
    
    private func isPotentiallyPII(key: String, value: AnalyticsParameterValue) -> Bool {
        let piiKeys = ["email", "phone", "address", "name", "password", "token", "id"]
        let lowercaseKey = key.lowercased()
        
        return piiKeys.contains { lowercaseKey.contains($0) }
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
    let parameters: AnalyticsParameters?
    let sessionID: String?
    let userID: String?
    let timestamp: Date
    
    init(event: AnalyticsEvent, parameters: AnalyticsParameters?, sessionID: String?, userID: String?) {
        self.event = event
        self.parameters = parameters
        self.sessionID = sessionID
        self.userID = userID
        self.timestamp = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case event, parameters, sessionID, userID, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(sessionID, forKey: .sessionID)
        try container.encodeIfPresent(userID, forKey: .userID)
        try container.encode(timestamp, forKey: .timestamp)
        
        try container.encodeIfPresent(parameters, forKey: .parameters)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(AnalyticsEvent.self, forKey: .event)
        sessionID = try container.decodeIfPresent(String.self, forKey: .sessionID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        parameters = try container.decodeIfPresent(AnalyticsParameters.self, forKey: .parameters)
    }
}

// MARK: - String Extension for Hashing
private extension String {
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

