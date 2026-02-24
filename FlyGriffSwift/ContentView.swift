import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "paperplane.fill")
                }

            AddFlightView()
                .tabItem {
                    Label("Add", systemImage: "airplane")
                }
        }
    }
}

#Preview {
    ContentView()
}