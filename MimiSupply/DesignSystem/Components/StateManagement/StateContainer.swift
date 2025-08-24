import SwiftUI

// MARK: - Universal State Container
struct StateContainer<Content: View, LoadingContent: View, EmptyContent: View, ErrorContent: View>: View {
    let state: ViewState
    @ViewBuilder let content: () -> Content
    @ViewBuilder let loadingContent: () -> LoadingContent
    @ViewBuilder let emptyContent: () -> EmptyContent
    @ViewBuilder let errorContent: (AppError) -> ErrorContent
    
    var body: some View {
        switch state {
        case .loading:
            loadingContent()
                .transition(.opacity)
        case .loaded(let hasData):
            if hasData {
                content()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            } else {
                emptyContent()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
        case .error(let error):
            errorContent(error)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
        }
    }
}

// MARK: - View State Enum
enum ViewState: Equatable {
    case loading
    case loaded(hasData: Bool)
    case error(AppError)
    
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded(let lhsHasData), .loaded(let rhsHasData)):
            return lhsHasData == rhsHasData
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Convenience State Container
struct SimpleStateContainer<Content: View>: View {
    let isLoading: Bool
    let hasData: Bool
    let error: AppError?
    let onRetry: (() -> Void)?
    @ViewBuilder let content: () -> Content
    let emptyStateType: EmptyStateType
    let onEmptyAction: (() -> Void)?
    
    init(
        isLoading: Bool,
        hasData: Bool,
        error: AppError? = nil,
        emptyStateType: EmptyStateType = .noData,
        onRetry: (() -> Void)? = nil,
        onEmptyAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.hasData = hasData
        self.error = error
        self.emptyStateType = emptyStateType
        self.onRetry = onRetry
        self.onEmptyAction = onEmptyAction
        self.content = content
    }
    
    var body: some View {
        let state: ViewState = {
            if let error = error {
                return .error(error)
            } else if isLoading {
                return .loading
            } else {
                return .loaded(hasData: hasData)
            }
        }()
        
        StateContainer(state: state) {
            content()
        } loadingContent: {
            AppLoadingView(message: "Loading...", size: .medium)
        } emptyContent: {
            ContextualEmptyStateView(
                type: emptyStateType,
                primaryAction: onEmptyAction
            )
        } errorContent: { error in
            ErrorStateView(
                error: error,
                onRetry: onRetry
            )
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}

// MARK: - Preview
#Preview("State Container") {
    TabView {
        SimpleStateContainer(
            isLoading: true,
            hasData: false,
            emptyStateType: .noData
        ) {
            Text("Content loaded")
        }
        .tabItem { Text("Loading") }
        
        SimpleStateContainer(
            isLoading: false,
            hasData: false,
            emptyStateType: .businessIntelligence(metric: "revenue")
        ) {
            Text("Content loaded")
        }
        .tabItem { Text("Empty") }
        
        SimpleStateContainer(
            isLoading: false,
            hasData: true,
            emptyStateType: .noData
        ) {
            VStack {
                Text("Content Loaded!")
                    .font(.title)
                Text("This is the actual content")
            }
        }
        .tabItem { Text("Loaded") }
        
        SimpleStateContainer(
            isLoading: false,
            hasData: false,
            error: .network(.noConnection),
            emptyStateType: .noData,
            onRetry: { print("Retry tapped") }
        ) {
            Text("Content loaded")
        }
        .tabItem { Text("Error") }
    }
}