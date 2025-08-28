import SwiftUI

// MARK: - Micro-Interactions System
struct MicroInteractions {
    
    // MARK: - Animation Presets
    enum AnimationPreset {
        case gentle
        case bouncy
        case snappy
        case smooth
        case energetic
        
        var animation: Animation {
            switch self {
            case .gentle:
                return .easeInOut(duration: 0.4)
            case .bouncy:
                return .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)
            case .snappy:
                return .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)
            case .smooth:
                return .easeOut(duration: 0.3)
            case .energetic:
                return .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2)
            }
        }
    }
    
    // MARK: - Interaction Types
    enum InteractionType {
        case tap
        case longPress
        case hover
        case focus
        case success
        case error
        case loading
    }
}

// MARK: - Enhanced Button Press Animation
struct PressableButtonStyle: ButtonStyle {
    let preset: MicroInteractions.AnimationPreset
    let scaleEffect: CGFloat
    let hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle?
    
    init(
        preset: MicroInteractions.AnimationPreset = .bouncy,
        scaleEffect: CGFloat = 0.95,
        hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle? = .light
    ) {
        self.preset = preset
        self.scaleEffect = scaleEffect
        self.hapticFeedback = hapticFeedback
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0.0)
            .animation(preset.animation, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed, let feedback = hapticFeedback {
                    let generator = UIImpactFeedbackGenerator(style: feedback)
                    generator.impactOccurred()
                }
            }
    }
}

// MARK: - PhaseAnimator Integration
@available(iOS 17.0, *)
struct PhaseAnimatedButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    @State private var animationPhase: AnimationPhase = .idle
    
    enum AnimationPhase: CaseIterable {
        case idle
        case pressed
        case success
        case error
        
        var scale: CGFloat {
            switch self {
            case .idle: return 1.0
            case .pressed: return 0.95
            case .success: return 1.05
            case .error: return 1.02
            }
        }
        
        var brightness: Double {
            switch self {
            case .idle: return 0.0
            case .pressed: return -0.1
            case .success: return 0.1
            case .error: return -0.05
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .idle: return 2
            case .pressed: return 1
            case .success: return 6
            case .error: return 4
            }
        }
    }
    
    init(@ViewBuilder content: () -> Content, action: @escaping () -> Void) {
        self.content = content()
        self.action = action
    }
    
    var body: some View {
        Button(action: handleTap) {
            content
        }
        .buttonStyle(PlainButtonStyle())
        .phaseAnimator(AnimationPhase.allCases, trigger: animationPhase) { view, phase in
            view
                .scaleEffect(phase.scale)
                .brightness(phase.brightness)
                .shadow(radius: phase.shadowRadius)
        } animation: { phase in
            switch phase {
            case .idle:
                return .easeOut(duration: 0.3)
            case .pressed:
                return .easeIn(duration: 0.1)
            case .success:
                return .spring(response: 0.4, dampingFraction: 0.6)
            case .error:
                return .spring(response: 0.3, dampingFraction: 0.8)
            }
        }
    }
    
    private func handleTap() {
        animationPhase = .pressed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
            animationPhase = .success
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animationPhase = .idle
            }
        }
    }
}

// MARK: - Card Interaction Effects
struct InteractiveCard<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var dragOffset = CGSize.zero
    
    init(
        @ViewBuilder content: () -> Content,
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.content = content()
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .offset(dragOffset)
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: dragOffset)
            .onTapGesture {
                onTap?()
            }
            .onLongPressGesture(
                minimumDuration: 0.5,
                maximumDistance: 10
            ) {
                onLongPress?()
            } onPressingChanged: { pressing in
                withAnimation {
                    isPressed = pressing
                }
                
                if pressing {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            .onHover { hovering in
                withAnimation {
                    isHovered = hovering
                }
            }
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .onChanged { value in
                        // Subtle drag effect
                        dragOffset = CGSize(
                            width: value.translation.width * 0.1,
                            height: value.translation.height * 0.1
                        )
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
            )
    }
    
    private var shadowOpacity: Double {
        if isPressed {
            return 0.1
        } else if isHovered {
            return 0.25
        } else {
            return 0.15
        }
    }
    
    private var shadowRadius: CGFloat {
        if isPressed {
            return 2
        } else if isHovered {
            return 8
        } else {
            return 4
        }
    }
    
    private var shadowOffset: CGFloat {
        if isPressed {
            return 1
        } else if isHovered {
            return 4
        } else {
            return 2
        }
    }
}

// MARK: - Loading Button with Animation
struct LoadingButton: View {
    let title: String
    let action: () -> Void
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0
    
    var body: some View {
        Button(action: handleAction) {
            HStack(spacing: 12) {
                if isLoading {
                    LoadingIndicator(progress: loadingProgress)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .opacity(0)
                }
                
                Text(isLoading ? "Loading..." : title)
                    .font(.labelLarge)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLoading ? Color.gray300 : Color.emerald)
            )
            .foregroundColor(.white)
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
    
    private func handleAction() {
        isLoading = true
        loadingProgress = 0
        Task { @MainActor in
            for _ in 0..<10 {
                try? await Task.sleep(for: .milliseconds(100))
                loadingProgress += 0.1
            }
            try? await Task.sleep(for: .milliseconds(500))
            isLoading = false
            action()
        }
    }
}

struct LoadingIndicator: View {
    let progress: Double
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Expandable Card
struct ExpandableCard<Content: View, ExpandedContent: View>: View {
    let content: Content
    let expandedContent: ExpandedContent
    @State private var isExpanded = false
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.content = content()
        self.expandedContent = expandedContent()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            InteractiveCard {
                content
            } onTap: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isVisible = true
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Button(action: handleAction) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.emerald)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .scaleEffect(isVisible ? 1.0 : 0.0)
        .rotationEffect(.degrees(rotationAngle))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .animation(.easeInOut(duration: 0.3), value: rotationAngle)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                isVisible = true
            }
        }
    }
    
    private func handleAction() {
        rotationAngle += 180
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
        }
    }
}

// MARK: - Preview
#Preview("Micro-Interactions") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Micro-Interactions Showcase")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Enhanced Buttons
            VStack(spacing: 16) {
                Button("Bouncy Button") {}
                    .buttonStyle(PressableButtonStyle(preset: .bouncy))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.emerald)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                if #available(iOS 17.0, *) {
                    PhaseAnimatedButton {
                        Text("Phase Animated")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    } action: {
                        print("Phase animated button tapped")
                    }
                }
                
                LoadingButton(title: "Load Data") {
                    print("Data loaded")
                }
                .padding(.horizontal)
            }
            
            // Interactive Cards
            VStack(spacing: 16) {
                InteractiveCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interactive Card")
                            .font(.headline)
                        Text("Tap, long press, or hover me!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                } onTap: {
                    print("Card tapped")
                } onLongPress: {
                    print("Card long pressed")
                }
                
                ExpandableCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expandable Card")
                            .font(.headline)
                        Text("Tap to expand")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                } expandedContent: {
                    VStack(spacing: 12) {
                        Text("Expanded Content")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("This content was hidden and now it's visible with a smooth animation.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    .overlay(alignment: .bottomTrailing) {
        FloatingActionButton(icon: "plus") {
            print("FAB tapped")
        }
        .padding()
    }
}
