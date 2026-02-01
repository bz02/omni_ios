import SwiftUI
import PhotosUI

struct ViralHubView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Go Viral 🚀")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Pet Psychic Card
                    NavigationLink(destination: PetPsychicView()) {
                        ViralFeatureCard(
                            icon: "🔮",
                            title: "Pet Psychic",
                            subtitle: "What is your pet really thinking?",
                            gradientColors: [.purple, .pink]
                        )
                    }
                    
                    // The Roast Card
                    NavigationLink(destination: TheRoastView()) {
                        ViralFeatureCard(
                            icon: "🔥",
                            title: "The Roast",
                            subtitle: "Why are you still single?",
                            gradientColors: [.orange, .red]
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct ViralFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 48))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors.map { $0.opacity(0.2) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Pet Psychic View
struct PetPsychicView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingResult = false
    @State private var reading: PetReading?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Pet Psychic 🔮")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Upload your pet's photo and discover their inner thoughts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Image Preview
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 250, height: 250)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("Tap to select photo")
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Text("Choose Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                }
                
                if selectedImage != nil {
                    Button(action: {
                        reading = generatePetReading()
                        showingResult = true
                    }) {
                        Text("Get Reading 🔮")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingResult) {
            if let reading = reading {
                PetReadingResultView(reading: reading)
            }
        }
    }
}

struct PetReading {
    let mood: String
    let personality: String
    let roast: String
    let emoji: String
}

func generatePetReading() -> PetReading {
    let readings = [
        PetReading(
            mood: "Judging You Hard",
            personality: "Professional Disappointment",
            roast: "Your pet simply tolerates you for the food. That's it. That's the relationship.",
            emoji: "😒"
        ),
        PetReading(
            mood: "Plotting World Domination",
            personality: "Evil Mastermind",
            roast: "Behind those innocent eyes is a strategic genius planning your downfall.",
            emoji: "😈"
        ),
        PetReading(
            mood: "Blissfully Stupid",
            personality: "Not a thought behind those eyes",
            roast: "There's absolutely nothing going on in that head. And honestly? Living their best life.",
            emoji: "🤪"
        ),
        PetReading(
            mood: "Main Character Energy",
            personality: "The Star of the Show",
            roast: "You're not the main character in this story. Your pet is. Accept it.",
            emoji: "⭐️"
        )
    ]
    
    return readings.randomElement()!
}

struct PetReadingResultView: View {
    let reading: PetReading
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text(reading.emoji)
                        .font(.system(size: 100))
                        .padding()
                    
                    VStack(spacing: 8) {
                        Text("Current Mood")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(reading.mood)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        Text("Personality Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(reading.personality)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        Text("The Truth")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\"\(reading.roast)\"")
                            .font(.title3)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        // Share functionality would go here
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share This Roast")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Pet Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - The Roast View
struct TheRoastView: View {
    @State private var selectedZodiac = "Aries"
    @State private var showingResult = false
    @State private var roastResult: RoastResult?
    
    let zodiacSigns = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                       "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("The Roast 🔥")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Based on your cosmic energy, let's find out why you're still single")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Your Zodiac Sign")
                    .font(.headline)
                
                Picker("Zodiac Sign", selection: $selectedZodiac) {
                    ForEach(zodiacSigns, id: \.self) { sign in
                        Text(sign).tag(sign)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            
            Spacer()
            
            Button(action: {
                roastResult = generateRoast(zodiac: selectedZodiac)
                showingResult = true
            }) {
                Text("Roast Me 🔥")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
            .padding()
        }
        .padding()
        .sheet(isPresented: $showingResult) {
            if let result = roastResult {
                RoastResultView(result: result)
            }
        }
    }
}

struct RoastResult {
    let title: String
    let reason: String
    let advice: String
    let emoji: String
}

func generateRoast(zodiac: String) -> RoastResult {
    let roasts: [String: RoastResult] = [
        "Aries": RoastResult(
            title: "Too Hot to Handle (Literally)",
            reason: "You're so intense, people need a fire extinguisher just to date you. Your energy is intimidating, and not in a sexy way.",
            advice: "Chill. Like, genuinely. Try yoga or something.",
            emoji: "🔥"
        ),
        "Taurus": RoastResult(
            title: "Stubbornness Level: Expert",
            reason: "You refuse to compromise on anything. Your standards are so high, even you can't reach them.",
            advice: "Maybe lower the bar just a little? Like 1%?",
            emoji: "🐂"
        ),
        "Gemini": RoastResult(
            title: "Double Personality Disorder",
            reason: "Nobody knows which version of you will show up on a date. It's exhausting.",
            advice: "Pick a personality and stick with it for at least 24 hours.",
            emoji: "👯"
        ),
        "Cancer": RoastResult(
            title: "Too Many Feelings",
            reason: "You cry at Netflix commercials. Potential partners are scared they'll break you.",
            advice: "Build some emotional walls. Not too many, but like... a fence.",
            emoji: "🦀"
        ),
        "Leo": RoastResult(
            title: "Main Character Syndrome",
            reason: "You need constant validation and the spotlight. Relationships require... other people existing too.",
            advice: "Learn to share the stage. Or at least pretend to care about their day.",
            emoji: "🦁"
        ),
        "Virgo": RoastResult(
            title: "Perfectionist Nightmare",
            reason: "You'll critique their grammar on dating apps. Nothing is ever good enough for you.",
            advice: "Accept that humans are flawed. Even you (gasp!).",
            emoji: "✨"
        )
    ]
    
    return roasts[zodiac] ?? RoastResult(
        title: "Cosmic Chaos Energy",
        reason: "The stars literally have no idea what you're doing. That's how single you are.",
        advice: "Maybe ask the universe for help? Or therapy.",
        emoji: "⭐️"
    )
}

struct RoastResultView: View {
    let result: RoastResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text(result.emoji)
                        .font(.system(size: 100))
                        .padding()
                    
                    Text("Why You're Single:")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(result.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("The Reason:")
                                .font(.headline)
                            Text(result.reason)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("The Advice:")
                                .font(.headline)
                            Text(result.advice)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    Button(action: {
                        // Share functionality
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share This Roast")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Your Roast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
