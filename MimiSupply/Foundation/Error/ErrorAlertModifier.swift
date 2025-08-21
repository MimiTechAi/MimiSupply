//
//  ErrorAlertModifier.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

/// View modifier for displaying error alerts
struct ErrorAlertModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var retryManager = RetryManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.isShowingError) {
                if let error = errorHandler.currentError {
                    errorAlertButtons(for: error)
                }
            } message: {
                if let error = errorHandler.currentError {
                    errorAlertMessage(for: error)
                }
            }
    }
    
    @ViewBuilder
    private func errorAlertButtons(for error: AppError) -> some View {
        // Retry button for retryable errors
        if isRetryable(error) {
            Button("Retry") {
                handleRetry(for: error)
            }
        }
        
        // Dismiss button
        Button("OK") {
            errorHandler.dismissError()
        }
        
        // Settings button for permission errors
        if needsSettingsAction(error) {
            Button("Settings") {
                openSettings()
            }
        }
    }
    
    @ViewBuilder
    private func errorAlertMessage(for error: AppError) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(error.localizedDescription)
            
            if let recoverySuggestion = error.recoverySuggestion {
                Text(recoverySuggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func isRetryable(_ error: AppError) -> Bool {
        switch error {
        case .network(.noConnection), .network(.timeout), .network(.connectionFailed):
            return true
        case .cloudKit:
            return true
        case .authentication(.tokenExpired):
            return true
        default:
            return false
        }
    }
    
    private func needsSettingsAction(_ error: AppError) -> Bool {
        switch error {
        case .location(.permissionDenied):
            return true
        case .cloudKit(let ckError):
            return ckError.code == .notAuthenticated || ckError.code == .permissionFailure
        default:
            return false
        }
    }
    
    private func handleRetry(for error: AppError) {
        errorHandler.dismissError()
        
        // Implement retry logic based on error type
        Task {
            switch error {
            case .network:
                // Wait for network and retry last failed operation
                // This would need to be implemented based on specific use case
                break
            case .authentication(.tokenExpired):
                // Attempt to refresh authentication
                // This would integrate with AuthenticationService
                break
            case .cloudKit:
                // Retry CloudKit operation
                // This would need context about what operation failed
                break
            default:
                break
            }
        }
    }
    
    private func openSettings() {
        errorHandler.dismissError()
        
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

/// View extension for easy error handling
extension View {
    /// Add global error handling to any view
    func handleErrors() -> some View {
        modifier(ErrorAlertModifier())
    }
}

/// Toast-style error notification
struct ErrorToast: View {
    let error: AppError
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(errorTitle)
                    .font(.labelMedium.scaledFont())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(error.localizedDescription)
                    .font(.caption.scaledFont())
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.error)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            isVisible = true
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if isVisible {
                    dismissToast()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to dismiss")
    }
    
    private var errorTitle: String {
        switch error {
        case .network:
            return "Connection Error"
        case .authentication:
            return "Authentication Error"
        case .payment:
            return "Payment Error"
        case .location:
            return "Location Error"
        case .cloudKit:
            return "Sync Error"
        case .validation:
            return "Validation Error"
        case .dataNotFound:
            return "Not Found"
        case .unknown:
            return "Error"
        }
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

/// Toast container for managing multiple error toasts
@MainActor
final class ErrorToastManager: ObservableObject {
    static let shared = ErrorToastManager()
    
    @Published var toasts: [ErrorToastItem] = []
    
    private init() {}
    
    func showToast(for error: AppError) {
        let toast = ErrorToastItem(error: error)
        toasts.append(toast)
        
        // Auto-remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.removeToast(toast)
        }
    }
    
    func removeToast(_ toast: ErrorToastItem) {
        toasts.removeAll { $0.id == toast.id }
    }
}

struct ErrorToastItem: Identifiable {
    let id = UUID()
    let error: AppError
    let timestamp = Date()
}

/// View modifier for toast-style error notifications
struct ErrorToastModifier: ViewModifier {
    @StateObject private var toastManager = ErrorToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                VStack(spacing: Spacing.sm) {
                    ForEach(toastManager.toasts) { toast in
                        ErrorToast(error: toast.error) {
                            toastManager.removeToast(toast)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
    }
}

extension View {
    /// Add toast-style error notifications
    func errorToasts() -> some View {
        modifier(ErrorToastModifier())
    }
}