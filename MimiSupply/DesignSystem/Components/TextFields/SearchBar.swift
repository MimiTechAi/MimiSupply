import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(accessibilityManager.isHighContrastEnabled ? .black : .gray500)
                .font(.body.scaledFont())
                .accessibilityHidden(true) // Decorative icon
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.bodyMedium.scaledFont())
                .focused($isFocused)
                .accessibleTextField(
                    label: accessibilityLabel ?? "Search field",
                    value: text.isEmpty ? "" : text,
                    hint: accessibilityHint ?? "Enter search terms to find restaurants, groceries, and more"
                )
                .onChange(of: text) { oldValue, newValue in
                    // Announce search results updates for VoiceOver users
                    if accessibilityManager.isVoiceOverRunning && !newValue.isEmpty && newValue != oldValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            accessibilityManager.announce("Search updated")
                        }
                    }
                }
            
            if !text.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(accessibilityManager.isHighContrastEnabled ? .black : .gray500)
                        .font(.body.scaledFont())
                }
                .accessibleButton(
                    label: "Clear search",
                    hint: "Removes all text from the search field"
                )
                .frame(minWidth: Font.minimumTouchTarget, minHeight: Font.minimumTouchTarget)
            }
        }
        .padding(.horizontal, 12 * accessibilityManager.preferredContentSizeCategory.spacingMultiplier)
        .padding(.vertical, 8 * accessibilityManager.preferredContentSizeCategory.spacingMultiplier)
        .background(
            accessibilityManager.isHighContrastEnabled ? 
                Color.white : Color.gray100
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isFocused ? 
                        (accessibilityManager.isHighContrastEnabled ? Color.black : Color.emerald) : 
                        Color.clear,
                    lineWidth: accessibilityManager.isHighContrastEnabled ? 2 : 1
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search bar")
        .accessibilityHint("Contains search field and clear button")
    }
    
    private func clearSearch() {
        text = ""
        
        // Provide haptic feedback
        if accessibilityManager.isVoiceOverRunning {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        // Announce the action to VoiceOver users
        if accessibilityManager.isVoiceOverRunning {
            accessibilityManager.announce("Search cleared")
        }
        
        // Return focus to search field
        isFocused = true
    }
}

#Preview {
    SearchBar(text: .constant(""), placeholder: "Search...")
        .padding()
}