//
//  String+Localization.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI

// MARK: - String Localization Extensions

extension String {
    
    /// Get localized string using the key
    var localized: String {
        return LocalizationManager.shared.localizedString(self)
    }
    
    /// Get localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(self)
        return String(format: format, arguments: arguments)
    }
    
    /// Get localized string from specific table
    func localized(from table: String) -> String {
        return LocalizationManager.shared.localizedString(self, tableName: table)
    }
    
    /// Get localized string with comment
    func localized(comment: String) -> String {
        return LocalizationManager.shared.localizedString(self, comment: comment)
    }
}

// MARK: - Localization Keys

enum LocalizationKeys {
    
    // MARK: - Common
    enum Common: String, CaseIterable {
        case ok = "common.ok"
        case cancel = "common.cancel"
        case done = "common.done"
        case save = "common.save"
        case delete = "common.delete"
        case edit = "common.edit"
        case add = "common.add"
        case remove = "common.remove"
        case search = "common.search"
        case filter = "common.filter"
        case sort = "common.sort"
        case loading = "common.loading"
        case error = "common.error"
        case retry = "common.retry"
        case close = "common.close"
        case back = "common.back"
        case next = "common.next"
        case previous = "common.previous"
        case yes = "common.yes"
        case no = "common.no"
        case minutes = "common.minutes"
        case hours = "common.hours"
        
        var localized: String {
            return self.rawValue.localized
        }
    }
    
    // MARK: - Authentication
    enum Authentication: String, CaseIterable {
        case signIn = "auth.sign_in"
        case signOut = "auth.sign_out"
        case signInWithApple = "auth.sign_in_with_apple"
        case selectRole = "auth.select_role"
        case customer = "auth.customer"
        case driver = "auth.driver"
        case partner = "auth.partner"
        case welcomeBack = "auth.welcome_back"
        case getStarted = "auth.get_started"
        case createAccount = "auth.create_account"
        case forgotPassword = "auth.forgot_password"
        case resetPassword = "auth.reset_password"
        case changePassword = "auth.change_password"
        case currentPassword = "auth.current_password"
        case newPassword = "auth.new_password"
        case confirmPassword = "auth.confirm_password"
        case passwordMismatch = "auth.password_mismatch"
        case invalidCredentials = "auth.invalid_credentials"
        case accountLocked = "auth.account_locked"
        case sessionExpired = "auth.session_expired"
        case authenticationFailed = "auth.authentication_failed"
        case biometricAuth = "auth.biometric_auth"
        case enableBiometrics = "auth.enable_biometrics"
        case useBiometrics = "auth.use_biometrics"
        
        var localized: String {
            return self.rawValue.localized
        }
    }
    
    // MARK: - Explore
    enum Explore: String, CaseIterable {
        case explore = "explore.explore"
        case searchPlaceholder = "explore.search_placeholder"
        case deliverTo = "explore.deliver_to"
        case categories = "explore.categories"
        case featuredPartners = "explore.featured_partners"
        case allPartners = "explore.all_partners"
        case nearbyPartners = "explore.nearby_partners"
        case seeAll = "explore.see_all"
        case noPartnersFound = "explore.no_partners_found"
        case adjustFilters = "explore.adjust_filters"
        case mapView = "explore.map_view"
        case listView = "explore.list_view"
        case filters = "explore.filters"
        case sortBy = "explore.sort_by"
        case distance = "explore.distance"
        case rating = "explore.rating"
        case deliveryTime = "explore.delivery_time"
        case priceRange = "explore.price_range"
        case openNow = "explore.open_now"
        case freeDelivery = "explore.free_delivery"
        case verified = "explore.verified"
        case newPartner = "explore.new_partner"
        case promoted = "explore.promoted"
        case closed = "explore.closed"
        case opensAt = "explore.opens_at"
        case closesAt = "explore.closes_at"
        case deliveryFee = "explore.delivery_fee"
        case minimumOrder = "explore.minimum_order"
        case estimatedDelivery = "explore.estimated_delivery"
        case minutes = "explore.minutes"
        case km = "explore.km"
        case miles = "explore.miles"
        case found = "explore.found"
        case results = "explore.results"
        case noResults = "explore.no_results"
        case tryDifferentSearch = "explore.try_different_search"
        case locationPermission = "explore.location_permission"
        case enableLocation = "explore.enable_location"
        case locationRequired = "explore.location_required"
        case manualLocation = "explore.manual_location"
        case enterAddress = "explore.enter_address"
        case currentLocation = "explore.current_location"
        case recentSearches = "explore.recent_searches"
        case clearSearchHistory = "explore.clear_search_history"
        case popularSearches = "explore.popular_searches"
        case trendingNow = "explore.trending_now"
        case loadingMore = "explore.loading_more"
        case refreshToUpdate = "explore.refresh_to_update"
        case pullToRefresh = "explore.pull_to_refresh"
        
        var localized: String {
            return self.rawValue.localized
        }
    }
    
    // MARK: - Cart
    enum Cart: String, CaseIterable {
        case cart = "cart.cart"
        case addToCart = "cart.add_to_cart"
        case removeFromCart = "cart.remove_from_cart"
        case updateQuantity = "cart.update_quantity"
        case quantity = "cart.quantity"
        case subtotal = "cart.subtotal"
        case deliveryFee = "cart.delivery_fee"
        case platformFee = "cart.platform_fee"
        case tax = "cart.tax"
        case tip = "cart.tip"
        case total = "cart.total"
        case emptyCart = "cart.empty_cart"
        case emptyCartMessage = "cart.empty_cart_message"
        case startShopping = "cart.start_shopping"
        case proceedToCheckout = "cart.proceed_to_checkout"
        case checkout = "cart.checkout"
        case clearCart = "cart.clear_cart"
        case confirmClearCart = "cart.confirm_clear_cart"
        case itemsInCart = "cart.items_in_cart"
        case cartUpdated = "cart.cart_updated"
        case itemAdded = "cart.item_added"
        case itemRemoved = "cart.item_removed"
        case quantityUpdated = "cart.quantity_updated"
        case maxQuantityReached = "cart.max_quantity_reached"
        case outOfStock = "cart.out_of_stock"
        case limitedStock = "cart.limited_stock"
        case stockRemaining = "cart.stock_remaining"
        case unavailableItems = "cart.unavailable_items"
        case removeUnavailable = "cart.remove_unavailable"
        case keepUnavailable = "cart.keep_unavailable"
        case priceChanged = "cart.price_changed"
        case updatePrices = "cart.update_prices"
        case specialInstructions = "cart.special_instructions"
        case addNote = "cart.add_note"
        case editNote = "cart.edit_note"
        case removeNote = "cart.remove_note"
        case savedForLater = "cart.saved_for_later"
        case moveToSaved = "cart.move_to_saved"
        case moveToCart = "cart.move_to_cart"
        case recentlyViewed = "cart.recently_viewed"
        case recommendedItems = "cart.recommended_items"
        case frequentlyBought = "cart.frequently_bought"
        case addRecommended = "cart.add_recommended"
        
        var localized: String {
            return self.rawValue.localized
        }
    }
}