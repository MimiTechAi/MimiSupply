//
//  AppState.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation
import SwiftUI
import Combine

/// Global app state management
@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var cartItems: [CartItem] = []
    
    // Public initializer
    init() {}
}