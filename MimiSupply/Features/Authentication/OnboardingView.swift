import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0
    
    var onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
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
            }
            .sheet(isPresented: $viewModel.showingLocationPermission) {
                LocationPermissionView(
                    onPermissionGranted: {
                        viewModel.handleLocationPermissionGranted()
                    }
                )
            }
        }
    }
    
    private func handleNext() {
        if currentPage < 3 {
            withAnimation {
                currentPage += 1
            }
        } else {
            viewModel.showingLocationPermission = true
        }
    }
    
    private func handleComplete() {
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
    OnboardingView(onComplete: {})
        .environmentObject(AppState())
}