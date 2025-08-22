// ... existing code ...
    func openAppSettings() {
        Task { @MainActor in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsUrl) else {
                return
            }
            UIApplication.shared.open(settingsUrl)
        }
    }
// ... existing code ...