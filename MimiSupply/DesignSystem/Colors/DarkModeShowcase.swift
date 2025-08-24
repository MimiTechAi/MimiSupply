import SwiftUI

// MARK: - Dark Mode Showcase
struct DarkModeShowcase: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedColorScheme: ColorScheme = .light
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Theme Toggle
                Picker("Color Scheme", selection: $selectedColorScheme) {
                    Text("Light").tag(ColorScheme.light)
                    Text("Dark").tag(ColorScheme.dark)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Business Intelligence Cards
                        BusinessIntelligenceShowcase()
                        
                        // UI Components
                        UIComponentsShowcase()
                        
                        // Interactive Elements
                        InteractiveElementsShowcase()
                        
                        // Status Colors
                        StatusColorsShowcase()
                    }
                    .padding()
                }
            }
            .navigationTitle("Dark Mode Showcase")
            .preferredColorScheme(selectedColorScheme)
            .background(ColorTokens.UI.backgroundPrimary)
        }
    }
}

// MARK: - Business Intelligence Showcase
struct BusinessIntelligenceShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Business Intelligence")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTokens.Content.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // Revenue Card
                ShowcaseCard(
                    title: "Revenue",
                    value: "$24,680",
                    change: "+15.3%",
                    isPositive: true,
                    icon: "dollarsign.circle.fill",
                    color: ColorTokens.Special.revenue
                )
                
                // Orders Card
                ShowcaseCard(
                    title: "Orders",
                    value: "1,248",
                    change: "+8.7%",
                    isPositive: true,
                    icon: "bag.fill",
                    color: ColorTokens.Special.orders
                )
                
                // Customers Card
                ShowcaseCard(
                    title: "Customers",
                    value: "856",
                    change: "+12.1%",
                    isPositive: true,
                    icon: "person.2.fill",
                    color: ColorTokens.Special.customers
                )
                
                // Performance Card
                ShowcaseCard(
                    title: "Performance",
                    value: "94.2%",
                    change: "-2.1%",
                    isPositive: false,
                    icon: "chart.line.uptrend.xyaxis",
                    color: ColorTokens.Special.performance
                )
            }
            
            // Chart Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Revenue Trends")
                    .font(.headline)
                    .foregroundColor(ColorTokens.Content.textPrimary)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorTokens.Special.analytics.opacity(0.1))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundColor(ColorTokens.Special.analytics)
                            Text("Interactive Chart")
                                .font(.caption)
                                .foregroundColor(ColorTokens.Content.textSecondary)
                        }
                    )
            }
            .padding()
            .background(ColorTokens.UI.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: ColorTokens.UI.separator.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - UI Components Showcase
struct UIComponentsShowcase: View {
    @State private var isToggleOn = true
    @State private var sliderValue: Double = 0.7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UI Components")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTokens.Content.textPrimary)
            
            VStack(spacing: 16) {
                // Text Fields
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Input")
                        .font(.subheadline)
                        .foregroundColor(ColorTokens.Content.textPrimary)
                    
                    TextField("Enter your message", text: .constant("Sample text"))
                        .textFieldStyle(ShowcaseTextFieldStyle())
                }
                
                // Toggle and Slider
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundColor(ColorTokens.Content.textPrimary)
                        
                        Toggle("Enable notifications", isOn: $isToggleOn)
                            .toggleStyle(SwitchToggleStyle(tint: ColorTokens.Brand.primary))
                    }
                    
                    Spacer()
                }
                
                // Slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume: \(Int(sliderValue * 100))%")
                        .font(.subheadline)
                        .foregroundColor(ColorTokens.Content.textPrimary)
                    
                    Slider(value: $sliderValue, in: 0...1)
                        .accentColor(ColorTokens.Brand.primary)
                }
            }
            .padding()
            .background(ColorTokens.UI.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: ColorTokens.UI.separator.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Interactive Elements Showcase
struct InteractiveElementsShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interactive Elements")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTokens.Content.textPrimary)
            
            VStack(spacing: 12) {
                // Primary Button
                Button("Primary Action") {}
                    .buttonStyle(ShowcasePrimaryButtonStyle())
                
                // Secondary Button
                Button("Secondary Action") {}
                    .buttonStyle(ShowcaseSecondaryButtonStyle())
                
                // Tertiary Button
                Button("Tertiary Action") {}
                    .buttonStyle(ShowcaseTertiaryButtonStyle())
                
                // Navigation Items
                HStack(spacing: 16) {
                    ForEach(["house.fill", "chart.bar.fill", "gear"], id: \.self) { icon in
                        Button {
                            // Action
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(ColorTokens.Content.iconPrimary)
                                .frame(width: 44, height: 44)
                                .background(ColorTokens.UI.surfaceSecondary)
                                .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(ColorTokens.UI.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: ColorTokens.UI.separator.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Status Colors Showcase
struct StatusColorsShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Colors")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTokens.Content.textPrimary)
            
            VStack(spacing: 12) {
                StatusRow(
                    title: "Success",
                    message: "Operation completed successfully",
                    color: ColorTokens.Status.success,
                    backgroundColor: ColorTokens.Status.successBackground
                )
                
                StatusRow(
                    title: "Warning",
                    message: "Please review this information",
                    color: ColorTokens.Status.warning,
                    backgroundColor: ColorTokens.Status.warningBackground
                )
                
                StatusRow(
                    title: "Error",
                    message: "Something went wrong",
                    color: ColorTokens.Status.error,
                    backgroundColor: ColorTokens.Status.errorBackground
                )
                
                StatusRow(
                    title: "Info",
                    message: "Additional information available",
                    color: ColorTokens.Status.info,
                    backgroundColor: ColorTokens.Status.infoBackground
                )
            }
            .padding()
            .background(ColorTokens.UI.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: ColorTokens.UI.separator.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views

struct ShowcaseCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? ColorTokens.Status.success : ColorTokens.Status.error)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTokens.Content.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(ColorTokens.Content.textSecondary)
        }
        .padding()
        .background(ColorTokens.UI.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: ColorTokens.UI.separator.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct StatusRow: View {
    let title: String
    let message: String
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTokens.Content.textPrimary)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(ColorTokens.Content.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Button Styles

struct ShowcasePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(ColorTokens.Content.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(ColorTokens.Interactive.primary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ShowcaseSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(ColorTokens.Interactive.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(ColorTokens.UI.surfaceSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorTokens.UI.borderPrimary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ShowcaseTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(ColorTokens.Interactive.tertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.clear)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ShowcaseTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(ColorTokens.UI.surfaceSecondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ColorTokens.UI.borderPrimary, lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview("Dark Mode Showcase") {
    DarkModeShowcase()
}