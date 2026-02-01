import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Daily Vibe Tab
            DailyVibeView()
                .tabItem {
                    Label("Daily", systemImage: "sun.max.fill")
                }
                .tag(0)
            
            // Viral Features Tab
            ViralHubView()
                .tabItem {
                    Label("Viral", systemImage: "sparkles")
                }
                .tag(1)
            
            // Chat Tab
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(Color(hex: appState.currentUser?.energyDNA?.colorHex ?? "#4A4E69"))
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Energy DNA Card
                    if let dna = appState.currentUser?.energyDNA {
                        EnergyDNACard(dna: dna)
                    }
                    
                    // Soul ID Card
                    if let soul = appState.currentUser?.soulID {
                        SoulIDCard(soul: soul)
                    }
                    
                    // Pet Info
                    if let user = appState.currentUser {
                        PetInfoCard(petName: user.petName, petType: user.petType, petImage: user.petImage)
                    }
                }
                .padding()
            }
            .navigationTitle("Your Energy")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Card Components
struct EnergyDNACard: View {
    let dna: EnergyDNA
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚡️ Energy DNA")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(dna.type)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: dna.colorHex))
            
            Text(dna.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: dna.colorHex).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: dna.colorHex), lineWidth: 2)
        )
    }
}

struct SoulIDCard: View {
    let soul: SoulID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔮 Soul ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(soul.id)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            Text(soul.archetype)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("\"\(soul.quote)\"")
                .font(.body)
                .italic()
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

struct PetInfoCard: View {
    let petName: String
    let petType: String
    let petImage: Data?
    
    var body: some View {
        VStack(spacing: 12) {
            if let imageData = petImage, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("🐾")
                            .font(.system(size: 48))
                    )
            }
            
            Text(petName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(petType)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
