//
//  MemoryLaneManager.swift
//  LovedOnes
//
//  Memory lane management for caregivers
//

import Foundation
import SwiftUI

class MemoryLaneManager: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var voiceNotes: [VoiceNote] = []
    @Published var photos: [Photo] = []
    @Published var videos: [Video] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Sample memories
        memories = [
            Memory(
                title: "Dad's 70th Birthday",
                story: "Celebrated with family at home. Dad was so happy to see everyone.",
                familyNote: "Everyone came together for this special day",
                people: ["Dad", "Mom", "Sarah", "John"],
                date: "2024-08-28",
                imageName: "birthday_cake.jpg",
                category: .special
            ),
            Memory(
                title: "Morning Walk in the Park",
                story: "Dad enjoyed feeding the ducks and watching the sunrise.",
                familyNote: "Such a peaceful morning together",
                people: ["Dad", "Me"],
                date: "2024-09-13",
                imageName: "park_walk.jpg",
                category: .everyday
            ),
            Memory(
                title: "Granddaughter's Visit",
                story: "Dad lit up when Sarah came to visit. They played cards together.",
                familyNote: "Sarah always brings such joy to Dad",
                people: ["Dad", "Sarah"],
                date: "2024-09-21",
                imageName: "cards_game.jpg",
                category: .family
            ),
            Memory(
                title: "Doctor's Appointment",
                story: "Regular checkup went well. Doctor was pleased with progress.",
                familyNote: "Good news from the doctor",
                people: ["Dad", "Me", "Dr. Smith"],
                date: "2024-09-25",
                imageName: "doctor_visit.jpg",
                category: .milestones
            )
        ]
        
        // Sample voice notes
        voiceNotes = [
            VoiceNote(
                title: "Dad's Favorite Song",
                fileName: "dad_song.mp3",
                duration: 120,
                category: .memories,
                isFavorite: true
            ),
            VoiceNote(
                title: "Memory of Mom",
                fileName: "mom_memory.mp3",
                duration: 180,
                category: .memories,
                isFavorite: true
            ),
            VoiceNote(
                title: "Daily Update",
                fileName: "daily_update.mp3",
                duration: 60,
                category: .general,
                isFavorite: false
            )
        ]
        
        // Sample photos
        photos = [
            Photo(
                id: UUID(),
                title: "Family Photo",
                description: "All of us together at Christmas",
                date: Date().addingTimeInterval(-86400 * 60),
                isFavorite: true,
                imagePath: "family_christmas.jpg"
            ),
            Photo(
                id: UUID(),
                title: "Dad in the Garden",
                description: "Dad tending to his roses",
                date: Date().addingTimeInterval(-86400 * 20),
                isFavorite: false,
                imagePath: "dad_garden.jpg"
            )
        ]
        
        // Sample videos
        videos = [
            Video(
                id: UUID(),
                title: "Dad Dancing",
                description: "Dad dancing to his favorite music",
                duration: 45,
                date: Date().addingTimeInterval(-86400 * 12),
                isFavorite: true,
                videoPath: "dad_dancing.mp4"
            )
        ]
    }
    
    func addMemory(_ memory: Memory) {
        memories.insert(memory, at: 0)
    }
    
    func addVoiceNote(_ voiceNote: VoiceNote) {
        voiceNotes.insert(voiceNote, at: 0)
    }
    
    func addPhoto(_ photo: Photo) {
        photos.insert(photo, at: 0)
    }
    
    func addVideo(_ video: Video) {
        videos.insert(video, at: 0)
    }
    
    func toggleFavorite(for memory: Memory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            // Note: Memory struct from MemoryLaneView doesn't have isFavorite property
            // This would need to be implemented in the actual Memory struct
        }
    }
    
    func toggleFavorite(for voiceNote: VoiceNote) {
        if let index = voiceNotes.firstIndex(where: { $0.id == voiceNote.id }) {
            voiceNotes[index].isFavorite.toggle()
        }
    }
    
    func getRecentMemories(limit: Int = 10) -> [Memory] {
        return Array(memories.prefix(limit))
    }
    
    func getFavoriteMemories() -> [Memory] {
        // Note: Memory struct doesn't have isFavorite property
        // This would need to be implemented in the actual Memory struct
        return memories
    }
    
    func getMemoriesByType(_ type: Memory.MemoryCategory) -> [Memory] {
        return memories.filter { $0.category == type }
    }
    
    func searchMemories(query: String) -> [Memory] {
        return memories.filter { memory in
            memory.title.localizedCaseInsensitiveContains(query) ||
            memory.story.localizedCaseInsensitiveContains(query) ||
            memory.familyNote.localizedCaseInsensitiveContains(query) ||
            memory.people.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

// MARK: - Data Models

// Memory and MemoryType are defined in MemoryLaneView.swift

struct Photo: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let date: Date
    var isFavorite: Bool
    let imagePath: String
}

struct Video: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let duration: Int // in seconds
    let date: Date
    var isFavorite: Bool
    let videoPath: String
}
