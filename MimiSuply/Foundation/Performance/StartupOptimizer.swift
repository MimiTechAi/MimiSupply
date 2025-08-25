// Send to analytics if needed
        await AnalyticsManager.shared.trackEvent(.appLaunch, parameters: [
                "startup_time": .double(metrics.totalStartupTime),
                "memory_usage": .double(metrics.memoryUsage)
            ])

// ... existing code …