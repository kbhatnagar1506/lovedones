//
//  HackathonWinningDashboard.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//  PRODUCTION-READY INTERACTIVE DASHBOARD
//

import SwiftUI
import Combine

// MARK: - Emergency Call Response Models
struct EmergencyCallResponse: Codable {
    let success: Bool
    let message: String?
    let location: LocationData?
    let call_results: [CallResult]?
    let successful_calls: Int?
    let total_contacts: Int?
    let emergency_phone: String?
}

struct LocationData: Codable {
    let address: String
    let latitude: Double
    let longitude: Double
    let timestamp: String
}

struct CallResult: Codable {
    let contact: FamilyContactData
    let call_result: CallData?
    let success: Bool
}

struct FamilyContactData: Codable {
    let name: String
    let phone: String
    let relationship: String
    let priority: Int
    let last_called: String?
    let call_count: Int
}

struct CallData: Codable {
    let id: String?
    let status: String?
}

// MARK: - 📊 DASHBOARD DATA MODELS
class DashboardData: ObservableObject {
    @Published var currentUser: DashboardUser = DashboardUser.sample
    @Published var activities: [DashboardActivity] = DashboardActivity.sampleData
    @Published var goals: [DashboardGoal] = DashboardGoal.sampleData
    @Published var cognitiveHealth: DashboardCognitiveHealth = DashboardCognitiveHealth.sample
    @Published var safetyStatus: DashboardSafetyStatus = DashboardSafetyStatus.sample
    @Published var notifications: [DashboardNotification] = DashboardNotification.sampleData
    @Published var cognitiveChallenges: [CognitiveChallenge] = CognitiveChallenge.sampleData
    @Published var currentChallenge: CognitiveChallenge?
    @Published var challengeProgress: ChallengeProgress = ChallengeProgress()
    
    func addMemory() {
        // Add memory functionality
    }
    
    func completeGoal(_ goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].isCompleted = true
        }
    }
    
    func startCognitiveChallenge(_ challenge: CognitiveChallenge) {
        currentChallenge = challenge
        challengeProgress.currentChallenge = challenge
        challengeProgress.startTime = Date()
    }
    
    func completeChallenge(score: Int, timeSpent: TimeInterval) {
        guard let challenge = currentChallenge else { return }
        
        challengeProgress.completeChallenge(score: score, timeSpent: timeSpent)
        
        // Update cognitive health based on performance
        updateCognitiveHealth(score: score, challengeType: challenge.type)
        
        // Add activity
        let activity = DashboardActivity(
            title: "Completed \(challenge.title)",
            subtitle: "Score: \(score)/\(challenge.maxScore)",
            timestamp: Date(),
            icon: challenge.icon,
            color: score >= Int(Double(challenge.maxScore) * 0.8) ? "successGreen" : "warningOrange"
        )
        activities.insert(activity, at: 0)
        
        currentChallenge = nil
    }
    
    private func updateCognitiveHealth(score: Int, challengeType: CognitiveChallengeType) {
        let performance = Double(score) / Double(challengeType.maxScore)
        let scoreIncrease = Int(performance * 10)
        
        switch challengeType {
        case .memory:
            cognitiveHealth.memoryScore = min(100, cognitiveHealth.memoryScore + scoreIncrease)
        case .attention:
            cognitiveHealth.attentionScore = min(100, cognitiveHealth.attentionScore + scoreIncrease)
        case .processing:
            cognitiveHealth.processingScore = min(100, cognitiveHealth.processingScore + scoreIncrease)
        case .language:
            cognitiveHealth.languageScore = min(100, cognitiveHealth.languageScore + scoreIncrease)
        case .executive:
            cognitiveHealth.executiveScore = min(100, cognitiveHealth.executiveScore + scoreIncrease)
        case .whosWho:
            cognitiveHealth.memoryScore = min(100, cognitiveHealth.memoryScore + scoreIncrease)
        }
        
        // Update overall cognitive health
        let totalScore = (cognitiveHealth.memoryScore + cognitiveHealth.attentionScore + 
                         cognitiveHealth.processingScore + cognitiveHealth.languageScore + 
                         cognitiveHealth.executiveScore) / 5
        cognitiveHealth.overallScore = totalScore
    }
}

struct DashboardUser: Identifiable, Codable {
    let id = UUID()
    let name: String
    let profileImage: String?
    let lastSeen: Date
    
    static let sample = DashboardUser(name: "David", profileImage: nil, lastSeen: Date())
}

// MARK: - 🧠 COGNITIVE CHALLENGE MODELS
enum CognitiveChallengeType: String, CaseIterable, Codable {
    case memory = "Memory"
    case attention = "Attention"
    case processing = "Processing Speed"
    case language = "Language"
    case executive = "Executive Function"
    case whosWho = "Who's Who"
    
    var maxScore: Int {
        switch self {
        case .memory: return 10
        case .attention: return 15
        case .processing: return 20
        case .language: return 12
        case .executive: return 18
        case .whosWho: return 12
        }
    }
    
    var icon: String {
        switch self {
        case .memory: return "brain.head.profile"
        case .attention: return "eye.fill"
        case .processing: return "speedometer"
        case .language: return "text.bubble.fill"
        case .executive: return "gearshape.fill"
        case .whosWho: return "person.2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .memory: return "primaryBlue"
        case .attention: return "primaryGreen"
        case .processing: return "primaryOrange"
        case .language: return "primaryPurple"
        case .executive: return "primaryRed"
        case .whosWho: return "primaryPink"
        }
    }
}

struct CognitiveChallenge: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let type: CognitiveChallengeType
    let difficulty: ChallengeDifficulty
    let questions: [ChallengeQuestion]
    let maxScore: Int
    let estimatedTime: TimeInterval // in seconds
    let icon: String
    let color: String
    
    static let sampleData = [
        CognitiveChallenge(
            title: "Memory Lane Quiz",
            description: "Test your memory with family photos and stories",
            type: .memory,
            difficulty: .medium,
            questions: MemoryChallengeQuestions.sampleQuestions,
            maxScore: 10,
            estimatedTime: 300,
            icon: "photo.fill",
            color: "primaryBlue"
        ),
        CognitiveChallenge(
            title: "Who's Who Family Quiz",
            description: "Identify family members in David's photos",
            type: .whosWho,
            difficulty: .easy,
            questions: WhosWhoChallengeQuestions.sampleQuestions,
            maxScore: 12,
            estimatedTime: 240,
            icon: "person.2.fill",
            color: "primaryPink"
        ),
        CognitiveChallenge(
            title: "Attention Focus Test",
            description: "Find hidden objects in busy scenes",
            type: .attention,
            difficulty: .hard,
            questions: AttentionChallengeQuestions.sampleQuestions,
            maxScore: 15,
            estimatedTime: 240,
            icon: "magnifyingglass",
            color: "primaryGreen"
        ),
        CognitiveChallenge(
            title: "Speed Processing",
            description: "Quick decision making under time pressure",
            type: .processing,
            difficulty: .easy,
            questions: ProcessingChallengeQuestions.sampleQuestions,
            maxScore: 20,
            estimatedTime: 180,
            icon: "timer",
            color: "primaryOrange"
        ),
        CognitiveChallenge(
            title: "Language Comprehension",
            description: "Read and understand family stories",
            type: .language,
            difficulty: .medium,
            questions: LanguageChallengeQuestions.sampleQuestions,
            maxScore: 12,
            estimatedTime: 360,
            icon: "book.fill",
            color: "primaryPurple"
        ),
        CognitiveChallenge(
            title: "Executive Planning",
            description: "Organize daily activities and solve problems",
            type: .executive,
            difficulty: .hard,
            questions: ExecutiveChallengeQuestions.sampleQuestions,
            maxScore: 18,
            estimatedTime: 420,
            icon: "list.bullet.rectangle",
            color: "primaryRed"
        )
    ]
}

enum ChallengeDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var multiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }
}

struct ChallengeQuestion: Identifiable, Codable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
    let timeLimit: TimeInterval
    let points: Int
}

struct ChallengeProgress: Codable {
    var currentChallenge: CognitiveChallenge?
    var startTime: Date?
    var currentQuestionIndex: Int = 0
    var score: Int = 0
    var completedChallenges: [UUID] = []
    var totalTimeSpent: TimeInterval = 0
    
    mutating func completeChallenge(score: Int, timeSpent: TimeInterval) {
        if let challenge = currentChallenge {
            completedChallenges.append(challenge.id)
            self.score = score
            totalTimeSpent += timeSpent
        }
        currentChallenge = nil
        startTime = nil
        currentQuestionIndex = 0
    }
}

// MARK: - 🧠 COGNITIVE CHALLENGE QUESTIONS
struct MemoryChallengeQuestions {
    static let sampleQuestions = [
        ChallengeQuestion(
            question: "Look at this family photo. What was the name of David's wife?",
            options: ["Sarah", "Emma", "Mary", "Lisa"],
            correctAnswer: 0,
            explanation: "David's wife was Sarah. They were married for 35 years and had many precious memories together.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "In the park picnic photo, how many grandchildren are with David?",
            options: ["1", "2", "3", "4"],
            correctAnswer: 1,
            explanation: "David has 2 grandchildren: Tommy and Emma. They loved going to Riverside Park for picnics together.",
            timeLimit: 25,
            points: 2
        ),
        ChallengeQuestion(
            question: "What activity is David doing with Tommy in the living room photo?",
            options: ["Reading stories", "Building blocks", "Playing cards", "Watching TV"],
            correctAnswer: 1,
            explanation: "David loved building blocks with Tommy. They would spend hours creating towers and train tracks together on the living room floor.",
            timeLimit: 30,
            points: 3
        ),
        ChallengeQuestion(
            question: "In the wedding photo, how old was David when he married Sarah?",
            options: ["25", "30", "32", "35"],
            correctAnswer: 2,
            explanation: "David was 32 years old when he married Sarah in 1985. She was 23 years old at the time.",
            timeLimit: 25,
            points: 2
        ),
        ChallengeQuestion(
            question: "What did Tommy surprise David with in the driveway photo?",
            options: ["A new watch", "A Tesla car", "A fishing rod", "A garden tool"],
            correctAnswer: 1,
            explanation: "Tommy surprised David with a dark blue Tesla car with a big red bow. It was a gesture of love and gratitude.",
            timeLimit: 30,
            points: 3
        ),
        ChallengeQuestion(
            question: "In the family dinner photo, what color shirt is David wearing?",
            options: ["White", "Blue plaid", "Green", "Black"],
            correctAnswer: 1,
            explanation: "David is wearing his blue plaid shirt in the family dinner photo. This was their Sunday evening tradition.",
            timeLimit: 25,
            points: 2
        ),
        ChallengeQuestion(
            question: "What was Sarah wearing in her 60th birthday photo?",
            options: ["Red dress", "Blue dress", "Green dress", "White dress"],
            correctAnswer: 1,
            explanation: "Sarah was wearing a blue dress for her 60th birthday. This was her last birthday celebration with the family.",
            timeLimit: 30,
            points: 3
        ),
        ChallengeQuestion(
            question: "In the graduation photo, what is Tommy holding?",
            options: ["A trophy", "A diploma", "A certificate", "A medal"],
            correctAnswer: 1,
            explanation: "Tommy is holding his college diploma in the graduation photo. David was so proud of his grandson's achievement.",
            timeLimit: 25,
            points: 2
        ),
        ChallengeQuestion(
            question: "What was the name of the park where David and Sarah had their favorite bench?",
            options: ["Central Park", "Riverside Park", "Maple Park", "Oak Park"],
            correctAnswer: 1,
            explanation: "David and Sarah had their favorite bench at Riverside Park. They would sit there every afternoon holding hands.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "In the bedtime story photo, what is Emma holding?",
            options: ["A doll", "A teddy bear", "A book", "A blanket"],
            correctAnswer: 1,
            explanation: "Emma is holding her teddy bear in the bedtime story photo. David would read her stories every night.",
            timeLimit: 25,
            points: 2
        )
    ]
}

struct AttentionChallengeQuestions {
    static let sampleQuestions = [
        ChallengeQuestion(
            question: "Look at the family dinner photo. How many people are wearing blue?",
            options: ["2", "3", "4", "5"],
            correctAnswer: 1,
            explanation: "Three people are wearing blue in the family dinner photo. Look carefully at each person's clothing.",
            timeLimit: 45,
            points: 3
        ),
        ChallengeQuestion(
            question: "In the park picnic photo, what color is the blanket?",
            options: ["Red and white checkered", "Blue and white striped", "Green and yellow", "Purple and pink"],
            correctAnswer: 0,
            explanation: "The blanket is red and white checkered. Sarah packed it for their picnic at Riverside Park.",
            timeLimit: 45,
            points: 3
        ),
        ChallengeQuestion(
            question: "Count the number of blocks visible in the building photo",
            options: ["15", "20", "25", "30"],
            correctAnswer: 2,
            explanation: "There are 25 blocks visible in the building photo. Tommy and David used them to build towers.",
            timeLimit: 45,
            points: 3
        ),
        ChallengeQuestion(
            question: "In the wedding photo, what color are the roses in the archway?",
            options: ["Red", "White", "Pink", "Yellow"],
            correctAnswer: 1,
            explanation: "The roses in the wedding archway are white. David and Sarah stood under this beautiful white rose archway for their first kiss.",
            timeLimit: 45,
            points: 3
        ),
        ChallengeQuestion(
            question: "How many flowers are in the garden?",
            options: ["15", "20", "25", "30"],
            correctAnswer: 2,
            explanation: "There are 25 flowers in the garden. Sarah loved her roses and David grew tomatoes.",
            timeLimit: 45,
            points: 3
        )
    ]
}

struct ProcessingChallengeQuestions {
    static let sampleQuestions = [
        ChallengeQuestion(
            question: "Quick! What comes next: 2, 4, 8, 16, ?",
            options: ["24", "32", "20", "28"],
            correctAnswer: 1,
            explanation: "The pattern is doubling: 2×2=4, 4×2=8, 8×2=16, 16×2=32",
            timeLimit: 15,
            points: 4
        ),
        ChallengeQuestion(
            question: "If it's 3 PM now, what time will it be in 2.5 hours?",
            options: ["5:00 PM", "5:30 PM", "6:00 PM", "6:30 PM"],
            correctAnswer: 1,
            explanation: "3 PM + 2.5 hours = 5:30 PM. Quick mental math!",
            timeLimit: 15,
            points: 4
        ),
        ChallengeQuestion(
            question: "Which word doesn't belong: Apple, Orange, Carrot, Banana",
            options: ["Apple", "Orange", "Carrot", "Banana"],
            correctAnswer: 2,
            explanation: "Carrot is a vegetable, while the others are fruits.",
            timeLimit: 15,
            points: 4
        ),
        ChallengeQuestion(
            question: "What is 7 × 8?",
            options: ["54", "56", "58", "60"],
            correctAnswer: 1,
            explanation: "7 × 8 = 56. Quick multiplication!",
            timeLimit: 15,
            points: 4
        ),
        ChallengeQuestion(
            question: "If today is Tuesday, what day will it be in 3 days?",
            options: ["Thursday", "Friday", "Saturday", "Sunday"],
            correctAnswer: 1,
            explanation: "Tuesday + 3 days = Friday. Quick calendar math!",
            timeLimit: 15,
            points: 4
        )
    ]
}

struct LanguageChallengeQuestions {
    static let sampleQuestions = [
        ChallengeQuestion(
            question: "Read this story: 'David and Sarah went to the park with Tommy and Emma. They had a picnic and played games.' Who went to the park?",
            options: ["David and Sarah", "Tommy and Emma", "All four of them", "Just David"],
            correctAnswer: 2,
            explanation: "All four of them went to the park: David, Sarah, Tommy, and Emma.",
            timeLimit: 60,
            points: 3
        ),
        ChallengeQuestion(
            question: "What does 'nostalgic' mean in this context: 'David felt nostalgic looking at old photos'?",
            options: ["Happy", "Sad", "Wistful about the past", "Angry"],
            correctAnswer: 2,
            explanation: "Nostalgic means feeling wistful or sentimental about the past.",
            timeLimit: 60,
            points: 3
        ),
        ChallengeQuestion(
            question: "Complete this sentence: 'The family gathered around the dinner table to...'",
            options: ["watch TV", "eat dinner", "play games", "read books"],
            correctAnswer: 1,
            explanation: "The family gathered around the dinner table to eat dinner together.",
            timeLimit: 60,
            points: 3
        ),
        ChallengeQuestion(
            question: "What is the main idea of this passage: 'Memory is precious. It connects us to our past and helps us understand who we are.'",
            options: ["Memory is difficult", "Memory is important", "Memory is confusing", "Memory is useless"],
            correctAnswer: 1,
            explanation: "The main idea is that memory is important because it connects us to our past.",
            timeLimit: 60,
            points: 3
        )
    ]
}

struct ExecutiveChallengeQuestions {
    static let sampleQuestions = [
        ChallengeQuestion(
            question: "Plan David's day: He needs to take medicine at 9 AM, have lunch at 12 PM, and visit the doctor at 2 PM. What should he do first?",
            options: ["Take medicine", "Have lunch", "Visit doctor", "It doesn't matter"],
            correctAnswer: 0,
            explanation: "He should take his medicine first at 9 AM, as it's the earliest scheduled activity.",
            timeLimit: 90,
            points: 4
        ),
        ChallengeQuestion(
            question: "David wants to organize his photos. What's the best way to sort them?",
            options: ["By color", "By date", "By size", "Randomly"],
            correctAnswer: 1,
            explanation: "Sorting by date makes it easiest to find specific memories and see the progression of time.",
            timeLimit: 90,
            points: 4
        ),
        ChallengeQuestion(
            question: "If David forgets where he put his keys, what should he do first?",
            options: ["Panic", "Check common places", "Buy new keys", "Ask someone else"],
            correctAnswer: 1,
            explanation: "Check common places first - it's the most logical and efficient approach.",
            timeLimit: 90,
            points: 4
        ),
        ChallengeQuestion(
            question: "David needs to remember to call his daughter. What's the best reminder method?",
            options: ["Just remember", "Set an alarm", "Write a note", "Ask someone to remind him"],
            correctAnswer: 1,
            explanation: "Setting an alarm is the most reliable method to ensure he doesn't forget.",
            timeLimit: 90,
            points: 4
        ),
        ChallengeQuestion(
            question: "David is feeling overwhelmed. What should he do?",
            options: ["Ignore it", "Take a break", "Work harder", "Give up"],
            correctAnswer: 1,
            explanation: "Taking a break is the healthiest way to handle feeling overwhelmed.",
            timeLimit: 90,
            points: 4
        )
    ]
}

struct WhosWhoChallengeQuestions {
    static let sampleQuestions = [
        ChallengeQuestion(
            question: "Look at this family photo. Who is David's wife?",
            options: ["The woman in the blue dress", "The woman in the white dress", "The woman in the green dress", "The woman in the red dress"],
            correctAnswer: 0,
            explanation: "Sarah is David's wife, wearing a blue dress in this family photo.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "In the wedding photo, who is the groom?",
            options: ["The man on the left", "The man on the right", "The man in the middle", "The man in the back"],
            correctAnswer: 0,
            explanation: "David is the groom, standing on the left in the wedding photo.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "Who is Tommy in the graduation photo?",
            options: ["The person in the cap and gown", "The person in the suit", "The person in the casual clothes", "The person in the uniform"],
            correctAnswer: 0,
            explanation: "Tommy is the person wearing the cap and gown in the graduation photo.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "In the park photo, who is Emma?",
            options: ["The girl in the cream sweater", "The girl in the blue shirt", "The girl in the pink dress", "The girl in the green top"],
            correctAnswer: 0,
            explanation: "Emma is the girl wearing the cream sweater in the park picnic photo.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "Who is David in the family portrait?",
            options: ["The man sitting in the middle", "The man standing on the left", "The man standing on the right", "The man in the back"],
            correctAnswer: 0,
            explanation: "David is the man sitting in the middle of the family portrait.",
            timeLimit: 30,
            points: 2
        ),
        ChallengeQuestion(
            question: "In the building blocks photo, who is the child?",
            options: ["Tommy", "Emma", "Sarah", "David"],
            correctAnswer: 0,
            explanation: "Tommy is the child playing with building blocks with David.",
            timeLimit: 30,
            points: 2
        )
    ]
}

struct DashboardActivity: Identifiable, Codable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timestamp: Date
    let icon: String
    let color: String
    
    static let sampleData = [
        DashboardActivity(title: "Added new memory", subtitle: "Family dinner photo", timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(), icon: "photo.fill", color: "primaryRed"),
        DashboardActivity(title: "Completed memory game", subtitle: "Face matching - 95% accuracy", timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(), icon: "brain.head.profile", color: "infoBlue"),
        DashboardActivity(title: "Task completed", subtitle: "Morning routine finished", timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(), icon: "checkmark.circle.fill", color: "successGreen")
    ]
}

struct DashboardTask: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let isCompleted: Bool
    let priority: String
    let dueDate: Date?
    let category: String
    
    static let sampleData = [
        DashboardTask(title: "Morning Routine", description: "Complete daily morning tasks", isCompleted: false, priority: "high", dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()), category: "daily"),
        DashboardTask(title: "Call Family", description: "Check in with loved ones", isCompleted: true, priority: "medium", dueDate: Calendar.current.date(byAdding: .hour, value: -1, to: Date()), category: "social"),
        DashboardTask(title: "Exercise", description: "30 minutes of light activity", isCompleted: false, priority: "medium", dueDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date()), category: "health")
    ]
}

struct DashboardGoal: Identifiable, Codable {
    let id = UUID()
    let title: String
    var isCompleted: Bool
    var progress: Double
    
    static let sampleData = [
        DashboardGoal(title: "Add a memory", isCompleted: true, progress: 1.0),
        DashboardGoal(title: "Play memory game", isCompleted: true, progress: 1.0),
        DashboardGoal(title: "Call family member", isCompleted: true, progress: 1.0),
        DashboardGoal(title: "Take medication", isCompleted: false, progress: 0.0),
        DashboardGoal(title: "Exercise for 15 min", isCompleted: false, progress: 0.0)
    ]
}

struct DashboardCognitiveHealth: Codable {
    let weeklyProgress: Double
    let gamesPlayed: Int
    let memoriesAdded: Int
    let currentStreak: Int
    let dailyScores: [Double]
    var memoryScore: Int
    var attentionScore: Int
    var processingScore: Int
    var languageScore: Int
    var executiveScore: Int
    var overallScore: Int
    
    static let sample = DashboardCognitiveHealth(
        weeklyProgress: 0.85,
        gamesPlayed: 12,
        memoriesAdded: 8,
        currentStreak: 5,
        dailyScores: [0.8, 0.9, 0.7, 0.85, 0.9, 0.8, 0.75],
        memoryScore: 75,
        attentionScore: 80,
        processingScore: 70,
        languageScore: 85,
        executiveScore: 78,
        overallScore: 78
    )
}

struct DashboardSafetyStatus: Codable {
    let isInSafeZone: Bool
    let lastSeen: Date
    let location: String
    
    static let sample = DashboardSafetyStatus(
        isInSafeZone: true,
        lastSeen: Calendar.current.date(byAdding: .minute, value: -2, to: Date()) ?? Date(),
        location: "Home"
    )
}

struct DashboardNotification: Identifiable, Codable {
    let id = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let isRead: Bool
    let type: NotificationType
    
    enum NotificationType: String, CaseIterable, Codable {
        case task = "Task"
        case safety = "Safety"
        case family = "Family"
        case system = "System"
    }
    
    static let sampleData = [
        DashboardNotification(title: "Daily Task", message: "Time for your morning routine", timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(), isRead: false, type: .task),
        DashboardNotification(title: "Family Update", message: "Mom called and left a message", timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(), isRead: false, type: .family),
        DashboardNotification(title: "Safety Check", message: "You're safely at home", timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date(), isRead: true, type: .safety)
    ]
}

// MARK: - 🏆 HACKATHON-WINNING DESIGN SYSTEM
struct LovedOnesDesignSystem {
    // 🎨 PREMIUM COLOR PALETTE
    static let primaryRed = Color(red: 0.89, green: 0.22, blue: 0.27)      // #E63946 - Love & Urgency
    static let secondaryRed = Color(red: 0.95, green: 0.35, blue: 0.40)    // #F25A66 - Softer Love
    static let accentRed = Color(red: 0.98, green: 0.60, blue: 0.65)       // #FA9AA6 - Gentle Love
    static let pureWhite = Color.white                                      // #FFFFFF - Clarity
    static let warmGray = Color(red: 0.97, green: 0.98, blue: 0.98)        // #F8F9FA - Soft Background
    static let lightGray = Color(red: 0.94, green: 0.95, blue: 0.96)       // #F0F1F2 - Card Background
    static let mediumGray = Color(red: 0.85, green: 0.87, blue: 0.89)      // #D9DDE1 - Borders
    static let darkGray = Color(red: 0.45, green: 0.47, blue: 0.49)        // #73777A - Secondary Text
    static let textPrimary = Color(red: 0.15, green: 0.17, blue: 0.19)     // #262A2E - Primary Text
    static let textSecondary = Color(red: 0.45, green: 0.47, blue: 0.49)   // #73777A - Secondary Text
    static let successGreen = Color(red: 0.20, green: 0.70, blue: 0.32)    // #33B352 - Success
    static let warningOrange = Color(red: 0.95, green: 0.60, blue: 0.10)   // #F39C12 - Warning
    static let infoBlue = Color(red: 0.27, green: 0.48, blue: 0.62)        // #457B9D - Information
    static let dangerRed = Color(red: 0.90, green: 0.20, blue: 0.20)       // #E74C3C - Danger
    
    // 📏 PRECISION SPACING SYSTEM
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 16
    static let spaceL: CGFloat = 24
    static let spaceXL: CGFloat = 32
    static let spaceXXL: CGFloat = 48
    static let spaceXXXL: CGFloat = 64
    
    // 🎯 CORNER RADIUS SYSTEM
    static let radiusXS: CGFloat = 4
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusXXL: CGFloat = 24
    static let radiusRound: CGFloat = 50
    
    // ✍️ TYPOGRAPHY SYSTEM
    static let heroFont = Font.system(size: 32, weight: .black, design: .rounded)
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headingFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let subheadingFont = Font.system(size: 18, weight: .medium, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .medium, design: .rounded)
    static let smallFont = Font.system(size: 12, weight: .medium, design: .rounded)
    static let buttonFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    // 🌟 SHADOW SYSTEM
    static let shadowLight = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    static let shadowMedium = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    static let shadowHeavy = (color: Color.black.opacity(0.15), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
    static let shadowGlow = (color: primaryRed.opacity(0.3), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(10))
    static let shadowColor = Color.black.opacity(0.1)
    
    // 🎨 COLOR UTILITIES
    static func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "primaryRed": return primaryRed
        case "infoBlue": return infoBlue
        case "successGreen": return successGreen
        case "warningOrange": return warningOrange
        case "dangerRed": return dangerRed
        case "primaryBlue": return infoBlue
        case "primaryGreen": return successGreen
        case "primaryOrange": return warningOrange
        case "primaryPurple": return Color.purple
        case "primaryPink": return Color.pink
        default: return textPrimary
        }
    }
}

// MARK: - 🏆 PRODUCTION-READY INTERACTIVE DASHBOARD
struct HackathonWinningDashboard: View {
    @StateObject private var dashboardData = DashboardData()
    @State private var showingEmergencyAlert = false
    @State private var showingNotifications = false
    @State private var showingMemoryDetail: Memory?
    @State private var showingTaskDetail: DashboardTask?
    @State private var currentTime = Date()
    @State private var pulseAnimation = false
    @State private var selectedTab = 0
    @State private var showingFaceRecognition = false
    @State private var showingFaceRegistration = false
    @State private var showingRegisteredFaces = false
    @State private var showingAIAssistant = false
    @State private var showingAIChatHistory = false
    @State private var showingMemoryLane = false
    @State private var showingMemoryTimeline = false
    @StateObject private var faceManager = FaceRecognitionManager()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 🌅 BACKGROUND GRADIENT
                LinearGradient(
                    gradient: Gradient(colors: [
                        LovedOnesDesignSystem.warmGray,
                        LovedOnesDesignSystem.pureWhite
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: LovedOnesDesignSystem.spaceL) {
                        // 🏆 HERO SECTION WITH LOGO
                        HeroSectionWithLogo(
                            user: dashboardData.currentUser,
                            showingNotifications: $showingNotifications,
                            showingEmergencyAlert: $showingEmergencyAlert,
                            unreadNotifications: dashboardData.notifications.filter { !$0.isRead }.count
                        )
                        
                        // 🧠 COGNITIVE CHALLENGES SECTION
                        CognitiveChallengesSection(
                            challenges: dashboardData.cognitiveChallenges,
                            onStartChallenge: { challenge in
                                dashboardData.startCognitiveChallenge(challenge)
                            }
                        )
                        
                        // ⚡ QUICK ACTIONS GRID
                        QuickActionsGrid(
                            onAddMemory: { addMemory() },
                            onMemoryGame: { startMemoryGame() },
                            onCallFamily: { callFamily() },
                            onFaceRecognition: { startFaceRecognition() },
                            onTasks: { openTasks() },
                            onWellnessCheck: { startWellnessCheck() }
                        )
                        
                        // 🎯 COMPACT FEATURES GRID
                        CompactFeaturesGrid(
                            onFaceRecognition: { startFaceRecognition() },
                            onRegisterFace: { registerNewFace() },
                            onViewRegistered: { viewRegisteredFaces() },
                            onAIChat: { startAIAssistant() },
                            onViewHistory: { viewAIChatHistory() },
                            onViewMemories: { viewMemoryLane() },
                            onAddMemory: { addMemory() },
                            onViewTimeline: { viewMemoryTimeline() }
                        )
                        
                        // 📊 SMART CARDS SECTION
                        SmartCardsSection(
                            tasks: DashboardTask.sampleData,
                            safetyStatus: dashboardData.safetyStatus,
                            onTaskTap: { task in
                                showingTaskDetail = task
                            },
                            onTaskToggle: { task in
                                toggleTask(task)
                            }
                        )
                        
                        // 🧠 COGNITIVE HEALTH DASHBOARD
                        CognitiveHealthDashboard(
                            cognitiveHealth: dashboardData.cognitiveHealth,
                            onViewDetails: { openCognitiveHealthDetails() }
                        )
                        
                        // 📱 RECENT ACTIVITY FEED
                        RecentActivityFeed(
                            activities: dashboardData.activities,
                            onViewAll: { openActivityFeed() }
                        )
                        
                        // 🎯 DAILY GOALS PROGRESS
                        DailyGoalsProgress(
                            goals: dashboardData.goals,
                            onGoalTap: { goal in
                                completeGoal(goal)
                            }
                        )
                        
                        // 🗺️ HOME MAP VIEW (Clickable)
                        HomeMapView()
                    }
                    .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                    .padding(.vertical, LovedOnesDesignSystem.spaceL)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .onAppear {
                pulseAnimation = true
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(notifications: dashboardData.notifications)
        }
        .sheet(item: $showingMemoryDetail) { memory in
            // Use existing MemoryDetailView from MemoryLaneView
            Text("Memory Detail - \(memory.title)")
        }
        .sheet(item: $showingTaskDetail) { task in
            Text("Task Detail - \(task.title)")
        }
        .sheet(isPresented: $showingFaceRecognition) {
            FaceRecognitionCameraView()
        }
        .sheet(isPresented: $showingFaceRegistration) {
            FaceRegistrationView(faceManager: faceManager)
        }
        .sheet(isPresented: $showingRegisteredFaces) {
            RegisteredFacesView(faceManager: faceManager)
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIAssistantView()
        }
        .sheet(isPresented: $showingAIChatHistory) {
            // Placeholder for AI chat history view
            VStack {
                Text("🤖 AI Chat History")
                    .font(.title)
                    .padding()
                Text("Your conversation history with the AI assistant will appear here.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
        }
        .sheet(isPresented: $showingMemoryLane) {
            MemoryLaneView()
        }
        .sheet(isPresented: $showingMemoryTimeline) {
            // Placeholder for Memory Timeline view
            VStack {
                Text("📸 Memory Timeline")
                    .font(.title)
                    .padding()
                Text("Your memory timeline will appear here.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
        }
        .sheet(item: $dashboardData.currentChallenge) { challenge in
            CognitiveChallengeGameView(dashboardData: dashboardData)
        }
        .alert("🚨 Emergency Support", isPresented: $showingEmergencyAlert) {
            Button("📞 Call 911", role: .destructive) {
                callEmergency()
            }
            Button("👨‍👩‍👧‍👦 Call Family") {
                callFamily()
            }
            Button("❌ Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to get help right now:")
        }
    }
    
    // MARK: - 🎯 INTERACTIVE FUNCTIONS
    private func addMemory() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Show memory lane to add new memory
        showingMemoryLane = true
    }
    
    private func startMemoryGame() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Start a cognitive challenge (memory game)
        if let memoryChallenge = dashboardData.cognitiveChallenges.first(where: { $0.type == .memory }) {
            dashboardData.startCognitiveChallenge(memoryChallenge)
        }
    }
    
    private func callFamily() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Call the emergency server to contact the emergency number
        Task {
            do {
                let result = try await callEmergencyServer()
                await MainActor.run {
                    if result.success {
                        print("🚨 Emergency call initiated!")
                        print("📞 Calling: \(result.emergency_phone ?? "Unknown")")
                        
                        // Show success alert
                        let alert = UIAlertController(
                            title: "Emergency Call Sent",
                            message: "Emergency call initiated to \(result.emergency_phone ?? "emergency contact") with your location",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(alert, animated: true)
                        }
                    } else {
                        print("❌ Emergency call failed: \(result.message ?? "Unknown error")")
                        // Don't show error alert - just log the issue
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error calling emergency server: \(error.localizedDescription)")
                    // Don't show error alert - just log the issue
                }
            }
        }
    }
    
    private func callEmergencyServer() async throws -> EmergencyCallResponse {
        guard let url = URL(string: "https://lovedones-emergency-calling-6db36c5e88ab.herokuapp.com/emergency-call") else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send empty JSON object as expected by the server
        let emptyData = "{}".data(using: .utf8)!
        request.httpBody = emptyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(EmergencyCallResponse.self, from: data)
    }
    
    private func startFaceRecognition() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show face recognition camera
        showingFaceRecognition = true
    }
    
    private func openTasks() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show tasks in a sheet
        let alert = UIAlertController(title: "Daily Tasks", message: "Here are your tasks for today", preferredStyle: .alert)
        
        let tasks = DashboardTask.sampleData
        for task in tasks.prefix(3) {
            alert.addAction(UIAlertAction(title: "\(task.isCompleted ? "✓" : "○") \(task.title)", style: .default) { _ in
                self.toggleTask(task)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func startWellnessCheck() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show wellness check questions
        let alert = UIAlertController(title: "Wellness Check", message: "How are you feeling today?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "😊 Great!", style: .default) { _ in
            self.updateWellnessStatus("Great")
        })
        
        alert.addAction(UIAlertAction(title: "😐 Okay", style: .default) { _ in
            self.updateWellnessStatus("Okay")
        })
        
        alert.addAction(UIAlertAction(title: "😔 Not well", style: .default) { _ in
            self.updateWellnessStatus("Not well")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func updateWellnessStatus(_ status: String) {
        // Update wellness status in dashboard data
        dashboardData.safetyStatus = DashboardSafetyStatus(
            isInSafeZone: status == "Great" || status == "Okay",
            lastSeen: Date(),
            location: "Home"
        )
        
        // Add activity
        let activity = DashboardActivity(
            title: "Wellness Check Completed",
            subtitle: "Status: \(status)",
            timestamp: Date(),
            icon: "heart.fill",
            color: status == "Great" ? "successGreen" : status == "Okay" ? "warningOrange" : "dangerRed"
        )
        dashboardData.activities.insert(activity, at: 0)
    }
    
    private func toggleTask(_ task: DashboardTask) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Toggle task completion - this would need to be implemented
        // in the actual task system
        print("Toggled task: \(task.title)")
    }
    
    private func openCognitiveHealthDetails() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        // Navigate to cognitive health details
    }
    
    private func openActivityFeed() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        // Navigate to activity feed
    }
    
    private func completeGoal(_ goal: DashboardGoal) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dashboardData.completeGoal(goal.id)
    }
    
    private func callEmergency() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Face Recognition Functions
    private func registerNewFace() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingFaceRegistration = true
    }
    
    private func viewRegisteredFaces() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingRegisteredFaces = true
    }
    
    // MARK: - AI Assistant Functions
    private func startAIAssistant() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingAIAssistant = true
    }
    
    private func viewAIChatHistory() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingAIChatHistory = true
    }
    
    // MARK: - Memory Lane Functions
    private func viewMemoryLane() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingMemoryLane = true
    }
    
    private func viewMemoryTimeline() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingMemoryTimeline = true
    }
}

// MARK: - 🏆 HERO SECTION WITH LOGO
struct HeroSectionWithLogo: View {
    let user: DashboardUser
    @Binding var showingNotifications: Bool
    @Binding var showingEmergencyAlert: Bool
    let unreadNotifications: Int
    
    @State private var greetingAnimation = false
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            // 🏆 TOP BAR WITH NOTIFICATIONS
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(LovedOnesDesignSystem.subheadingFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .opacity(greetingAnimation ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: greetingAnimation)
                    
                    Text("Welcome back, \(user.name)")
                        .font(LovedOnesDesignSystem.titleFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .opacity(greetingAnimation ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(0.7), value: greetingAnimation)
                }
                
                Spacer()
                
                HStack(spacing: LovedOnesDesignSystem.spaceM) {
                    // 🚨 SOS BUTTON (MOVED TO LEFT)
                    Button(action: {
                        showingEmergencyAlert = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            LovedOnesDesignSystem.primaryRed,
                                            LovedOnesDesignSystem.dangerRed
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .shadow(
                                    color: LovedOnesDesignSystem.primaryRed.opacity(0.3),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                    .accessibilityLabel("Emergency SOS")
                    .accessibilityHint("Double tap to call for emergency help")
                    
                    // 🔔 NOTIFICATIONS BUTTON
                    Button(action: {
                        showingNotifications = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(LovedOnesDesignSystem.lightGray)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(LovedOnesDesignSystem.primaryRed)
                            
                            // Notification badge
                            if unreadNotifications > 0 {
                                Circle()
                                    .fill(LovedOnesDesignSystem.dangerRed)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text("\(unreadNotifications)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 15, y: -15)
                            }
                        }
                    }
                    .accessibilityLabel("Notifications")
                    .accessibilityValue("\(unreadNotifications) new notifications")
                    
                }
            }
            
            // 🏆 LOVEDONES LOGO CARD
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                HStack {
                    // Logo
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remembering for two, caring as one")
                            .font(LovedOnesDesignSystem.captionFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                    
                    Spacer()
                }
                
                // Daily Memory Spotlight
                DailyMemorySpotlightCard()
            }
            .padding(LovedOnesDesignSystem.spaceL)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusXL)
                    .fill(LovedOnesDesignSystem.pureWhite)
                    .shadow(color: LovedOnesDesignSystem.shadowMedium.color, 
                           radius: LovedOnesDesignSystem.shadowMedium.radius, 
                           x: LovedOnesDesignSystem.shadowMedium.x, 
                           y: LovedOnesDesignSystem.shadowMedium.y)
            )
        }
        .onAppear {
            greetingAnimation = true
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
}

// MARK: - 📸 DAILY MEMORY SPOTLIGHT CARD
struct DailyMemorySpotlightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Today's Memory")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to memories
                }
                .font(LovedOnesDesignSystem.captionFont)
                .foregroundColor(LovedOnesDesignSystem.primaryRed)
            }
            
            HStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Memory Photo
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                LovedOnesDesignSystem.accentRed,
                                LovedOnesDesignSystem.secondaryRed
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Dinner at Grandma's")
                        .font(LovedOnesDesignSystem.subheadingFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .lineLimit(2)
                    
                    Text("Everyone was laughing and sharing stories about the old days")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .lineLimit(3)
                    
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                            .font(.caption)
                        
                        Text("2 hours ago")
                            .font(LovedOnesDesignSystem.smallFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 🚨 EMERGENCY SOS BUTTON
struct EmergencySOSButton: View {
    @Binding var showingAlert: Bool
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                showingAlert = true
            }
        }) {
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                LovedOnesDesignSystem.dangerRed.opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 15)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.8 : 0.4)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                LovedOnesDesignSystem.dangerRed,
                                LovedOnesDesignSystem.dangerRed.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(
                        color: LovedOnesDesignSystem.dangerRed.opacity(0.5),
                        radius: isPressed ? 8 : 20,
                        x: 0,
                        y: isPressed ? 4 : 10
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // SOS Text
                VStack(spacing: 4) {
                    Text("SOS")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
        }
        .accessibilityLabel("Emergency SOS button")
        .accessibilityHint("Double tap to call for emergency help")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - ⚡ QUICK ACTIONS GRID
struct QuickActionsGrid: View {
    let onAddMemory: () -> Void
    let onMemoryGame: () -> Void
    let onCallFamily: () -> Void
    let onFaceRecognition: () -> Void
    let onTasks: () -> Void
    let onWellnessCheck: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Quick Actions")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: LovedOnesDesignSystem.spaceM), count: 3), spacing: LovedOnesDesignSystem.spaceM) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Add Memory",
                    subtitle: "Capture a moment",
                    color: LovedOnesDesignSystem.primaryRed,
                    action: onAddMemory
                )
                
                QuickActionCard(
                    icon: "brain.head.profile",
                    title: "Memory Game",
                    subtitle: "Exercise your mind",
                    color: LovedOnesDesignSystem.infoBlue,
                    action: onMemoryGame
                )
                
                QuickActionCard(
                    icon: "person.2.fill",
                    title: "Call Family",
                    subtitle: "Stay connected",
                    color: LovedOnesDesignSystem.successGreen,
                    action: onCallFamily
                )
                
                QuickActionCard(
                    icon: "camera.fill",
                    title: "Face Recognition",
                    subtitle: "Who's this?",
                    color: LovedOnesDesignSystem.warningOrange,
                    action: onFaceRecognition
                )
                
                QuickActionCard(
                    icon: "checklist",
                    title: "Tasks",
                    subtitle: "Stay organized",
                    color: LovedOnesDesignSystem.secondaryRed,
                    action: onTasks
                )
                
                QuickActionCard(
                    icon: "heart.text.square.fill",
                    title: "Wellness Check",
                    subtitle: "How are you?",
                    color: LovedOnesDesignSystem.accentRed,
                    action: onWellnessCheck
                )
            }
        }
    }
}

// MARK: - 🎯 QUICK ACTION CARD
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(LovedOnesDesignSystem.smallFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(LovedOnesDesignSystem.spaceM)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                    .fill(LovedOnesDesignSystem.pureWhite)
                    .shadow(color: LovedOnesDesignSystem.shadowLight.color, 
                           radius: LovedOnesDesignSystem.shadowLight.radius, 
                           x: LovedOnesDesignSystem.shadowLight.x, 
                           y: LovedOnesDesignSystem.shadowLight.y)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - 📊 SMART CARDS SECTION
struct SmartCardsSection: View {
    let tasks: [DashboardTask]
    let safetyStatus: DashboardSafetyStatus
    let onTaskTap: (DashboardTask) -> Void
    let onTaskToggle: (DashboardTask) -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Today's Overview")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Tasks Card
                SmartCard(
                    icon: "checklist",
                    title: "Tasks",
                    subtitle: "\(tasks.filter { !$0.isCompleted }.count) pending",
                    color: LovedOnesDesignSystem.primaryRed,
                    content: {
                        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
                            ForEach(tasks.prefix(3)) { task in
                                TaskRow(
                                    task: task,
                                    onTap: { onTaskTap(task) },
                                    onToggle: { onTaskToggle(task) }
                                )
                            }
                        }
                    }
                )
                
                // Safety Status Card
                SmartCard(
                    icon: "shield.fill",
                    title: "Safety Status",
                    subtitle: safetyStatus.isInSafeZone ? "All good" : "Outside safe zone",
                    color: safetyStatus.isInSafeZone ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.warningOrange,
                    content: {
                        HStack {
                            Circle()
                                .fill(safetyStatus.isInSafeZone ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.warningOrange)
                                .frame(width: 12, height: 12)
                            
                            Text(safetyStatus.isInSafeZone ? "Inside Safe Zone" : "Outside Safe Zone")
                                .font(LovedOnesDesignSystem.bodyFont)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            
                            Spacer()
                            
                            Text("Last seen: \(timeAgoString(from: safetyStatus.lastSeen))")
                                .font(LovedOnesDesignSystem.captionFont)
                                .foregroundColor(LovedOnesDesignSystem.darkGray)
                        }
                    }
                )
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - 🎯 SMART CARD
struct SmartCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let content: Content
    
    init(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LovedOnesDesignSystem.subheadingFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    
                    Text(subtitle)
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            
            content
        }
        .padding(LovedOnesDesignSystem.spaceL)
        .background(
            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusL)
                .fill(LovedOnesDesignSystem.pureWhite)
                .shadow(color: LovedOnesDesignSystem.shadowLight.color, 
                       radius: LovedOnesDesignSystem.shadowLight.radius, 
                       x: LovedOnesDesignSystem.shadowLight.x, 
                       y: LovedOnesDesignSystem.shadowLight.y)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(subtitle)")
    }
}

// MARK: - 📝 TASK ROW
struct TaskRow: View {
    let task: DashboardTask
    let onTap: () -> Void
    let onToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LovedOnesDesignSystem.spaceM) {
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundColor(priorityColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .strikethrough(task.isCompleted)
                    
                    Text(task.description)
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                    
                    Text(timeString)
                        .font(LovedOnesDesignSystem.smallFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.mediumGray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case "urgent": return LovedOnesDesignSystem.dangerRed
        case "high": return LovedOnesDesignSystem.primaryRed
        case "medium": return LovedOnesDesignSystem.warningOrange
        case "low": return LovedOnesDesignSystem.infoBlue
        default: return LovedOnesDesignSystem.mediumGray
        }
    }
    
    private var timeString: String {
        guard let dueDate = task.dueDate else { return "No due date" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
}

// MARK: - 🧠 COGNITIVE HEALTH DASHBOARD
struct CognitiveHealthDashboard: View {
    let cognitiveHealth: DashboardCognitiveHealth
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Cognitive Health")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Button("View Details", action: onViewDetails)
                .font(LovedOnesDesignSystem.captionFont)
                .foregroundColor(LovedOnesDesignSystem.primaryRed)
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Progress Overview
                HStack {
                    VStack(alignment: .leading) {
                        Text("This Week")
                            .font(LovedOnesDesignSystem.captionFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                        
                        Text("\(Int(cognitiveHealth.weeklyProgress * 100))%")
                            .font(LovedOnesDesignSystem.heroFont)
                            .foregroundColor(LovedOnesDesignSystem.successGreen)
                        
                        Text("Great progress!")
                            .font(LovedOnesDesignSystem.smallFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                    
                    Spacer()
                    
                    // Simple progress bars
                    VStack(alignment: .trailing, spacing: LovedOnesDesignSystem.spaceXS) {
                        ForEach(0..<cognitiveHealth.dailyScores.count, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cognitiveHealth.dailyScores[day] > 0.7 ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.lightGray)
                                .frame(width: 20, height: CGFloat(cognitiveHealth.dailyScores[day] * 24))
                        }
                    }
                }
                
            }
            .padding(LovedOnesDesignSystem.spaceL)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusL)
                    .fill(LovedOnesDesignSystem.pureWhite)
                    .shadow(color: LovedOnesDesignSystem.shadowLight.color, 
                           radius: LovedOnesDesignSystem.shadowLight.radius, 
                           x: LovedOnesDesignSystem.shadowLight.x, 
                           y: LovedOnesDesignSystem.shadowLight.y)
            )
        }
    }
}

// MARK: - 📱 RECENT ACTIVITY FEED
struct RecentActivityFeed: View {
    let activities: [DashboardActivity]
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Recent Activity")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Button("View All", action: onViewAll)
                .font(LovedOnesDesignSystem.captionFont)
                .foregroundColor(LovedOnesDesignSystem.primaryRed)
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                ForEach(activities.prefix(3)) { activity in
                    ActivityItem(
                        icon: activity.icon,
                        title: activity.title,
                        subtitle: activity.subtitle,
                        time: timeAgoString(from: activity.timestamp),
                        color: colorFromString(activity.color)
                    )
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "primaryRed": return LovedOnesDesignSystem.primaryRed
        case "infoBlue": return LovedOnesDesignSystem.infoBlue
        case "successGreen": return LovedOnesDesignSystem.successGreen
        case "warningOrange": return LovedOnesDesignSystem.warningOrange
        default: return LovedOnesDesignSystem.primaryRed
        }
    }
}

// MARK: - 📝 ACTIVITY ITEM
struct ActivityItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: LovedOnesDesignSystem.spaceM) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Text(subtitle)
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            
            Spacer()
            
            Text(time)
                .font(LovedOnesDesignSystem.smallFont)
                .foregroundColor(LovedOnesDesignSystem.darkGray)
        }
        .padding(LovedOnesDesignSystem.spaceM)
        .background(
            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                .fill(LovedOnesDesignSystem.lightGray)
        )
    }
}

// MARK: - 🎯 DAILY GOALS PROGRESS
struct DailyGoalsProgress: View {
    let goals: [DashboardGoal]
    let onGoalTap: (DashboardGoal) -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Daily Goals")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Text("\(goals.filter { $0.isCompleted }.count) of \(goals.count) completed")
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                ForEach(goals) { goal in
                    GoalProgressItem(
                        goal: goal,
                        onTap: { onGoalTap(goal) }
                    )
                }
            }
        }
        .padding(LovedOnesDesignSystem.spaceL)
        .background(
            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusL)
                .fill(LovedOnesDesignSystem.pureWhite)
                .shadow(color: LovedOnesDesignSystem.shadowLight.color, 
                       radius: LovedOnesDesignSystem.shadowLight.radius, 
                       x: LovedOnesDesignSystem.shadowLight.x, 
                       y: LovedOnesDesignSystem.shadowLight.y)
        )
    }
}

// MARK: - ✅ GOAL PROGRESS ITEM
struct GoalProgressItem: View {
    let goal: DashboardGoal
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LovedOnesDesignSystem.spaceM) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(goal.isCompleted ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.mediumGray)
                    .font(.title3)
                
                Text(goal.title)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .strikethrough(goal.isCompleted)
                
                Spacer()
                
                if !goal.isCompleted {
                    ProgressView(value: goal.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: LovedOnesDesignSystem.primaryRed))
                        .frame(width: 60)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 🎯 COMPACT FEATURES GRID
struct CompactFeaturesGrid: View {
    let onFaceRecognition: () -> Void
    let onRegisterFace: () -> Void
    let onViewRegistered: () -> Void
    let onAIChat: () -> Void
    let onViewHistory: () -> Void
    let onViewMemories: () -> Void
    let onAddMemory: () -> Void
    let onViewTimeline: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            // Header
            HStack {
                Text("Key Features")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    .font(.title2)
            }
            
            // Compact Grid - 2x2 layout
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                // Row 1: Face Recognition & AI Assistant
                HStack(spacing: LovedOnesDesignSystem.spaceS) {
                    // Face Recognition Card
                    CompactFeatureCard(
                        title: "Face ID",
                        subtitle: "Recognize family",
                        icon: "camera.fill",
                        color: LovedOnesDesignSystem.warningOrange,
                        onTap: onFaceRecognition,
                        onSecondary: onRegisterFace
                    )
                    
                    // AI Assistant Card
                    CompactFeatureCard(
                        title: "Talk Buddy",
                        subtitle: "AI companion",
                        icon: "brain.head.profile",
                        color: LovedOnesDesignSystem.primaryRed,
                        onTap: onAIChat,
                        onSecondary: onViewHistory
                    )
                }
                
                // Row 2: Memory Lane & Add Memory
                HStack(spacing: LovedOnesDesignSystem.spaceS) {
                    // Memory Lane Card
                    CompactFeatureCard(
                        title: "Memories",
                        subtitle: "Family moments",
                        icon: "photo.on.rectangle.angled",
                        color: LovedOnesDesignSystem.primaryRed,
                        onTap: onViewMemories,
                        onSecondary: onViewTimeline
                    )
                    
                    // Add Memory Card
                    CompactFeatureCard(
                        title: "Add Memory",
                        subtitle: "Capture moment",
                        icon: "plus.circle.fill",
                        color: LovedOnesDesignSystem.successGreen,
                        onTap: onAddMemory,
                        onSecondary: nil
                    )
                }
            }
        }
        .padding(LovedOnesDesignSystem.spaceM)
        .background(LovedOnesDesignSystem.pureWhite)
        .cornerRadius(LovedOnesDesignSystem.radiusL)
        .shadow(color: LovedOnesDesignSystem.shadowColor, radius: 10, x: 0, y: 5)
    }
}

// MARK: - 🎯 COMPACT FEATURE CARD
struct CompactFeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    let onSecondary: (() -> Void)?
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceS) {
            // Main button
            Button(action: onTap) {
                VStack(spacing: LovedOnesDesignSystem.spaceS) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(color.opacity(0.1))
                .cornerRadius(LovedOnesDesignSystem.radiusM)
            }
            
            // Secondary action button (if available)
            if let onSecondary = onSecondary {
                Button(action: onSecondary) {
                    Text("More")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(color)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceS)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(LovedOnesDesignSystem.radiusS)
                }
            }
        }
    }
}

// MARK: - 📷 FACE RECOGNITION SECTION
struct FaceRecognitionSection: View {
    let onStartRecognition: () -> Void
    let onRegisterFace: () -> Void
    let onViewRegistered: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Face Recognition")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Image(systemName: "camera.fill")
                    .foregroundColor(LovedOnesDesignSystem.warningOrange)
                    .font(.title2)
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Main Recognition Card
                Button(action: onStartRecognition) {
                    HStack(spacing: LovedOnesDesignSystem.spaceM) {
                        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
                            Text("Start Recognition")
                                .font(LovedOnesDesignSystem.titleFont)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Point camera at someone to identify them")
                                .font(LovedOnesDesignSystem.bodyFont)
                                .foregroundColor(LovedOnesDesignSystem.darkGray)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(LovedOnesDesignSystem.warningOrange)
                    }
                    .padding(LovedOnesDesignSystem.spaceL)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LovedOnesDesignSystem.pureWhite)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Action Buttons Row
                HStack(spacing: LovedOnesDesignSystem.spaceM) {
                    Button(action: onRegisterFace) {
                        HStack(spacing: LovedOnesDesignSystem.spaceS) {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                            Text("Register")
                                .font(LovedOnesDesignSystem.buttonFont)
                        }
                        .foregroundColor(LovedOnesDesignSystem.pureWhite)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LovedOnesDesignSystem.primaryRed)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onViewRegistered) {
                        HStack(spacing: LovedOnesDesignSystem.spaceS) {
                            Image(systemName: "person.2.fill")
                                .font(.title3)
                            Text("View All")
                                .font(LovedOnesDesignSystem.buttonFont)
                        }
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LovedOnesDesignSystem.primaryRed, lineWidth: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
    }
}

// MARK: - 🤖 AI ASSISTANT SECTION
struct AIAssistantSection: View {
    let onStartChat: () -> Void
    let onViewHistory: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("AI Assistant")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    .font(.title2)
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Main AI Chat Card
                Button(action: onStartChat) {
                    HStack(spacing: LovedOnesDesignSystem.spaceM) {
                        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
                            Text("Start AI Chat")
                                .font(LovedOnesDesignSystem.titleFont)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Ask questions, get help, or have a conversation")
                                .font(LovedOnesDesignSystem.bodyFont)
                                .foregroundColor(LovedOnesDesignSystem.darkGray)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    }
                    .padding(LovedOnesDesignSystem.spaceL)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LovedOnesDesignSystem.pureWhite)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Action Buttons Row
                HStack(spacing: LovedOnesDesignSystem.spaceM) {
                    Button(action: onStartChat) {
                        HStack(spacing: LovedOnesDesignSystem.spaceS) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.title3)
                            Text("New Chat")
                                .font(LovedOnesDesignSystem.buttonFont)
                        }
                        .foregroundColor(LovedOnesDesignSystem.pureWhite)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LovedOnesDesignSystem.primaryRed)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onViewHistory) {
                        HStack(spacing: LovedOnesDesignSystem.spaceS) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                            Text("History")
                                .font(LovedOnesDesignSystem.buttonFont)
                        }
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LovedOnesDesignSystem.primaryRed, lineWidth: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
    }
}

// MARK: - 📸 MEMORY LANE SECTION
struct MemoryLaneSection: View {
    let onViewMemories: () -> Void
    let onAddMemory: () -> Void
    let onViewTimeline: () -> Void
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                Text("Memory Lane")
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    .font(.title2)
            }
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Main Memory Lane Card
                Button(action: onViewMemories) {
                    HStack(spacing: LovedOnesDesignSystem.spaceM) {
                        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
                            Text("View Memories")
                                .font(LovedOnesDesignSystem.titleFont)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Browse your precious family moments and memories")
                                .font(LovedOnesDesignSystem.bodyFont)
                                .foregroundColor(LovedOnesDesignSystem.darkGray)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 40))
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    }
                    .padding(LovedOnesDesignSystem.spaceL)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LovedOnesDesignSystem.pureWhite)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Action Buttons Row
                HStack(spacing: LovedOnesDesignSystem.spaceM) {
                    Button(action: onAddMemory) {
                        HStack(spacing: LovedOnesDesignSystem.spaceS) {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Add Memory")
                                .font(LovedOnesDesignSystem.buttonFont)
                        }
                        .foregroundColor(LovedOnesDesignSystem.pureWhite)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LovedOnesDesignSystem.primaryRed)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onViewTimeline) {
                        HStack(spacing: LovedOnesDesignSystem.spaceS) {
                            Image(systemName: "timeline.selection")
                                .font(.title3)
                            Text("Timeline")
                                .font(LovedOnesDesignSystem.buttonFont)
                        }
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LovedOnesDesignSystem.primaryRed, lineWidth: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
    }
}

// MARK: - 🧠 COGNITIVE CHALLENGES SECTION
struct CognitiveChallengesSection: View {
    let challenges: [CognitiveChallenge]
    let onStartChallenge: (CognitiveChallenge) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🧠 Cognitive Challenges")
                        .font(LovedOnesDesignSystem.headingFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    
                    Text("Keep your mind sharp with daily exercises")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.textSecondary)
                }
                
                Spacer()
                
                Button("View All") {
                    // Show all challenges
                }
                .font(LovedOnesDesignSystem.captionFont)
                .foregroundColor(LovedOnesDesignSystem.primaryRed)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LovedOnesDesignSystem.spaceM) {
                    ForEach(challenges) { challenge in
                        CognitiveChallengeCard(
                            challenge: challenge,
                            onStart: {
                                onStartChallenge(challenge)
                            }
                        )
                    }
                }
                .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            }
        }
    }
}

// MARK: - 🧠 COGNITIVE CHALLENGE CARD
struct CognitiveChallengeCard: View {
    let challenge: CognitiveChallenge
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: challenge.type.icon)
                        .font(.title2)
                        .foregroundColor(LovedOnesDesignSystem.colorFromString(challenge.color))
                    
                    Spacer()
                    
                    Text(challenge.difficulty.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(challenge.difficulty == .easy ? Color.green : 
                                      challenge.difficulty == .medium ? Color.orange : Color.red)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .lineLimit(2)
                    
                    Text(challenge.description)
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.textSecondary)
                        .lineLimit(3)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("\(challenge.maxScore) pts")
                            .font(.caption)
                    }
                    .foregroundColor(LovedOnesDesignSystem.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(Int(challenge.estimatedTime/60)) min")
                            .font(.caption)
                    }
                    .foregroundColor(LovedOnesDesignSystem.textSecondary)
                }
            }
            .padding(LovedOnesDesignSystem.spaceM)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LovedOnesDesignSystem.pureWhite)
                    .shadow(
                        color: LovedOnesDesignSystem.shadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(width: 200)
    }
}

// MARK: - 🎮 COGNITIVE CHALLENGE GAME VIEW
struct CognitiveChallengeGameView: View {
    @ObservedObject var dashboardData: DashboardData
    @Environment(\.presentationMode) var presentationMode
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var score = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var gameTimer: Timer?
    
    var currentQuestion: ChallengeQuestion? {
        guard let challenge = dashboardData.currentChallenge,
              currentQuestionIndex < challenge.questions.count else { return nil }
        return challenge.questions[currentQuestionIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        LovedOnesDesignSystem.warmGray,
                        LovedOnesDesignSystem.pureWhite
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if let challenge = dashboardData.currentChallenge {
                    VStack(spacing: LovedOnesDesignSystem.spaceL) {
                        // Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text(challenge.title)
                                    .font(LovedOnesDesignSystem.titleFont)
                                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                
                                Text("Question \(currentQuestionIndex + 1) of \(challenge.questions.count)")
                                    .font(LovedOnesDesignSystem.captionFont)
                                    .foregroundColor(LovedOnesDesignSystem.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Timer
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                Text("\(Int(timeRemaining))s")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(timeRemaining < 10 ? .red : LovedOnesDesignSystem.textPrimary)
                        }
                        
                        // Progress Bar
                        ProgressView(value: Double(currentQuestionIndex), total: Double(challenge.questions.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: LovedOnesDesignSystem.colorFromString(challenge.color)))
                        
                        // Question
                        if let question = currentQuestion {
                            VStack(spacing: LovedOnesDesignSystem.spaceL) {
                                Text(question.question)
                                    .font(LovedOnesDesignSystem.headingFont)
                                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LovedOnesDesignSystem.pureWhite)
                                            .shadow(radius: 4)
                                    )
                                
                                // Answer Options
                                VStack(spacing: LovedOnesDesignSystem.spaceM) {
                                    ForEach(0..<question.options.count, id: \.self) { index in
                                        Button(action: {
                                            selectAnswer(index)
                                        }) {
                                            HStack {
                                                Text(question.options[index])
                                                    .font(LovedOnesDesignSystem.bodyFont)
                                                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                                
                                                Spacer()
                                                
                                                if selectedAnswer == index {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(LovedOnesDesignSystem.colorFromString(challenge.color))
                                                }
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedAnswer == index ? 
                                                          LovedOnesDesignSystem.colorFromString(challenge.color).opacity(0.1) : 
                                                          LovedOnesDesignSystem.pureWhite)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(selectedAnswer == index ? 
                                                                   LovedOnesDesignSystem.colorFromString(challenge.color) : 
                                                                   Color.clear, lineWidth: 2)
                                                    )
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                // Submit Button
                                if selectedAnswer != nil {
                                    Button(action: submitAnswer) {
                                        Text("Submit Answer")
                                            .font(LovedOnesDesignSystem.buttonFont)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(LovedOnesDesignSystem.colorFromString(challenge.color))
                                            )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Quit") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            gameTimer?.invalidate()
        }
        .alert("Challenge Complete!", isPresented: $showingResult) {
            Button("OK") {
                completeChallenge()
            }
        } message: {
            Text("Your score: \(score)/\(dashboardData.currentChallenge?.maxScore ?? 0)")
        }
    }
    
    private func startTimer() {
        guard let question = currentQuestion else { return }
        timeRemaining = question.timeLimit
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                submitAnswer()
            }
        }
    }
    
    private func selectAnswer(_ index: Int) {
        selectedAnswer = index
    }
    
    private func submitAnswer() {
        guard let question = currentQuestion,
              let selected = selectedAnswer else { return }
        
        gameTimer?.invalidate()
        
        isCorrect = selected == question.correctAnswer
        if isCorrect {
            score += question.points
        }
        
        // Show explanation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            nextQuestion()
        }
    }
    
    private func nextQuestion() {
        guard let challenge = dashboardData.currentChallenge else { return }
        
        if currentQuestionIndex < challenge.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            startTimer()
        } else {
            showingResult = true
        }
    }
    
    private func completeChallenge() {
        let timeSpent = dashboardData.challengeProgress.startTime?.timeIntervalSinceNow.magnitude ?? 0
        dashboardData.completeChallenge(score: score, timeSpent: timeSpent)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 🏆 PREVIEW
struct HackathonWinningDashboard_Previews: PreviewProvider {
    static var previews: some View {
        HackathonWinningDashboard()
            .previewDisplayName("🏆 Hackathon Winning Dashboard")
    }
}
