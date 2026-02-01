import SwiftUI

struct DailyVibeView: View {
    @EnvironmentObject var appState: AppState
    @State private var dailyVibe = generateDailyVibe()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(greetingMessage())
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(todayDateString())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Energy Score Card
                    EnergyScoreCard(score: dailyVibe.energyScore)
                    
                    // OOTD Card
                    OOTDCard(outfit: dailyVibe.ootd)
                    
                    // Advice Card
                    AdviceCard(advice: dailyVibe.advice)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Daily Vibe")
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: appState.currentUser?.energyDNA?.colorHex ?? "#4A4E69").opacity(0.1),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning ☀️"
        } else if hour < 18 {
            return "Good Afternoon 🌤️"
        } else {
            return "Good Evening 🌙"
        }
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Daily Vibe Model
struct DailyVibe {
    let energyScore: Int
    let ootd: Outfit
    let advice: String
}

struct Outfit {
    let color: String
    let style: String
    let emoji: String
}

func generateDailyVibe() -> DailyVibe {
    // Mock logic: Random for MVP
    let energyScores = [45, 67, 89, 92, 34, 78, 88, 95]
    let outfits = [
        Outfit(color: "Purple", style: "Mystical Vibes", emoji: "🔮"),
        Outfit(color: "Gold", style: "Power Player", emoji: "👑"),
        Outfit(color: "Black", style: "Shadow Mode", emoji: "🖤"),
        Outfit(color: "White", style: "Angel Energy", emoji: "🤍"),
        Outfit(color: "Red", style: "Fire Starter", emoji: "🔥")
    ]
    let advices = [
        "Today is not the day to check your ex's Instagram.",
        "Mercury is in retrograde. Blame everything on that.",
        "Your vibe is immaculate. Don't let anyone dull it.",
        "Chaos is calling. Answer with grace (or don't).",
        "You're a masterpiece. Act like it."
    ]
    
    return DailyVibe(
        energyScore: energyScores.randomElement()!,
        ootd: outfits.randomElement()!,
        advice: advices.randomElement()!
    )
}

// MARK: - Card Components

struct EnergyScoreCard: View {
    let score: Int
    
    var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Energy Score")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: score)
                
                VStack(spacing: 4) {
                    Text("\(score)%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text(scoreEmoji(for: score))
                        .font(.title)
                }
            }
            
            Text(scoreMessage(for: score))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: scoreColor.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
    
    private func scoreEmoji(for score: Int) -> String {
        if score >= 80 { return "🚀" }
        if score >= 50 { return "😌" }
        return "😴"
    }
    
    private func scoreMessage(for score: Int) -> String {
        if score >= 80 { return "You're unstoppable today!" }
        if score >= 50 { return "Solid vibes, keep it steady." }
        return "Low energy. Self-care mode activated."
    }
}

struct OOTDCard: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👗 OOTD (Outfit of the Day)")
                    .font(.headline)
                Spacer()
                Text(outfit.emoji)
                    .font(.title)
            }
            
            HStack(spacing: 16) {
                Circle()
                    .fill(colorFromName(outfit.color))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.color)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(outfit.style)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [colorFromName(outfit.color).opacity(0.2), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
    
    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "purple": return .purple
        case "gold": return .yellow
        case "black": return .black
        case "white": return Color(.systemGray6)
        case "red": return .red
        default: return .blue
        }
    }
}

struct AdviceCard: View {
    let advice: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💬 Today's Wisdom")
                    .font(.headline)
                Spacer()
            }
            
            Text("\"\(advice)\"")
                .font(.title3)
                .fontWeight(.medium)
                .italic()
                .lineSpacing(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.2), Color.pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}
