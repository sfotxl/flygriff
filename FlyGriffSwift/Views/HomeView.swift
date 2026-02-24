import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/World_map_-_low_resolution.svg/1024px-World_map_-_low_resolution.svg.png")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            Rectangle().fill(.blue.opacity(0.08))
                            ProgressView()
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("Where in the world is James Hurley?")
                        .font(.largeTitle).bold()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome").font(.title3).bold()
                        Text("This app was designed to make it easier for James's boyfriend to build him a flight map.")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("At the moment").font(.title3).bold()
                        Text("The app can be used to view historical flight data or add flight data to the database.")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("In the future").font(.title3).bold()
                        Text("The app will be expanded to provide visualizations of flight behavior, both in-app and on a physical flight map.")
                    }
                }
                .padding(16)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}