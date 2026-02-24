import SwiftUI

struct AddFlightView: View {
    struct Option: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    private let service = FlightService()

    private let airlines: [Option] = [
        .init(label: "American Airlines", value: "AA"),
        .init(label: "Delta Air Lines", value: "DL"),
        .init(label: "United Airlines", value: "UA"),
        .init(label: "Southwest Airlines", value: "SW"),
        .init(label: "Alaska Airlines", value: "AS"),
        .init(label: "JetBlue Airways", value: "B6"),
        .init(label: "Spirit Airlines", value: "NK"),
        .init(label: "Frontier Airlines", value: "F9"),
        .init(label: "Hawaiian Airlines", value: "HA"),
        .init(label: "Allegiant Air", value: "G4")
    ]

    private let purposes: [Option] = [
        .init(label: "Business", value: "business"),
        .init(label: "Leisure", value: "leisure"),
        .init(label: "Visiting Family/Friends", value: "visiting"),
        .init(label: "Other", value: "other"),
        .init(label: "Liz", value: "Liz"),
        .init(label: "Rob", value: "Rob"),
        .init(label: "Kalani", value: "Kalani"),
        .init(label: "Chad", value: "Chad")
    ]

    @State private var selectedAirline = "AA"
    @State private var selectedPurpose = "business"
    @State private var flightNumber = ""
    @State private var date = ""
    @State private var departureAirport = ""
    @State private var arrivalAirport = ""
    @State private var isSubmitting = false
    @State private var resultMessage = ""
    @State private var resultIsError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Add a flight") {
                    Picker("Airline", selection: $selectedAirline) {
                        ForEach(airlines) { airline in
                            Text(airline.label).tag(airline.value)
                        }
                    }

                    TextField("Flight Number", text: $flightNumber)
                    TextField("Date (YYYY-MM-DD)", text: $date)
                    TextField("Departure Airport", text: $departureAirport)
                        .textInputAutocapitalization(.characters)
                    TextField("Arrival Airport", text: $arrivalAirport)
                        .textInputAutocapitalization(.characters)

                    Picker("Purpose", selection: $selectedPurpose) {
                        ForEach(purposes) { purpose in
                            Text(purpose.label).tag(purpose.value)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await submit()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Save Flight")
                        }
                    }
                    .disabled(isSubmitting || !isValid)
                }

                if !resultMessage.isEmpty {
                    Section {
                        Text(resultMessage)
                            .foregroundStyle(resultIsError ? .red : .green)
                    }
                }
            }
            .navigationTitle("Add")
        }
    }

    private var isValid: Bool {
        !flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !date.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        departureAirport.trimmingCharacters(in: .whitespacesAndNewlines).count == 3 &&
        arrivalAirport.trimmingCharacters(in: .whitespacesAndNewlines).count == 3
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        resultMessage = ""
        resultIsError = false
        defer { isSubmitting = false }

        let payload = NewFlightPayload(
            airline: selectedAirline,
            flight_number: flightNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date.trimmingCharacters(in: .whitespacesAndNewlines),
            from_airport_code: departureAirport.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            to_airport_code: arrivalAirport.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            trip_type: selectedPurpose
        )

        do {
            try await service.insertFlight(payload)
            resultMessage = "Flight saved to Supabase."
            flightNumber = ""
            date = ""
            departureAirport = ""
            arrivalAirport = ""
        } catch {
            resultIsError = true
            resultMessage = "Save failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AddFlightView()
}