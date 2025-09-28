//
//  MemoryLaneView.swift
//  lovedones
//
//  Created by Krishna Bhatnagar on 9/27/25.
//

import SwiftUI
import AVFoundation

// MARK: - 🎨 DESIGN SYSTEM
struct MemoryLaneDesignSystem {
    // Colors
    static let primaryPink = Color(red: 0.95, green: 0.85, blue: 0.95)     // #F2D9F2 - Soft Pink
    static let accentPurple = Color(red: 0.8, green: 0.6, blue: 0.9)       // #CC99E6 - Accent Purple
    static let textWarm = Color(red: 0.2, green: 0.15, blue: 0.25)         // #332640 - Warm Text
    static let textSoft = Color(red: 0.4, green: 0.35, blue: 0.45)         // #665973 - Soft Text
    static let backgroundCream = Color(red: 0.98, green: 0.97, blue: 0.98) // #FAF9FA - Cream Background
    static let cardWhite = Color(red: 0.99, green: 0.98, blue: 0.99)       // #FDFAFD - Card White
    static let shadowSoft = (color: Color.black.opacity(0.08), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
    
    // Typography
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headingFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .medium, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    static let smallFont = Font.system(size: 12, weight: .medium, design: .rounded)
    
    // Spacing
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 16
    static let spaceL: CGFloat = 24
    static let spaceXL: CGFloat = 32
    
    // Border Radius
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 20
}

// MARK: - 📖 MEMORY DATA MODELS
struct Memory: Identifiable, Codable {
    let id = UUID()
    let title: String
    let story: String
    let familyNote: String
    let people: [String]
    let date: String
    let imageName: String
    let category: MemoryCategory
    
    enum MemoryCategory: String, CaseIterable, Codable {
        case family = "Family"
        case everyday = "Everyday"
        case milestones = "Milestones"
        case holidays = "Holidays"
        case special = "Special"
        
        var color: Color {
            switch self {
            case .family: return Color.blue
            case .everyday: return Color.green
            case .milestones: return Color.purple
            case .holidays: return Color.orange
            case .special: return Color.pink
            }
        }
    }
}

struct DavidMemoryStory {
    let title: String
    let story: String
    let familyNote: String
    let people: [String]
    let date: String
    let imageName: String
    let category: Memory.MemoryCategory
    let audioMessage: String? // Audio file name for voice notes
}

struct DavidMemoryStories {
    static let stories: [String: DavidMemoryStory] = [
        "memorylane_1": DavidMemoryStory(
            title: "Family Dinner at 127 Maple Street",
            story: "Every Sunday evening, our family of five would gather around the large wooden dining table. Sarah would cook her famous roasted turkey with carrots, and I'd help set the table with our best china. The kids - Tommy (7) and Emma (9) - would always fight over who got to sit next to me. Sarah would wear her light cardigan, and I'd be in my blue plaid shirt. The chandelier above us cast a warm glow as we shared stories about our week. Those were the happiest moments of my life.",
            familyNote: "This was our weekly tradition. Dad always sat at the head of the table, and Mom made sure everyone had their favorite dish.",
            people: ["Sarah (Wife, 58)", "Tommy (Son, 7)", "Emma (Daughter, 9)", "David (67)", "Sarah's Mother (82)"],
            date: "2020-03-15",
            imageName: "WhatsApp Image 2025-09-27 at 22.50.20",
            category: .everyday,
            audioMessage: "I love you grandpa"
        ),
        "memorylane_2": DavidMemoryStory(
            title: "Park Picnic with the Grandkids",
            story: "On a sunny Saturday in May, we took Tommy and Emma to Riverside Park for a picnic. Sarah packed our red and white checkered blanket and filled the wicker basket with sandwiches and fresh fruit. The kids were so excited - Tommy (7) wore his light blue shirt and Emma (9) had her cream sweater. We sat under the big oak tree, and I taught them how to identify different bird songs. Sarah and I held hands as we watched them play, feeling so grateful for our beautiful family.",
            familyNote: "Dad loved teaching the kids about nature. He'd point out every bird and flower, making it an adventure.",
            people: ["Sarah (Wife, 58)", "Tommy (Grandson, 7)", "Emma (Granddaughter, 9)", "David (67)"],
            date: "2020-05-23",
            imageName: "WhatsApp Image 2025-09-27 at 22.54.32",
            category: .family,
            audioMessage: "I love the special s"
        ),
        "memorylane_3": DavidMemoryStory(
            title: "Movie Night with Popcorn",
            story: "Friday nights were our movie tradition. We'd all pile onto the big grey sectional sofa in our living room. I'd make popcorn in the big glass bowl, and Sarah would choose the movie. Tommy (7) and Emma (9) would snuggle up next to us, and we'd watch classic family films. The kids would ask a million questions, and I'd pause the movie to explain everything. Sarah would always fall asleep halfway through, but she'd wake up for the ending. Those quiet evenings meant everything to me.",
            familyNote: "Dad was the best at explaining movie plots to the kids. He'd make up voices for all the characters.",
            people: ["Sarah (Wife, 58)", "Tommy (Grandson, 7)", "Emma (Granddaughter, 9)", "David (67)"],
            date: "2020-07-12",
            imageName: "WhatsApp Image 2025-09-27 at 22.57.18",
            category: .everyday,
            audioMessage: "I am cooking pasta t"
        ),
        "memorylane_4": DavidMemoryStory(
            title: "Building Blocks with Tommy",
            story: "Tommy (7) and I spent hours building with wooden blocks on the living room floor. He was so creative - always building the tallest towers and most elaborate train tracks. I'd help him with the tricky parts, and he'd get so excited when we finished a big project. The red and blue blocks were his favorites, and he'd always save the yellow ones for the top of his towers. Sarah would watch us from the sofa, smiling as Tommy explained his latest invention. Those simple moments were pure joy.",
            familyNote: "Tommy inherited Dad's engineering mind. They could build anything together, and Dad was so patient teaching him.",
            people: ["Tommy (Grandson, 7)", "David (67)"],
            date: "2020-09-08",
            imageName: "WhatsApp Image 2025-09-27 at 22.36.43 (1)",
            category: .family,
            audioMessage: "When I get old I wil"
        ),
        "memorylane_5": DavidMemoryStory(
            title: "Bedtime Stories with Emma",
            story: "Every night, Emma (9) would crawl into bed with her teddy bear, and I'd read her a story. She loved picture books with colorful illustrations, and she'd always ask me to do different voices for each character. Her bedroom was so cozy with the warm lamp light and the bookshelf full of her favorite books. She'd fall asleep in my arms, and I'd sit there for a while, just watching her peaceful face. Those quiet moments before sleep were some of my most precious memories.",
            familyNote: "Dad was the best storyteller. Emma would beg for 'just one more story' every night.",
            people: ["Emma (Granddaughter, 9)", "David (67)"],
            date: "2020-11-14",
            imageName: "WhatsApp Image 2025-09-27 at 22.36.43",
            category: .family,
            audioMessage: "I love you grandpa"
        ),
        "memorylane_6": DavidMemoryStory(
            title: "Swinging at the Park",
            story: "Tommy (7) loved the wooden swing at Riverside Park. I'd push him higher and higher, and he'd laugh with pure joy. He wore his blue and white striped shirt and his favorite sneakers. I'd always make sure to catch him safely, and he'd beg me to push him 'even higher, Grandpa!' The other kids at the park would watch us, and I felt so proud to be his grandfather. Sarah would sit on the bench nearby, taking pictures and cheering us on.",
            familyNote: "Dad was Tommy's favorite playmate. They'd spend hours at the park, and Dad never got tired of pushing that swing.",
            people: ["Tommy (Grandson, 7)", "David (67)"],
            date: "2021-01-20",
            imageName: "WhatsApp Image 2025-09-27 at 22.36.44",
            category: .family,
            audioMessage: "I love you David"
        ),
        "memorylane_7": DavidMemoryStory(
            title: "Our Park Bench Moments",
            story: "Sarah and I had our favorite bench at Riverside Park. We'd sit there every afternoon, holding hands and watching the world go by. She'd wear her light cardigan and I'd be in my blue plaid shirt. We'd talk about our day, our dreams, and our beautiful family. The bench was our special place - where we'd share secrets, make plans, and simply enjoy being together. Those quiet moments of companionship were the foundation of our love.",
            familyNote: "Mom and Dad's daily ritual. They'd walk to the park every day, rain or shine, just to sit on their bench.",
            people: ["Sarah (Wife, 58)", "David (67)"],
            date: "2021-03-10",
            imageName: "WhatsApp Image 2025-09-27 at 22.38.34",
            category: .everyday,
            audioMessage: nil
        ),
        "memorylane_8": DavidMemoryStory(
            title: "Our Wedding Day - 35 Years Ago",
            story: "Our wedding day was perfect. Sarah looked absolutely beautiful in her white gown with the delicate lace sleeves and her short veil. I was so nervous in my dark suit, but when I saw her walking down the aisle, everything felt right. We stood under the white rose archway, holding hands and promising to love each other forever. The photographer captured this moment - our first kiss as husband and wife. I still remember how soft her hand felt in mine, and how her eyes sparkled with happiness.",
            familyNote: "This is Mom and Dad's wedding photo from 1985. They were so young and in love, and that love lasted 35 years.",
            people: ["Sarah (Wife, 23)", "David (32)"],
            date: "1985-06-15",
            imageName: "WhatsApp Image 2025-09-27 at 22.38.47",
            category: .milestones,
            audioMessage: "I love you David"
        ),
        "memorylane_9": DavidMemoryStory(
            title: "Tommy's Graduation Day",
            story: "I was so proud watching Tommy graduate from college. He looked so grown up in his cap and gown, holding his diploma. I wore my navy suit and stood beside him, feeling like the luckiest grandfather in the world. He had worked so hard for this moment, and I couldn't stop smiling. Sarah would have been so proud too. Tommy hugged me tight and whispered 'Thank you, Grandpa, for believing in me.' That was one of the happiest days of my life.",
            familyNote: "Dad was Tommy's biggest supporter. He never missed a single school event and was always there to celebrate his achievements.",
            people: ["Tommy (Grandson, 22)", "David (67)"],
            date: "2021-05-15",
            imageName: "WhatsApp Image 2025-09-27 at 22.40.26",
            category: .milestones,
            audioMessage: nil
        ),
        "memorylane_10": DavidMemoryStory(
            title: "The Surprise Car Gift",
            story: "I'll never forget the day Tommy surprised me with a Tesla. I was standing in the driveway at 127 Maple Street, and there it was - a beautiful dark blue Tesla with a big red bow on it. Tommy handed me the keys, and I was speechless. 'You've given me everything, Grandpa,' he said. 'It's time I gave something back to you.' I covered my mouth in shock and joy. Sarah would have been so proud of the man Tommy had become. That car represented so much more than transportation - it was love.",
            familyNote: "Tommy worked extra hours for months to save up for this surprise. Dad cried when he saw it, and we all cried with him.",
            people: ["Tommy (Grandson, 24)", "David (67)"],
            date: "2021-08-22",
            imageName: "WhatsApp Image 2025-09-27 at 22.41.30",
            category: .milestones,
            audioMessage: nil
        ),
        "memorylane_11": DavidMemoryStory(
            title: "Family Portrait at Home",
            story: "This was our last family photo together at 127 Maple Street. Tommy (24) had grown into such a fine young man, and Emma (26) was beautiful in her cream sweater. I sat in the middle, feeling so blessed to be surrounded by my family. We were all smiling, but I could see the sadness in their eyes - they knew this might be one of our last photos together. The living room behind us was filled with memories, and I felt so grateful for every moment we'd shared in that house.",
            familyNote: "This was taken just before Dad's diagnosis. We all knew something was changing, but we tried to smile for the camera.",
            people: ["Tommy (Grandson, 24)", "Emma (Granddaughter, 26)", "David (67)"],
            date: "2021-10-30",
            imageName: "WhatsApp Image 2025-09-27 at 22.46.01",
            category: .family,
            audioMessage: nil
        ),
        "memorylane_12": DavidMemoryStory(
            title: "Sarah's 60th Birthday - Our Last Together",
            story: "Sarah's 60th birthday was perfect. The whole family came over to 127 Maple Street, and she was glowing in her blue dress. I gave her a locket with our wedding photo inside, and she cried happy tears. Tommy (7) and Emma (9) made her cards, and we had her favorite chocolate cake. I didn't know it would be our last birthday together, but I'm glad it was a good one. She wore that locket every day after that, and I can still see her touching it when she thought I wasn't looking.",
            familyNote: "This was Mom's last birthday with us. Dad made it so special for her, and she wore that locket every day.",
            people: ["Sarah (Wife, 60)", "Tommy (Grandson, 7)", "Emma (Granddaughter, 9)", "David (67)"],
            date: "2021-02-14",
            imageName: "WhatsApp Image 2025-09-27 at 22.47.50",
            category: .milestones,
            audioMessage: "I wish we grow old t"
        )
    ]
}

// MARK: - 🌸 MEMORY LANE VIEW
struct MemoryLaneView: View {
    @StateObject private var audioManager = AudioPlayerManager()
    @State private var selectedStory: DavidMemoryStory? = nil
    @State private var showingStoryDetail = false
    @State private var showingVoiceNotes = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MemoryLaneDesignSystem.spaceL) {
                // 🌸 HEADER SECTION
                headerSection
                
                // 📖 DAVID'S MEMORY GALLERY
                davidsMemoryGallery
            }
            .padding(.horizontal, MemoryLaneDesignSystem.spaceL)
            .padding(.vertical, MemoryLaneDesignSystem.spaceL)
        }
        .background(MemoryLaneDesignSystem.backgroundCream)
        .sheet(isPresented: $showingStoryDetail) {
            if let story = selectedStory {
                DavidStoryDetailView(story: story)
            }
        }
        .sheet(isPresented: $showingVoiceNotes) {
            VoiceNotePlayerView()
        }
    }
    
    // MARK: - HEADER SECTION
    private var headerSection: some View {
        VStack(spacing: MemoryLaneDesignSystem.spaceM) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Memory Lane")
                        .font(MemoryLaneDesignSystem.titleFont)
                        .foregroundColor(MemoryLaneDesignSystem.textWarm)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Cherish every precious moment")
                        .font(MemoryLaneDesignSystem.captionFont)
                        .foregroundColor(MemoryLaneDesignSystem.textSoft)
                }
                
                Spacer()
                
                // Voice Notes Button
                Button(action: {
                    showingVoiceNotes = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("Voice Notes")
                            .font(MemoryLaneDesignSystem.captionFont)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [MemoryLaneDesignSystem.accentPurple, MemoryLaneDesignSystem.primaryPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: MemoryLaneDesignSystem.shadowSoft.color, radius: MemoryLaneDesignSystem.shadowSoft.radius, x: MemoryLaneDesignSystem.shadowSoft.x, y: MemoryLaneDesignSystem.shadowSoft.y)
                }
            }
        }
    }
    
    // MARK: - DAVID'S MEMORY GALLERY
    private var davidsMemoryGallery: some View {
        VStack(alignment: .leading, spacing: MemoryLaneDesignSystem.spaceL) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("David's Memory Gallery")
                        .font(MemoryLaneDesignSystem.titleFont)
                        .foregroundColor(MemoryLaneDesignSystem.textWarm)
                    
                    Text("Precious moments from David's life")
                        .font(MemoryLaneDesignSystem.captionFont)
                        .foregroundColor(MemoryLaneDesignSystem.textSoft)
                }
                
                Spacer()
            }
            
            // Full-width grid of David's memories
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: MemoryLaneDesignSystem.spaceM),
                GridItem(.flexible(), spacing: MemoryLaneDesignSystem.spaceM)
            ], spacing: MemoryLaneDesignSystem.spaceL) {
                ForEach(Array(DavidMemoryStories.stories.keys.sorted()), id: \.self) { key in
                    if let story = DavidMemoryStories.stories[key] {
                        DavidMemoryCard(story: story) {
                            selectedStory = story
                            showingStoryDetail = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - DAVID MEMORY CARD
struct DavidMemoryCard: View {
    let story: DavidMemoryStory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                Image(story.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(
                        TopRoundedRectangle(cornerRadius: MemoryLaneDesignSystem.radiusM)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Title and Date
                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title)
                            .font(MemoryLaneDesignSystem.bodyFont)
                            .fontWeight(.semibold)
                            .foregroundColor(MemoryLaneDesignSystem.textWarm)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(story.date)
                            .font(MemoryLaneDesignSystem.smallFont)
                            .foregroundColor(MemoryLaneDesignSystem.textSoft)
                    }
                    
                    // Story preview
                    Text(story.story)
                        .font(MemoryLaneDesignSystem.captionFont)
                        .foregroundColor(MemoryLaneDesignSystem.textSoft)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    
                    // People involved
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(MemoryLaneDesignSystem.textSoft)
                        
                        Text("\(story.people.count) people")
                            .font(MemoryLaneDesignSystem.smallFont)
                            .foregroundColor(MemoryLaneDesignSystem.textSoft)
                        
                        Spacer()
                        
                        // Category badge
                        Text(story.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(story.category.color)
                            )
                    }
                }
                .padding(12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: MemoryLaneDesignSystem.radiusM)
                .fill(Color.white.opacity(0.9))
                .shadow(
                    color: MemoryLaneDesignSystem.shadowSoft.color,
                    radius: MemoryLaneDesignSystem.shadowSoft.radius,
                    x: MemoryLaneDesignSystem.shadowSoft.x,
                    y: MemoryLaneDesignSystem.shadowSoft.y
                )
        )
    }
}

// MARK: - DAVID STORY DETAIL VIEW
struct DavidStoryDetailView: View {
    let story: DavidMemoryStory
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: MemoryLaneDesignSystem.spaceL) {
                    // Image
                    Image(story.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: MemoryLaneDesignSystem.radiusL))
                    
                    VStack(alignment: .leading, spacing: MemoryLaneDesignSystem.spaceL) {
                        // Title and Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text(story.title)
                                .font(MemoryLaneDesignSystem.titleFont)
                                .foregroundColor(MemoryLaneDesignSystem.textWarm)
                                .multilineTextAlignment(.leading)
                            
                            Text(story.date)
                                .font(MemoryLaneDesignSystem.bodyFont)
                                .foregroundColor(MemoryLaneDesignSystem.textSoft)
                        }
                        
                        // Story
                        VStack(alignment: .leading, spacing: 8) {
                            Text("The Story")
                                .font(MemoryLaneDesignSystem.headingFont)
                                .foregroundColor(MemoryLaneDesignSystem.textWarm)
                            
                            Text(story.story)
                                .font(MemoryLaneDesignSystem.bodyFont)
                                .foregroundColor(MemoryLaneDesignSystem.textWarm)
                                .lineSpacing(4)
                        }
                        
                        // Family Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Family Note")
                                .font(MemoryLaneDesignSystem.headingFont)
                                .foregroundColor(MemoryLaneDesignSystem.textWarm)
                            
                            Text(story.familyNote)
                                .font(MemoryLaneDesignSystem.bodyFont)
                                .foregroundColor(MemoryLaneDesignSystem.textSoft)
                                .italic()
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: MemoryLaneDesignSystem.radiusM)
                                .fill(MemoryLaneDesignSystem.primaryPink.opacity(0.3))
                        )
                        
                        // Audio Message from Loved Ones
                        if let audioMessage = story.audioMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Voice Message from Family")
                                    .font(MemoryLaneDesignSystem.headingFont)
                                    .foregroundColor(MemoryLaneDesignSystem.textWarm)
                                
                                AudioPlayerView(audioFileName: audioMessage)
                            }
                        }
                        
                        // People involved
                        VStack(alignment: .leading, spacing: 8) {
                            Text("People in this memory")
                                .font(MemoryLaneDesignSystem.headingFont)
                                .foregroundColor(MemoryLaneDesignSystem.textWarm)
                            
                            ForEach(story.people, id: \.self) { person in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(MemoryLaneDesignSystem.accentPurple)
                                    Text(person)
                                        .font(MemoryLaneDesignSystem.bodyFont)
                                        .foregroundColor(MemoryLaneDesignSystem.textWarm)
                                    Spacer()
                                }
                            }
                        }
                        
                        // Memory Category
                        HStack {
                            Text("Category:")
                                .font(MemoryLaneDesignSystem.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(MemoryLaneDesignSystem.textWarm)
                            
                            Text(story.category.rawValue)
                                .font(MemoryLaneDesignSystem.bodyFont)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(story.category.color)
                                )
                        }
                    }
                    .padding(.horizontal, MemoryLaneDesignSystem.spaceL)
                }
            }
            .background(MemoryLaneDesignSystem.backgroundCream)
            .navigationTitle("Memory Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - TOP ROUNDED RECTANGLE SHAPE
struct TopRoundedRectangle: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}

// MARK: - AUDIO PLAYER MANAGER
class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    func play() {
        isPlaying = true
    }
    
    func pause() {
        isPlaying = false
    }
    
    func stop() {
        isPlaying = false
        currentTime = 0
    }
}

// MARK: - AUDIO PLAYER VIEW
struct AudioPlayerView: View {
    let audioFileName: String
    @StateObject private var audioManager = AudioPlayerManager()
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        HStack(spacing: 16) {
            // Play/Pause Button
            Button(action: {
                if audioManager.isPlaying {
                    audioManager.pause()
                    player?.pause()
                } else {
                    playAudio()
                }
            }) {
                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(MemoryLaneDesignSystem.accentPurple)
            }
            
            // Audio Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Note")
                    .font(MemoryLaneDesignSystem.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(MemoryLaneDesignSystem.textWarm)
                
                Text("Tap to play message from family")
                    .font(.caption)
                    .foregroundColor(MemoryLaneDesignSystem.textSoft)
            }
            
            Spacer()
            
            // Duration
            Text(formatTime(audioManager.duration))
                .font(.caption)
                .foregroundColor(MemoryLaneDesignSystem.textSoft)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: MemoryLaneDesignSystem.radiusM)
                .fill(MemoryLaneDesignSystem.accentPurple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: MemoryLaneDesignSystem.radiusM)
                        .stroke(MemoryLaneDesignSystem.accentPurple.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            setupAudio()
        }
    }
    
    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "m4a") else {
            print("Audio file not found: \(audioFileName).m4a")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = AudioPlayerDelegate(audioManager: audioManager)
            audioManager.duration = player?.duration ?? 0
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    private func playAudio() {
        guard let player = player else { return }
        
        if player.currentTime == 0 {
            player.play()
        } else {
            player.play()
        }
        audioManager.play()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AUDIO PLAYER DELEGATE
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let audioManager: AudioPlayerManager
    
    init(audioManager: AudioPlayerManager) {
        self.audioManager = audioManager
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioManager.stop()
    }
}

// MARK: - PREVIEW
struct MemoryLaneView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryLaneView()
    }
}
