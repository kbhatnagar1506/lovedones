//
//  VoiceNotePlayerView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import SwiftUI
import AVFoundation

struct VoiceNotePlayerView: View {
    @StateObject private var voiceNoteManager = VoiceNoteManager()
    @State private var searchText = ""
    @State private var selectedCategory: VoiceNoteCategory?
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Category Filter
                categoryFilter
                
                // Voice Notes List
                voiceNotesList
                
                // Mini Player
                if voiceNoteManager.currentlyPlaying != nil {
                    miniPlayer
                }
            }
            .navigationTitle("Voice Notes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPlayer) {
                if let currentNote = voiceNoteManager.currentlyPlaying {
                    FullScreenPlayerView(voiceNote: currentNote, voiceNoteManager: voiceNoteManager)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search voice notes...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .blue
                ) {
                    selectedCategory = nil
                }
                
                ForEach(VoiceNoteCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Voice Notes List
    private var voiceNotesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredVoiceNotes) { voiceNote in
                    VoiceNoteCard(
                        voiceNote: voiceNote,
                        isPlaying: voiceNoteManager.currentlyPlaying?.id == voiceNote.id,
                        isPlayingAudio: voiceNoteManager.isPlaying,
                        onPlay: {
                            if voiceNoteManager.currentlyPlaying?.id == voiceNote.id {
                                if voiceNoteManager.isPlaying {
                                    voiceNoteManager.pausePlayback()
                                } else {
                                    voiceNoteManager.resumePlayback()
                                }
                            } else {
                                voiceNoteManager.playVoiceNote(voiceNote)
                            }
                        },
                        onShowPlayer: {
                            showingPlayer = true
                        },
                        onToggleFavorite: {
                            voiceNoteManager.toggleFavorite(voiceNote)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Mini Player
    private var miniPlayer: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Play/Pause Button
                Button(action: {
                    if voiceNoteManager.isPlaying {
                        voiceNoteManager.pausePlayback()
                    } else {
                        voiceNoteManager.resumePlayback()
                    }
                }) {
                    Image(systemName: voiceNoteManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Voice Note Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(voiceNoteManager.currentlyPlaying?.title ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(voiceNoteManager.formattedCurrentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress Bar
                ProgressView(value: voiceNoteManager.currentProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 100)
                
                // Full Screen Button
                Button(action: {
                    showingPlayer = true
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Computed Properties
    private var filteredVoiceNotes: [VoiceNote] {
        var notes = voiceNoteManager.voiceNotes
        
        // Filter by search text
        if !searchText.isEmpty {
            notes = voiceNoteManager.searchNotes(searchText)
        }
        
        // Filter by category
        if let category = selectedCategory {
            notes = notes.filter { $0.category == category }
        }
        
        // Sort by favorites first, then by date
        return notes.sorted { first, second in
            if first.isFavorite != second.isFavorite {
                return first.isFavorite
            }
            return first.createdAt > second.createdAt
        }
    }
}

// MARK: - Supporting Views
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? color : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct VoiceNoteCard: View {
    let voiceNote: VoiceNote
    let isPlaying: Bool
    let isPlayingAudio: Bool
    let onPlay: () -> Void
    let onShowPlayer: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Play Button
            Button(action: onPlay) {
                Image(systemName: isPlaying && isPlayingAudio ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(voiceNote.category.color)
            }
            
            // Voice Note Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(voiceNote.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: onToggleFavorite) {
                        Image(systemName: voiceNote.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(voiceNote.isFavorite ? .red : .gray)
                    }
                }
                
                HStack {
                    Image(systemName: voiceNote.category.icon)
                        .foregroundColor(voiceNote.category.color)
                        .font(.caption)
                    
                    Text(voiceNote.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(voiceNote.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar (if playing)
                if isPlaying {
                    ProgressView(value: 0.0) // This would be connected to actual progress
                        .progressViewStyle(LinearProgressViewStyle(tint: voiceNote.category.color))
                }
            }
            
            // Expand Button
            Button(action: onShowPlayer) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Full Screen Player
struct FullScreenPlayerView: View {
    let voiceNote: VoiceNote
    @ObservedObject var voiceNoteManager: VoiceNoteManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Album Art Placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [voiceNote.category.color.opacity(0.3), voiceNote.category.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 250, height: 250)
                    .overlay(
                        Image(systemName: voiceNote.category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(voiceNote.category.color)
                    )
                
                // Voice Note Info
                VStack(spacing: 8) {
                    Text(voiceNote.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(voiceNote.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress Section
                VStack(spacing: 16) {
                    // Progress Bar
                    ProgressView(value: voiceNoteManager.currentProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: voiceNote.category.color))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    // Time Labels
                    HStack {
                        Text(voiceNoteManager.formattedCurrentTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(voiceNoteManager.formattedRemainingTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 40)
                
                // Controls
                HStack(spacing: 40) {
                    // Previous Button
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .disabled(true)
                    
                    // Play/Pause Button
                    Button(action: {
                        if voiceNoteManager.isPlaying {
                            voiceNoteManager.pausePlayback()
                        } else {
                            voiceNoteManager.resumePlayback()
                        }
                    }) {
                        Image(systemName: voiceNoteManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(voiceNote.category.color)
                    }
                    
                    // Next Button
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .disabled(true)
                }
                
                // Speed Control
                HStack {
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $voiceNoteManager.playbackSpeed, in: 0.5...2.0, step: 0.25)
                        .accentColor(voiceNote.category.color)
                        .frame(width: 150)
                    
                    Text("\(voiceNoteManager.playbackSpeed, specifier: "%.1f")x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    VoiceNotePlayerView()
}

