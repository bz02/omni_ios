import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var chatVM = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(chatVM.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatVM.messages.count) { _ in
                        if let lastMessage = chatVM.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Chat Limit Indicator
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(chatVM.remainingMessages > 0 ? .green : .red)
                    Text("\(chatVM.remainingMessages)/3 messages left today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Input Bar
                HStack(spacing: 12) {
                    TextField("Ask Omni anything...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .lineLimit(1...4)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty || chatVM.remainingMessages == 0 ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || chatVM.remainingMessages == 0)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Omni Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        chatVM.resetChat()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .onAppear {
            if chatVM.messages.isEmpty {
                chatVM.addWelcomeMessage()
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, chatVM.remainingMessages > 0 else { return }
        
        let userMessage = messageText
        messageText = ""
        isInputFocused = false
        
        chatVM.sendMessage(userMessage)
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Chat ViewModel
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var remainingMessages: Int = 3
    
    private let responsesEastern = [
        "The stars suggest patience. Mercury is in retrograde after all.",
        "Your energy is blocked in the solar plexus chakra. Try some breathwork.",
        "According to your birth chart, this week favors introspection over action.",
        "The universe is testing you. This too shall pass.",
        "Consider the wisdom of yin and yang. Balance is key."
    ]
    
    private let responsesWestern = [
        "Based on psychological patterns, you might be overthinking this.",
        "Research shows that taking breaks improves decision-making by 40%.",
        "Have you considered the logical approach? Make a pros and cons list.",
        "Sometimes the answer is simpler than we think.",
        "Trust your gut, but verify with data."
    ]
    
    private let responsesSassy = [
        "Bestie, you already know the answer. Stop procrastinating.",
        "Plot twist: the problem is you. (Said with love.)",
        "Are we really doing this again? You asked me this yesterday.",
        "The audacity. I love it. But also, no.",
        "You're giving chaos energy and I'm here for it."
    ]
    
    func addWelcomeMessage() {
        messages.append(ChatMessage(
            content: "Welcome to Omni Chat! 🔮\n\nI blend Eastern wisdom and Western logic to help guide you. You have 3 free messages today. Make them count!",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    func sendMessage(_ text: String) {
        guard remainingMessages > 0 else { return }
        
        // Add user message
        messages.append(ChatMessage(
            content: text,
            isUser: true,
            timestamp: Date()
        ))
        
        remainingMessages -= 1
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let response = self.generateResponse(for: text)
            self.messages.append(ChatMessage(
                content: response,
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    func resetChat() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    private func generateResponse(for input: String) -> String {
        let allResponses = responsesEastern + responsesWestern + responsesSassy
        
        // Simple keyword matching for MVP
        let lowercased = input.lowercased()
        
        if lowercased.contains("love") || lowercased.contains("relationship") {
            return ["Venus is entering your 7th house. Love is on the horizon... eventually.",
                    "Relationships require vulnerability. Are you ready for that?",
                    "Your attachment style might be getting in the way. Consider therapy."].randomElement()!
        } else if lowercased.contains("work") || lowercased.contains("career") {
            return ["Your career path is aligned with Saturn's discipline. Keep grinding.",
                    "Job satisfaction comes from purpose, not just paychecks.",
                    "You're undervaluing yourself. Ask for that raise."].randomElement()!
        } else if lowercased.contains("tired") || lowercased.contains("exhausted") {
            return ["Your root chakra needs grounding. Try walking barefoot on grass.",
                    "Burnout is real. Rest is productive.",
                    "Sleep deprivation is not a flex. Go to bed."].randomElement()!
        }
        
        return allResponses.randomElement()!
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("🔮")
                            .font(.caption)
                    )
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser
                                  ? Color.blue
                                  : Color(.systemGray5))
                    )
                    .foregroundColor(message.isUser ? .white : .primary)
                
                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.isUser {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("👤")
                            .font(.caption)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
