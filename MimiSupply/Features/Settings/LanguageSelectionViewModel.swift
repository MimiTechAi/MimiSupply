//
//  LanguageSelectionViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI

/// ViewModel for language selection and localization
@MainActor
final class LanguageSelectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var availableLanguages: [SupportedLanguage] = []
    @Published var selectedLanguageCode: String = "en"
    @Published var isLoading = false
    @Published var showingRestartAlert = false
    
    // MARK: - Initialization
    
    init() {
        setupAvailableLanguages()
    }
    
    // MARK: - Language Management
    
    func loadCurrentLanguage() async {
        selectedLanguageCode = getCurrentLanguageCode()
    }
    
    func selectLanguage(_ language: SupportedLanguage) {
        selectedLanguageCode = language.code
    }
    
    func applyLanguageChange() async {
        isLoading = true
        
        // Find the selected language
        guard let selectedLanguage = availableLanguages.first(where: { $0.code == selectedLanguageCode }) else {
            isLoading = false
            return
        }
        
        // Update through LocalizationManager
        LocalizationManager.shared.changeLanguage(to: selectedLanguage)
        
        isLoading = false
        
        // Language switching without restart is now supported
        // No need to show restart alert
    }
    
    func restartApp() {
        // In a real app, you might want to handle this more gracefully
        // For now, we'll just exit the app
        exit(0)
    }
    
    // MARK: - Private Methods
    
    private func setupAvailableLanguages() {
        availableLanguages = SupportedLanguage.allLanguages
    }
    
    private func getCurrentLanguageCode() -> String {
        return LocalizationManager.shared.currentLanguage.code
    }
    
    private func setAppLanguage(_ languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Update bundle language
        Bundle.setLanguage(languageCode)
    }
}