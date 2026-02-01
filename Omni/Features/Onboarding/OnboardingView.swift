import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    // Form States
    @State private var dateOfBirth = Date()
    @State private var petName = ""
    @State private var petType = ""
    // @State private var petImage: UIImage? // Need ImagePicker
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Omni")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Energy Management for the AI Era")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Simple Form
                DatePicker("Birthday", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                
                TextField("Pet Name", text: $petName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Pet Type (e.g. Cat, Dog)", text: $petType)
                    .textFieldStyle(.roundedBorder)
                
                Spacer()
                
                Button(action: {
                    appState.completeOnboarding(dob: dateOfBirth, petName: petName, petType: petType, petImage: nil)
                }) {
                    Text("Generate Energy DNA")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}
