//
//  ErrorStateView.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

/// Error state view component with recovery actions
struct ErrorStateView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init(
        error: AppError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
            // Error icon
            Image(systemName: errorIcon)
                .font(.system(size: iconSize))
                .foregroundColor(errorColor)
                .accessibilityHidden(true)
            
            // Error content
            VStack(spacing: Spacing.sm * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
                Text(errorTitle)
                    .font(.titleLarge.scaledFont())
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                    .accessibleHeading(errorTitle, level: .h2)
                
                Text(errorMessage)
                    .font(.bodyMedium.scaledFont())
                    .foregroundColor(messageColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .accessibilityLabel(errorMessage)
                
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(.bodySmall.scaledFont())
                        .foregroundColor(suggestionColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .accessibilityLabel("Suggestion: \(recoverySuggestion)")
                }
            }
            
            // Action buttons
            VStack(spacing: Spacing.md) {
                if let onRetry = onRetry, shouldShowRetryButton {
                    PrimaryButton(
                        title: retryButtonTitle,
                        action: onRetry,
                        isLoading: false,
                        isDisabled: !canRetry,
                        accessibilityHint: "Tap to retry the failed operation"
                    )
                    .frame(maxWidth: 200)
                }
                
                if let onDismiss = onDismiss {
                    SecondaryButton(
                        title: "Dismiss",
                        action: onDismiss,
                        accessibilityHint: "Tap to dismiss this error"
                    )
                    .frame(maxWidth: 200)
                }
            }
            
            // Network status indicator for network errors
            if case .network = error, !networkMonitor.isConnected {
                NetworkStatusIndicator()
            }
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isStaticText)
    }
    
    // MARK: - Computed Properties
    
    private var errorIcon: String {
        switch error {
        case .network:
            return "wifi.slash"
        case .authentication:
            return "person.crop.circle.badge.exclamationmark"
        case .payment:
            return "creditcard.trianglebadge.exclamationmark"
        case .location:
            return "location.slash"
        case .cloudKit:
            return "icloud.slash"
        case .validation:
            return "exclamationmark.triangle"
        case .dataNotFound:
            return "magnifyingglass"
        case .unknown:
            return "exclamationmark.circle"
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .network:
            return "Connection Problem"
        case .authentication:
            return "Authentication Error"
        case .payment:
            return "Payment Error"
        case .location:
            return "Location Error"
        case .cloudKit:
            return "Sync Error"
        case .validation:
            return "Invalid Input"
        case .dataNotFound:
            return "Not Found"
        case .unknown:
            return "Something Went Wrong"
        }
    }
    
    private var errorMessage: String {
        return error.localizedDescription
    }
    
    private var errorColor: Color {
        let baseColor = Color.error
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var titleColor: Color {
        let baseColor = Color.graphite
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var messageColor: Color {
        let baseColor = Color.gray600
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var suggestionColor: Color {
        let baseColor = Color.gray500
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var iconSize: CGFloat {
        let baseSize: CGFloat = 48
        return baseSize * accessibilityManager.preferredContentSizeCategory.scaleFactor
    }
    
    private var shouldShowRetryButton: Bool {
        switch error {
        case .network, .cloudKit, .authentication(.tokenExpired):
            return true
        default:
            return false
        }
    }
    
    private var canRetry: Bool {
        switch error {
        case .network:
            return networkMonitor.isConnected
        default:
            return true
        }
    }
    
    private var retryButtonTitle: String {
        switch error {
        case .network:
            return networkMonitor.isConnected ? "Retry" : "Waiting for Connection..."
        default:
            return "Try Again"
        }
    }
    
    private var accessibilityDescription: String {
        var description = "\(errorTitle). \(errorMessage)"
        
        if let recoverySuggestion = error.recoverySuggestion {
            description += ". \(recoverySuggestion)"
        }
        
        if shouldShowRetryButton {
            description += ". Retry button available."
        }
        
        return description
    }
}

/// Network status indicator for connection issues
struct NetworkStatusIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                .foregroundColor(networkMonitor.isConnected ? .success : .error)
                .font(.caption)
            
            Text(statusText)
                .font(.caption.scaledFont())
                .foregroundColor(networkMonitor.isConnected ? .success : .error)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(networkMonitor.isConnected ? Color.success.opacity(0.1) : Color.error.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statusText)
        .accessibilityAddTraits(.isStaticText)
    }
    
    private var statusText: String {
        if networkMonitor.isConnected {
            if let connectionType = networkMonitor.connectionType {
                return "Connected via \(connectionType.description)"
            } else {
                return "Connected"
            }
        } else {
            return "No internet connection"
        }
    }
}

/// Inline error message component
struct InlineErrorView: View {
    let message: String
    let icon: String?
    
    init(_ message: String, icon: String? = "exclamationmark.triangle") {
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.error)
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            
            Text(message)
                .font(.caption.scaledFont())
                .foregroundColor(.error)
                .lineLimit(nil)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        ErrorStateView(
            error: .network(.noConnection),
            onRetry: { print("Retry tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
        
        Divider()
        
        InlineErrorView("Please enter a valid email address")
    }
    .padding()
}