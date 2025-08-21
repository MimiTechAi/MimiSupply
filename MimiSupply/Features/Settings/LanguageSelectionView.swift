//
//  LanguageSelectionView.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

/// Language selection view for localization support
struct LanguageSelectionView: View {
    @StateObject private var viewModel = LanguageSelectionViewModel()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.availableLanguages, id: \.code) { language in
                    LanguageRow(
                        language: language,
                        isSelected: language.code == viewModel.selectedLanguageCode,
                        onSelect: {
                            viewModel.selectLanguage(language)
                        }
                    )
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibleButton(
                        label: "Cancel",
                        hint: "Cancel language selection"
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            await viewModel.applyLanguageChange()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .accessibleButton(
                        label: "Done",
                        hint: "Apply language selection"
                    )
                }
            }
            .alert("Restart Required", isPresented: $viewModel.showingRestartAlert) {
                Button("Later") { }
                Button("Restart Now") {
                    viewModel.restartApp()
                }
            } message: {
                Text("The app needs to restart to apply the new language. You can restart now or the changes will take effect the next time you open the app.")
            }
        }
        .task {
            await viewModel.loadCurrentLanguage()
        }
    }
}

// MARK: - Language Row Component

struct LanguageRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let onSelect: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(language.nativeName)
                        .font(.bodyMedium.scaledFont())
                        .foregroundColor(.graphite)
                    
                    Text(language.englishName)
                        .font(.bodySmall.scaledFont())
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(.emerald)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibleCard(
            title: language.nativeName,
            subtitle: language.englishName,
            hint: isSelected ? "Currently selected language" : "Tap to select this language",
            isSelected: isSelected
        )
        .switchControlAccessible(
            identifier: "language-\(language.code)",
            sortPriority: isSelected ? 1.0 : 0.8
        )
    }
}

#Preview {
    LanguageSelectionView()
}