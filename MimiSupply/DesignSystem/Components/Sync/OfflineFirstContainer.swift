//
//  OfflineFirstContainer.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Combine

/// Container view that provides offline-first functionality to child views
struct OfflineFirstContainer<Content: View>: View {
    let content: Content
    
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var degradationService = GracefulDegradationService.shared
    @StateObject private var persistenceManager = OfflinePersistenceManager.shared
    
    @State private var showingSyncSheet = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            content
            
            // Offline/Sync indicators overlay
            VStack(spacing: 0) {
                // Offline indicator (top priority)
                OfflineIndicatorView()
                
                // Service degradation indicator
                ServiceStatusIndicator()
                    .padding(.horizontal, Spacing.lg)
                
                // Sync indicator
                HStack {
                    Spacer()
                    SyncIndicatorView()
                        .onTapGesture {
                            showingSyncSheet = true
                        }
                }
                .padding(.horizontal, Spacing.lg)
                
                Spacer()
            }
            
            // Retry banners
            VStack {
                RetryBannerView()
                Spacer()
            }
        }
        .sheet(isPresented: $showingSyncSheet) {
            SyncStatusDashboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await handleAppWillEnterForeground()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            Task {
                await handleAppDidEnterBackground()
            }
        }
    }
    
    // MARK: - App Lifecycle Handlers
    
    @MainActor
    private func handleAppWillEnterForeground() async {
        // Check for pending sync when app comes to foreground
        if networkMonitor.isConnected && offlineManager.pendingSyncCount > 0 {
            await offlineManager.forceSyncNow()
        }
        
        // Clean expired cache
        await persistenceManager.cleanExpiredCache()
        
        // Enforce cache limits
        await persistenceManager.enforceCacheLimits()
    }
    
    @MainActor
    private func handleAppDidEnterBackground() async {
        // Perform background cleanup
        await persistenceManager.cleanExpiredCache()
    }
}

/// Convenience modifier for adding offline-first functionality
extension View {
    func offlineFirst() -> some View {
        OfflineFirstContainer {
            self
        }
    }
}

// MARK: - Offline-First Data Loading

/// Protocol for views that need offline-first data loading
protocol OfflineFirstLoadable {
    associatedtype DataType: Codable
    
    var cacheKey: String { get }
    var cacheCategory: CacheCategory { get }
    
    func loadDataOnline() async throws -> DataType
    func loadDataOffline() async -> DataType?
}

/// Generic offline-first data loader
@MainActor
final class OfflineFirstDataLoader<T: Codable & Equatable & Sendable>: ObservableObject {
    @Published var data: T?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loadingSource: DataSource = .unknown
    
    private let cacheKey: String
    private let cacheCategory: CacheCategory
    private let onlineLoader: @Sendable () async throws -> T
    private let persistenceManager = OfflinePersistenceManager.shared
    private let degradationService = GracefulDegradationService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    enum DataSource {
        case unknown
        case cache
        case network
        case fallback
    }
    
    init(
        cacheKey: String,
        cacheCategory: CacheCategory = .general,
        onlineLoader: @escaping @Sendable () async throws -> T
    ) {
        self.cacheKey = cacheKey
        self.cacheCategory = cacheCategory
        self.onlineLoader = onlineLoader
    }
    
    /// Load data with offline-first strategy
    func loadData(forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Strategy 1: Try cached data first (if not forcing refresh)
        if !forceRefresh {
            if let cachedData = try? await persistenceManager.retrieveCachedData(
                T.self,
                forKey: cacheKey,
                category: cacheCategory
            ) {
                data = cachedData
                loadingSource = .cache
                isLoading = false
                
                // Still try to update in background if online
                if networkMonitor.isConnected {
                    Task {
                        await refreshDataInBackground()
                    }
                }
                return
            }
        }
        
        // Strategy 2: Try online loading
        if networkMonitor.isConnected {
            do {
                let onlineData = try await onlineLoader()
                data = onlineData
                loadingSource = .network
                
                // Cache the fresh data
                try? await persistenceManager.cacheData(
                    onlineData,
                    forKey: cacheKey,
                    category: cacheCategory
                )
                
                isLoading = false
                return
            } catch {
                errorMessage = error.localizedDescription
                
                // Handle CloudKit errors specifically
                if let ckError = error as? CloudKitError {
                    await CloudKitErrorHandler.shared.handleCloudKitError(
                        ckError,
                        operation: "loadData",
                        retryOperation: {
                            await self.loadData(forceRefresh: true)
                        }
                    )
                }
            }
        }
        
        // Strategy 3: Fallback to any cached data (even expired)
        if data == nil {
            // This would be a more lenient cache retrieval
            loadingSource = .fallback
        }
        
        isLoading = false
    }
    
    /// Refresh data in background without affecting UI loading state
    private func refreshDataInBackground() async {
        guard networkMonitor.isConnected else { return }
        
        do {
            let freshData = try await onlineLoader()
            
            // Update cache
            try? await persistenceManager.cacheData(
                freshData,
                forKey: cacheKey,
                category: cacheCategory
            )
            
            // Update data if significantly different
            if shouldUpdateData(current: data, new: freshData) {
                data = freshData
                loadingSource = .network
            }
        } catch {
            // Silent failure for background refresh
        }
    }
    
    /// Determine if data should be updated based on content comparison
    private func shouldUpdateData(current: T?, new: T) -> Bool {
        // This would implement smart comparison logic
        // For now, always update
        return true
    }
    
    /// Clear cached data
    func clearCache() async {
        // Remove specific cache item
        // Implementation would be added to persistenceManager
    }
}

// MARK: - Offline-First View Modifier

struct OfflineFirstDataModifier<T: Codable & Equatable & Sendable>: ViewModifier {
    @StateObject private var dataLoader: OfflineFirstDataLoader<T>
    
    let onDataLoaded: (T?) -> Void
    let onError: (String?) -> Void
    
    init(
        cacheKey: String,
        cacheCategory: CacheCategory = .general,
        onlineLoader: @escaping @Sendable () async throws -> T,
        onDataLoaded: @escaping (T?) -> Void,
        onError: @escaping (String?) -> Void
    ) {
        self._dataLoader = StateObject(wrappedValue: OfflineFirstDataLoader(
            cacheKey: cacheKey,
            cacheCategory: cacheCategory,
            onlineLoader: onlineLoader
        ))
        self.onDataLoaded = onDataLoaded
        self.onError = onError
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Task {
                    await dataLoader.loadData()
                }
            }
            .onChange(of: dataLoader.data) { oldData, newData in
                onDataLoaded(newData)
            }
            .onChange(of: dataLoader.errorMessage) { oldError, newError in
                onError(newError)
            }
            .refreshable {
                await dataLoader.loadData(forceRefresh: true)
            }
    }
}

extension View {
    func offlineFirstData<T: Codable & Equatable & Sendable>(
        _ type: T.Type,
        cacheKey: String,
        cacheCategory: CacheCategory = .general,
        onlineLoader: @escaping @Sendable () async throws -> T,
        onDataLoaded: @escaping (T?) -> Void,
        onError: @escaping (String?) -> Void = { _ in }
    ) -> some View {
        modifier(OfflineFirstDataModifier(
            cacheKey: cacheKey,
            cacheCategory: cacheCategory,
            onlineLoader: onlineLoader,
            onDataLoaded: onDataLoaded,
            onError: onError
        ))
    }
}

// MARK: - Preview

struct OfflineFirstContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                Text("Sample Content")
                    .font(.title)
                
                Button("Test Offline Banner") {
                    RetryBannerManager.shared.showRetryBanner(
                        title: "Sync Failed",
                        message: "Unable to sync data. Tap to retry.",
                        severity: .error,
                        operation: {
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                    )
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.emerald)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Offline First Demo")
        }
        .offlineFirst()
    }
}