LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(haptics.enumerated()), id: \.offset) { _, haptic in
                    Button(haptic.0) {
                        HapticManager.shared.trigger(haptic.1)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }

// ... existing code ...