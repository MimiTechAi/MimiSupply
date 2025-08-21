//
//  AppError.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CloudKit

/// Comprehensive error system for the MimiSupply app
enum AppError: LocalizedError, Sendable {
    case authentication(AuthenticationError)
    case network(NetworkError)
    case cloudKit(CKError)
    case location(LocationError)
    case payment(PaymentError)
    case validation(ValidationError)
    case dataNotFound(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .authentication(let error):
            return error.localizedDescription
        case .network(let error):
            return error.localizedDescription
        case .cloudKit(let error):
            return "Sync error: \(error.localizedDescription)"
        case .location(let error):
            return "Location error: \(error.localizedDescription)"
        case .payment(let error):
            return "Payment error: \(error.localizedDescription)"
        case .validation(let error):
            return error.localizedDescription
        case .dataNotFound(let message):
            return message
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authentication:
            return "Please sign in again to continue."
        case .network:
            return "Please check your internet connection and try again."
        case .cloudKit:
            return "Your data will sync when connection is restored."
        case .location:
            return "Please enable location services in Settings."
        case .payment:
            return "Please check your payment method and try again."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - Specific Error Types

enum AuthenticationError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidCredentials
    case tokenExpired
    case signInFailed(String)
    case signOutFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue."
        case .invalidCredentials:
            return "Invalid credentials provided."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed:
            return "Sign out failed. Please try again."
        }
    }
}

enum NetworkError: LocalizedError, Sendable {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .connectionFailed:
            return "Connection failed. Please try again."
        }
    }
}



enum PaymentError: LocalizedError, Sendable {
    case paymentFailed
    case invalidAmount
    case cardDeclined
    case insufficientFunds
    case applePayNotAvailable
    case paymentCancelled
    case merchantNotConfigured
    case networkError
    case refundFailed
    case receiptNotFound
    case invalidRefundAmount
    
    var errorDescription: String? {
        switch self {
        case .paymentFailed:
            return "Payment processing failed."
        case .invalidAmount:
            return "Invalid payment amount."
        case .cardDeclined:
            return "Payment method declined."
        case .insufficientFunds:
            return "Insufficient funds."
        case .applePayNotAvailable:
            return "Apple Pay is not available on this device."
        case .paymentCancelled:
            return "Payment was cancelled."
        case .merchantNotConfigured:
            return "Payment system is not properly configured."
        case .networkError:
            return "Network error during payment processing."
        case .refundFailed:
            return "Refund processing failed."
        case .receiptNotFound:
            return "Payment receipt not found."
        case .invalidRefundAmount:
            return "Invalid refund amount."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .paymentFailed:
            return "Please try again or use a different payment method."
        case .invalidAmount:
            return "Please check the order total and try again."
        case .cardDeclined:
            return "Please check your payment method or try a different card."
        case .insufficientFunds:
            return "Please ensure you have sufficient funds and try again."
        case .applePayNotAvailable:
            return "Please add a payment method to Apple Wallet or use a different device."
        case .paymentCancelled:
            return "Tap 'Pay with Apple Pay' to complete your purchase."
        case .merchantNotConfigured:
            return "Please contact support for assistance."
        case .networkError:
            return "Please check your internet connection and try again."
        case .refundFailed:
            return "Please contact support for refund assistance."
        case .receiptNotFound:
            return "Please contact support with your order details."
        case .invalidRefundAmount:
            return "Please contact support for refund assistance."
        }
    }
}

enum LocationError: LocalizedError, Sendable {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
    case invalidCoordinates
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied."
        case .locationUnavailable:
            return "Location services unavailable."
        case .geocodingFailed:
            return "Failed to find location."
        case .invalidCoordinates:
            return "Invalid location coordinates."
        }
    }
}

// MARK: - AuthServiceError for Authentication Service
// AuthServiceError is now defined in AuthenticationService.swift

// MARK: - CloudKit Specific Errors
// CloudKitError is now defined in Foundation/Error/CloudKitError.swift

enum ValidationError: LocalizedError, Sendable {
    case invalidEmail
    case invalidPhoneNumber
    case requiredFieldMissing(String)
    case invalidFormat(String)
    case orderNotFound
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        case .requiredFieldMissing(let field):
            return "\(field) is required."
        case .invalidFormat(let field):
            return "\(field) format is invalid."
        case .orderNotFound:
            return "Order not found."
        case .invalidImageData:
            return "Invalid image data provided."
        }
    }
}
