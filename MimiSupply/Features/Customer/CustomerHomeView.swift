import SwiftUI

struct CustomerHomeView: View {
    var body: some View {
        NavigationView {
            ExploreHomeView()
                .navigationTitle("Home")
        }
    }
}

#Preview {
    CustomerHomeView()
}