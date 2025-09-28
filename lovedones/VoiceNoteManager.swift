//
//  VoiceNoteManager.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Voice Note Models
struct VoiceNote: Identifiable, Codable {
    let id = UUID()
    let title: String
    let fileName: String
    let duration: TimeInterval
    let createdAt: Date
    let category: VoiceNoteCategory
    var isFavorite: Bool
    
    init(title: String, fileName: String, duration: TimeInterval, category: VoiceNoteCategory, isFavorite: Bool = false) {
        self.title = title
        self.fileName = fileName
        self.duration = duration
        self.createdAt = Date()
        self.category = category
        self.isFavorite = isFavorite
    }
}

enum VoiceNoteCategory: String, CaseIterable, Codable {
    case family = "family"
    case memories = "memories"
    case messages = "messages"
    case reminders = "reminders"
    case general = "general"
    
    var icon: String {
        switch self {
        case .family: return "person.2.fill"
        case .memories: return "heart.fill"
        case .messages: return "message.fill"
        case .reminders: return "bell.fill"
        case .general: return "mic.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .family: return .blue
        case .memories: return .pink
        case .messages: return .green
        case .reminders: return .orange
        case .general: return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .family: return "Family"
        case .memories: return "Memories"
        case .messages: return "Messages"
        case .reminders: return "Reminders"
        case .general: return "General"
        }
    }
}

// MARK: - Voice Note Manager
class VoiceNoteManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var voiceNotes: [VoiceNote] = []
    @Published var currentlyPlaying: VoiceNote?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var playbackSpeed: Float = 1.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    override init() {
        super.init()
        loadSampleVoiceNotes()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            // Configure audio session for playback with options
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func loadSampleVoiceNotes() {
        // These are the 5 MP3 files from the backend
        let sampleNotes = [
            VoiceNote(
                title: "I Love the Special S",
                fileName: "I love the special s.mp3",
                duration: 15.0, // Estimated duration
                category: .memories,
                isFavorite: true
            ),
            VoiceNote(
                title: "I Love You David",
                fileName: "I love you David .mp3",
                duration: 12.0,
                category: .family,
                isFavorite: true
            ),
            VoiceNote(
                title: "I Love You David (2)",
                fileName: "I love you David 1.mp3",
                duration: 10.0,
                category: .family,
                isFavorite: false
            ),
            VoiceNote(
                title: "I Love You Grandpa",
                fileName: "I love you grandpa .mp3",
                duration: 8.0,
                category: .family,
                isFavorite: true
            ),
            VoiceNote(
                title: "When I Get Old",
                fileName: "When I get old I wil.mp3",
                duration: 20.0,
                category: .memories,
                isFavorite: false
            )
        ]
        
        voiceNotes = sampleNotes
    }
    
    func playVoiceNote(_ voiceNote: VoiceNote) {
        stopPlayback()
        
        currentlyPlaying = voiceNote
        isLoading = true
        
        // Load and play the actual audio file
        loadAndPlayAudioFile(voiceNote)
    }
    
    private func loadAndPlayAudioFile(_ voiceNote: VoiceNote) {
        // For now, we'll use local audio files since the backend files aren't accessible
        // In a real implementation, you would download from the backend URL
        guard let audioURL = getLocalAudioURL(for: voiceNote.fileName) else {
            print("Could not find audio file: \(voiceNote.fileName)")
            isLoading = false
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.rate = playbackSpeed
            
            // Update duration with actual audio duration
            if let duration = audioPlayer?.duration {
                // Update the voice note duration if it's different
                if let index = voiceNotes.firstIndex(where: { $0.id == voiceNote.id }) {
                    voiceNotes[index] = VoiceNote(
                        title: voiceNote.title,
                        fileName: voiceNote.fileName,
                        duration: duration,
                        category: voiceNote.category,
                        isFavorite: voiceNote.isFavorite
                    )
                }
            }
            
            audioPlayer?.play()
            isPlaying = true
            isLoading = false
            startPlaybackTimer()
            
        } catch {
            print("Error loading audio file: \(error)")
            isLoading = false
            errorMessage = "Could not load audio file"
        }
    }
    
    private func getLocalAudioURL(for fileName: String) -> URL? {
        // For now, we'll create placeholder audio files
        // In a real implementation, you would download from your backend
        // For demo purposes, we'll use system sounds or create silent audio
        
        // Create a temporary audio file for demo
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        // If file doesn't exist, create a silent audio file for demo
        if !FileManager.default.fileExists(atPath: audioURL.path) {
            createSilentAudioFile(at: audioURL, duration: 10.0)
        }
        
        return audioURL
    }
    
    private func createSilentAudioFile(at url: URL, duration: TimeInterval) {
        // For demo purposes, create a simple audio file with actual sound
        // In a real implementation, you would download the actual MP3 from your backend
        
        // Create a simple audio file with a pleasant tone
        let sampleRate: Double = 44100
        let channels: Int = 1
        let bitsPerChannel: Int = 16
        let frequency: Double = 523.25 // C5 note (pleasant sound)
        
        let frameCount = Int(sampleRate * duration)
        let dataSize = frameCount * channels * bitsPerChannel / 8
        
        // Create audio data with a more complex waveform
        var audioData = Data(count: dataSize)
        audioData.withUnsafeMutableBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            let amplitude: Int16 = 16000 // Higher volume level
            
            for i in 0..<frameCount {
                let time = Double(i) / sampleRate
                // Create a more complex waveform with harmonics
                let fundamental = sin(2.0 * Double.pi * frequency * time)
                let harmonic2 = 0.5 * sin(2.0 * Double.pi * frequency * 2.0 * time)
                let harmonic3 = 0.25 * sin(2.0 * Double.pi * frequency * 3.0 * time)
                let envelope = exp(-time * 0.5) // Decay envelope
                
                let sample = Int16(Double(amplitude) * envelope * (fundamental + harmonic2 + harmonic3))
                samples[i] = sample
            }
        }
        
        // Create WAV header
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        var chunkSize = UInt32(36 + dataSize)
        wavData.append(Data(bytes: &chunkSize, count: 4))
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        var fmtChunkSize = UInt32(16)
        wavData.append(Data(bytes: &fmtChunkSize, count: 4))
        var audioFormat = UInt16(1) // PCM
        wavData.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = UInt16(channels)
        wavData.append(Data(bytes: &numChannels, count: 2))
        var sampleRateUInt = UInt32(sampleRate)
        wavData.append(Data(bytes: &sampleRateUInt, count: 4))
        var byteRate = UInt32(sampleRate * Double(channels) * Double(bitsPerChannel) / 8)
        wavData.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(channels * bitsPerChannel / 8)
        wavData.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample = UInt16(bitsPerChannel)
        wavData.append(Data(bytes: &bitsPerSample, count: 2))
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        var dataSizeUInt = UInt32(dataSize)
        wavData.append(Data(bytes: &dataSizeUInt, count: 4))
        wavData.append(audioData)
        
        try? wavData.write(to: url)
    }
    
    func pausePlayback() {
        isPlaying = false
        stopPlaybackTimer()
        audioPlayer?.pause()
    }
    
    func resumePlayback() {
        isPlaying = true
        startPlaybackTimer()
        audioPlayer?.play()
    }
    
    func stopPlayback() {
        isPlaying = false
        currentlyPlaying = nil
        currentTime = 0
        stopPlaybackTimer()
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func seekTo(_ time: TimeInterval) {
        currentTime = time
        audioPlayer?.currentTime = time
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        audioPlayer?.rate = speed
    }
    
    func toggleFavorite(_ voiceNote: VoiceNote) {
        if let index = voiceNotes.firstIndex(where: { $0.id == voiceNote.id }) {
            voiceNotes[index].isFavorite.toggle()
        }
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = self.audioPlayer, self.isPlaying {
                self.currentTime = player.currentTime
                
                if self.currentTime >= player.duration {
                    self.stopPlayback()
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.stopPlayback()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.errorMessage = "Audio playback error: \(error?.localizedDescription ?? "Unknown error")"
            self.isLoading = false
            self.isPlaying = false
        }
    }
    
    // MARK: - Filtering
    var favoriteNotes: [VoiceNote] {
        voiceNotes.filter { $0.isFavorite }
    }
    
    var familyNotes: [VoiceNote] {
        voiceNotes.filter { $0.category == .family }
    }
    
    var memoryNotes: [VoiceNote] {
        voiceNotes.filter { $0.category == .memories }
    }
    
    func notesForCategory(_ category: VoiceNoteCategory) -> [VoiceNote] {
        voiceNotes.filter { $0.category == category }
    }
    
    // MARK: - Search
    func searchNotes(_ query: String) -> [VoiceNote] {
        if query.isEmpty {
            return voiceNotes
        }
        
        return voiceNotes.filter { voiceNote in
            voiceNote.title.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Voice Note Extensions
extension VoiceNote {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

extension VoiceNoteManager {
    var currentProgress: Double {
        guard let voiceNote = currentlyPlaying else { return 0.0 }
        return voiceNote.duration > 0 ? currentTime / voiceNote.duration : 0.0
    }
    
    var remainingTime: TimeInterval {
        guard let voiceNote = currentlyPlaying else { return 0.0 }
        return max(0, voiceNote.duration - currentTime)
    }
    
    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "-%d:%02d", minutes, seconds)
    }
}
