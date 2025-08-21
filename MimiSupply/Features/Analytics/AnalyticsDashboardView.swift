import SwiftUI

struct AnalyticsDashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Analytics Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Comprehensive analytics and insights")
                .font(.title2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15) {
                analyticsCard(
                    title: "Revenue Overview",
                    description: "Track daily, weekly, and monthly revenue",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                analyticsCard(
                    title: "Order Metrics",
                    description: "Monitor order volumes and conversion rates",
                    icon: "bag.fill",
                    color: .blue
                )
                
                analyticsCard(
                    title: "User Engagement",
                    description: "Analyze user behavior and retention",
                    icon: "person.2.fill",
                    color: .purple
                )
                
                analyticsCard(
                    title: "Partner Performance",
                    description: "Evaluate partner metrics and ratings",
                    icon: "storefront.fill",
                    color: .orange
                )
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Analytics")
    }
    
    private func analyticsCard(title: String, description: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    AnalyticsDashboardView()
}