import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var currentRoute: AppRoute = .onboarding
    
    // Simple persistence simulation (UserDefaults or just memory for MVP session)
    // For MVP validation, let's keep it in memory mostly, but maybe save to UserDefaults to skip onboarding on relaunch if needed.
    // For now, let's assume fresh start or simple persistence.
    
    init() {
        // Load user from disk if exists (Mock implementation)
        // self.currentUser = loadUser()
        // if self.currentUser != nil { currentRoute = .home }
    }
    
    func completeOnboarding(dob: Date, petName: String, petType: String, petImage: UIImage?) {
        // 1. Generate DNA (Mock Logic)
        let dna = generateMockDNA(dob: dob)
        let soul = generateMockSoulID(petType: petType)
        
        // 2. Create User
        let user = UserProfile(
            dateOfBirth: dob,
            petName: petName,
            petType: petType,
            petImage: petImage?.jpegData(compressionQuality: 0.8),
            energyDNA: dna,
            soulID: soul
        )
        
        // 3. Save & Transition
        self.currentUser = user
        withAnimation {
            self.currentRoute = .home
        }
    }
    
    private func generateMockDNA(dob: Date) -> EnergyDNA {
        // Simple logic: Odd/Even day -> Different types
        let calendar = Calendar.current
        let day = calendar.component(.day, from: dob)
        
        if day % 2 == 0 {
            return EnergyDNA(type: "Void Walker", description: "You thrive in chaos and silence.", colorHex: "#4A4E69")
        } else {
            return EnergyDNA(type: "Solar Flare", description: "You burn bright and exhaust quickly.", colorHex: "#FFB84C")
        }
    }
    
    private func generateMockSoulID(petType: String) -> SoulID {
        let suffix = Int.random(in: 1000...9999)
        let archetype = petType.lowercased() == "cat" ? "Master Manipulator" : "Loyal Goofball"
        return SoulID(id: "OMNI-\(suffix)", archetype: archetype, quote: "Judge me all you want, I know where you sleep.")
    }
}
