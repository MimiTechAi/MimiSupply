import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showingLocationPermission = false
    @State private var locationPermissionGranted = false
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.emerald.opacity(0.1), Color.emerald.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                    .padding()
                }
                
                // Onboarding pages
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        title: "Welcome to MimiSupply",
                        description: "Your neighborhood marketplace for everything you need, delivered fast",
                        imageName: "bag.fill",
                        backgroundColor: .emerald.opacity(0.1),
                        tag: 0
                    )
                    
                    OnboardingPageView(
                        title: "Lightning Fast Delivery",
                        description: "Get your orders delivered in 15-30 minutes from local businesses",
                        imageName: "bolt.fill",
                        backgroundColor: .blue.opacity(0.1),
                        tag: 1
                    )
                    
                    OnboardingPageView(
                        title: "Support Local Businesses",
                        description: "Discover restaurants, groceries, pharmacies and more in your area",
                        imageName: "heart.fill",
                        backgroundColor: .orange.opacity(0.1),
                        tag: 2
                    )
                    
                    OnboardingPageView(
                        title: "Track Every Order",
                        description: "Real-time tracking from preparation to your doorstep",
                        imageName: "location.fill",
                        backgroundColor: .purple.opacity(0.1),
                        tag: 3,
                        isLast: true,
                        onNext: requestLocationPermission
                    )
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.emerald : Color.gray300)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        SecondaryButton(title: "Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }
                        .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    PrimaryButton(
                        title: currentPage < 3 ? "Next" : "Get Started"
                    ) {
                        if currentPage < 3 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            requestLocationPermission()
                        }
                    }
                    .frame(width: currentPage > 0 ? 120 : 200)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingLocationPermission) {
            LocationPermissionView(
                permissionType: .whenInUse,
                onPermissionGranted: {
                    locationPermissionGranted = true
                    showingLocationPermission = false
                    completeOnboarding()
                },
                onPermissionDenied: {
                    locationPermissionGranted = false
                    showingLocationPermission = false
                    completeOnboarding()
                }
            )
        }
    }
    
    private func requestLocationPermission() {
        showingLocationPermission = true
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        onComplete()
    }
}

struct OnboardingPageView: View {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
    let tag: Int
    let isLast: Bool
    let onNext: () -> Void
    
    init(
        title: String,
        description: String,
        imageName: String,
        backgroundColor: Color = .clear,
        tag: Int,
        isLast: Bool = false,
        onNext: @escaping () -> Void = {}
    ) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.backgroundColor = backgroundColor
        self.tag = tag
        self.isLast = isLast
        self.onNext = onNext
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 200, height: 200)
                
                Image(systemName: imageName)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.emerald)
            }
            .padding(.top, 40)
            
            // Content
            VStack(spacing: 16) {
                Text(title)
                    .font(.headlineLarge)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.graphite)
                
                Text(description)
                    .font(.bodyLarge)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .tag(tag)
        .padding()
    }
}

#Preview {
    OnboardingView()
}