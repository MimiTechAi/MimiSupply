//
//  RetryBannerView.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Combine
import OSLog

/// Banner view for displaying retry options when operations fail
struct RetryBannerView: View {
    @StateObject private var retryBannerManager = RetryBannerManager.shared
    @State private var showingRetrySheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(retryBannerManager.activeBanners) { banner in
                RetryBannerCard(
                    banner: banner,
                    onRetry: {
                        Task {
                            await retryBannerManager.retryOperation(banner.id)
                        }
                    },
                    onDismiss: {
                        retryBannerManager.dismissBanner(banner.id)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: retryBannerManager.activeBanners.count)
    }
}

/// Individual retry banner card
struct RetryBannerCard: View {
    let banner: RetryBanner
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    @State private var isRetrying = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            bannerIcon
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(banner.title)
                    .font(.body.scaledFont().weight(.medium))
                    .foregroundColor(banner.severity.textColor)
                
                if let message = banner.message {
                    Text(message)
                        .font(.caption.scaledFont())
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Actions
            bannerActions
        }
        .padding(Spacing.md)
        .background(bannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }
    
    private var bannerIcon: some View {
        Image(systemName: banner.severity.iconName)
            .font(.title3)
            .foregroundColor(banner.severity.iconColor)
            .frame(width: 24, height: 24)
    }
    
    private var bannerActions: some View {
        HStack(spacing: Spacing.xs) {
            if banner.isRetryable && !isRetrying {
                Button {
                    isRetrying = true
                    onRetry()
                    HapticManager.shared.trigger(.medium)
                    
                    // Reset retrying state after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isRetrying = false
                    }
                } label: {
                    if isRetrying {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: banner.severity.buttonColor))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                }
                .foregroundColor(banner.severity.buttonColor)
                .frame(width: 32, height: 32)
                .background(banner.severity.buttonColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(isRetrying)
            }
            
            Button {
                onDismiss()
                HapticManager.shared.trigger(.light)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.secondary)
            .frame(width: 32, height: 32)
            .background(Color.surfaceSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var bannerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(banner.severity.backgroundColor)
            .strokeBorder(banner.severity.borderColor, lineWidth: 1)
    }
}

/// Manager for retry banners
@MainActor
final class RetryBannerManager: ObservableObject {
    static let shared = RetryBannerManager()
    
    @Published var activeBanners: [RetryBanner] = []
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "RetryBannerManager")
    private var bannerTimers: [UUID: Timer] = [:]
    
    private init() {}
    
    /// Show retry banner for failed operation
    func showRetryBanner(
        id: UUID = UUID(),
        title: String,
        message: String? = nil,
        severity: RetryBannerSeverity = .error,
        operation: @escaping () async throws -> Void,
        autoRetryDelay: TimeInterval? = nil,
        autoDismissDelay: TimeInterval? = 10.0
    ) {
        let banner = RetryBanner(
            id: id,
            title: title,
            message: message,
            severity: severity,
            operation: operation,
            isRetryable: true
        )
        
        // Remove existing banner with same ID
        dismissBanner(id)
        
        // Add new banner
        activeBanners.append(banner)
        logger.info("📢 Showing retry banner: \(title)")
        
        // Setup auto-retry if specified
        if let autoRetryDelay = autoRetryDelay {
            bannerTimers[id] = Timer.scheduledTimer(withTimeInterval: autoRetryDelay, repeats: false) { _ in
                Task { @MainActor in
                    await self.retryOperation(id)
                }
            }
        }
        
        // Setup auto-dismiss if specified
        if let autoDismissDelay = autoDismissDelay {
            bannerTimers[id] = Timer.scheduledTimer(withTimeInterval: autoDismissDelay, repeats: false) { _ in
                Task { @MainActor in
                    self.dismissBanner(id)
                }
            }
        }
    }
    
    /// Show info banner (non-retryable)
    func showInfoBanner(
        title: String,
        message: String? = nil,
        severity: RetryBannerSeverity = .info,
        autoDismissDelay: TimeInterval = 5.0
    ) {
        let banner = RetryBanner(
            id: UUID(),
            title: title,
            message: message,
            severity: severity,
            operation: { },
            isRetryable: false
        )
        
        activeBanners.append(banner)
        logger.info("📢 Showing info banner: \(title)")
        
        // Auto-dismiss
        bannerTimers[banner.id] = Timer.scheduledTimer(withTimeInterval: autoDismissDelay, repeats: false) { _ in
            Task { @MainActor in
                self.dismissBanner(banner.id)
            }
        }
    }
    
    /// Retry operation for banner
    func retryOperation(_ bannerId: UUID) async {
        guard let banner = activeBanners.first(where: { $0.id == bannerId }) else { return }
        
        logger.info("🔄 Retrying operation for banner: \(banner.title)")
        
        do {
            try await banner.operation()
            dismissBanner(bannerId)
            
            // Show success feedback
            showInfoBanner(
                title: "Operation Successful",
                message: "The failed operation has been completed.",
                severity: .success,
                autoDismissDelay: 3.0
            )
        } catch {
            logger.warning("❌ Retry failed for banner: \(banner.title) - \(error.localizedDescription)")
            
            // Update banner to show retry failed
            if let index = activeBanners.firstIndex(where: { $0.id == bannerId }) {
                var updatedBanner = activeBanners[index]
                updatedBanner.retryCount += 1
                updatedBanner.message = "Retry failed: \(error.localizedDescription)"
                activeBanners[index] = updatedBanner
            }
        }
    }
    
    /// Dismiss banner
    func dismissBanner(_ bannerId: UUID) {
        activeBanners.removeAll { $0.id == bannerId }
        bannerTimers[bannerId]?.invalidate()
        bannerTimers.removeValue(forKey: bannerId)
        
        logger.debug("🗑️ Dismissed banner: \(bannerId)")
    }
    
    /// Dismiss all banners
    func dismissAllBanners() {
        activeBanners.removeAll()
        bannerTimers.values.forEach { $0.invalidate() }
        bannerTimers.removeAll()
        
        logger.info("🗑️ Dismissed all banners")
    }
}

/// Retry banner model
struct RetryBanner: Identifiable, Equatable {
    let id: UUID
    let title: String
    var message: String?
    let severity: RetryBannerSeverity
    let operation: () async throws -> Void
    let isRetryable: Bool
    var retryCount: Int = 0
    let createdAt = Date()
    
    static func == (lhs: RetryBanner, rhs: RetryBanner) -> Bool {
        lhs.id == rhs.id
    }
}

/// Banner severity levels
enum RetryBannerSeverity: CaseIterable {
    case info
    case warning
    case error
    case success
    
    var iconName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .warning
        case .error:
            return .error
        case .success:
            return .success
        }
    }
    
    var textColor: Color {
        switch self {
        case .info:
            return .primary
        case .warning:
            return .primary
        case .error:
            return .primary
        case .success:
            return .primary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .info:
            return Color.blue.opacity(0.1)
        case .warning:
            return Color.warning.opacity(0.1)
        case .error:
            return Color.error.opacity(0.1)
        case .success:
            return Color.success.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .info:
            return Color.blue.opacity(0.3)
        case .warning:
            return Color.warning.opacity(0.3)
        case .error:
            return Color.error.opacity(0.3)
        case .success:
            return Color.success.opacity(0.3)
        }
    }
    
    var buttonColor: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .warning
        case .error:
            return .error
        case .success:
            return .success
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        RetryBannerView()
        
        Spacer()
        
        VStack(spacing: Spacing.sm) {
            Button("Show Error Banner") {
                RetryBannerManager.shared.showRetryBanner(
                    title: "Sync Failed",
                    message: "Unable to sync your data. Check your connection and try again.",
                    severity: .error,
                    operation: {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        // Simulate success
                    }
                )
            }
            .buttonStyle(.primary)
            
            Button("Show Warning Banner") {
                RetryBannerManager.shared.showRetryBanner(
                    title: "Partial Sync",
                    message: "Some items couldn't be synchronized.",
                    severity: .warning,
                    operation: {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                )
            }
            .buttonStyle(.secondary)
            
            Button("Show Success Banner") {
                RetryBannerManager.shared.showInfoBanner(
                    title: "Sync Complete",
                    message: "All your data has been synchronized.",
                    severity: .success
                )
            }
            .buttonStyle(.tertiary)
        }
        .padding()
    }
}