import SwiftUI

struct RegisteredFacesView: View {
    @ObservedObject var faceManager: FaceRecognitionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var faceToDelete: RegisteredFace?
    
    var body: some View {
        NavigationView {
            VStack {
                if faceManager.registeredFaces.isEmpty {
                    RegisteredFacesEmptyStateView()
                } else {
                    List {
                        ForEach(faceManager.registeredFaces) { face in
                            RegisteredFaceRow(face: face) {
                                faceToDelete = face
                                showingDeleteAlert = true
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Registered Faces")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await faceManager.loadRegisteredFaces()
                }
            }
            .alert("Delete Face", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    faceToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let face = faceToDelete {
                        Task {
                            await faceManager.deleteFace(faceId: face.faceId)
                        }
                    }
                    faceToDelete = nil
                }
            } message: {
                if let face = faceToDelete {
                    Text("Are you sure you want to delete \(face.personName) from the recognition system?")
                }
            }
        }
    }
}

// MARK: - Empty State View
struct RegisteredFacesEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Registered Faces")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Register family members and friends to enable face recognition")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Registered Face Row
struct RegisteredFaceRow: View {
    let face: RegisteredFace
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(avatarColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(face.personName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Face Info
            VStack(alignment: .leading, spacing: 4) {
                Text(face.personName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(face.relationship)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !face.additionalInfo.isEmpty {
                    Text(face.additionalInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("Registered: \(formatDate(face.registeredAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .indigo]
        let index = abs(face.personName.hashValue) % colors.count
        return colors[index]
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        
        return "Unknown"
    }
}

// MARK: - Face Recognition Settings View
struct FaceRecognitionSettingsView: View {
    @ObservedObject var faceManager: FaceRecognitionManager
    @State private var recognitionTolerance: Double = 0.6
    @State private var isAutoRecognitionEnabled = true
    @State private var showingTestView = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Recognition Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recognition Tolerance")
                            Spacer()
                            Text("\(Int(recognitionTolerance * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $recognitionTolerance, in: 0.3...0.9, step: 0.1)
                            .accentColor(.blue)
                        
                        Text("Lower values = more strict matching")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Auto Recognition", isOn: $isAutoRecognitionEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Section("Testing") {
                    Button(action: {
                        showingTestView = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.blue)
                            Text("Test Recognition")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Registered Faces")
                        Spacer()
                        Text("\(faceManager.registeredFaces.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Recognition")
                        Spacer()
                        Text(faceManager.recognitionResults.isEmpty ? "None" : "Recent")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Face Recognition")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingTestView) {
            FaceRecognitionCameraView()
        }
    }
}

#Preview {
    RegisteredFacesView(faceManager: FaceRecognitionManager())
}
