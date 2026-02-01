import Foundation
import SwiftUI

// MARK: - Models

struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String? // User might not enter name, but maybe we ask? Let's assume Birthday is key.
    var dateOfBirth: Date
    var petName: String
    var petType: String
    var petImage: Data? // Storing image as Data for simplicity in MVP
    var energyDNA: EnergyDNA?
    var soulID: SoulID?
}

struct EnergyDNA: Codable {
    let type: String       // e.g., "Solar Generator", "Lunar Reflector"
    let description: String
    let colorHex: String   // Primary associated color
}

struct SoulID: Codable {
    let id: String         // Unique generated ID string
    let archetype: String  // e.g., "Chaos Gremlin", "Noble Guardian"
    let quote: String      // The "Roast" or "Vibe" quote
}

enum AppRoute {
    case onboarding
    case home
}
