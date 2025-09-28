//
//  FamilyMemberManager.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import PhotosUI

// MARK: - Family Member Model
struct FamilyMember: Identifiable, Codable {
    let id = UUID()
    let name: String
    let relationship: String
    let photoData: Data?
    let dateAdded: Date
    let notes: String
    
    var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
}

// MARK: - Family Member Manager
class FamilyMemberManager: ObservableObject {
    @Published var familyMembers: [FamilyMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let faceService = AzureFaceService.shared
    
    init() {
        loadFamilyMembers()
    }
    
    // MARK: - Data Management
    func addFamilyMember(name: String, relationship: String, photo: UIImage?, notes: String) {
        isLoading = true
        
        let photoData = photo?.jpegData(compressionQuality: 0.8)
        let newMember = FamilyMember(
            name: name,
            relationship: relationship,
            photoData: photoData,
            dateAdded: Date(),
            notes: notes
        )
        
        familyMembers.append(newMember)
        saveFamilyMembers()
        
        // Add to Azure Face API
        if let photo = photo {
            Task {
                do {
                    try await faceService.addFamilyMember(name: name, image: photo)
                    await MainActor.run {
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to add to face recognition: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
    
    func removeFamilyMember(_ member: FamilyMember) {
        familyMembers.removeAll { $0.id == member.id }
        saveFamilyMembers()
    }
    
    func updateFamilyMember(_ member: FamilyMember, name: String, relationship: String, photo: UIImage?, notes: String) {
        if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
            let photoData = photo?.jpegData(compressionQuality: 0.8)
            familyMembers[index] = FamilyMember(
                name: name,
                relationship: relationship,
                photoData: photoData,
                dateAdded: member.dateAdded,
                notes: notes
            )
            saveFamilyMembers()
        }
    }
    
    // MARK: - Persistence
    private func saveFamilyMembers() {
        if let data = try? JSONEncoder().encode(familyMembers) {
            UserDefaults.standard.set(data, forKey: "familyMembers")
        }
    }
    
    private func loadFamilyMembers() {
        if let data = UserDefaults.standard.data(forKey: "familyMembers"),
           let members = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            familyMembers = members
        }
    }
}

// MARK: - Add Family Member View
struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyManager = FamilyMemberManager()
    @State private var name = ""
    @State private var relationship = ""
    @State private var notes = ""
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    
    let onSave: (FamilyMember) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Family Member Details") {
                    TextField("Name", text: $name)
                    TextField("Relationship (e.g., Mother, Father, Sister)", text: $relationship)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Photo") {
                    if let selectedPhoto = selectedPhoto {
                        HStack {
                            Image(uiImage: selectedPhoto)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("Photo Selected")
                                    .font(.headline)
                                
                                Button("Change Photo") {
                                    showingPhotoPicker = true
                                }
                                .font(.caption)
                            }
                            
                            Spacer()
                        }
                    } else {
                        Button("Add Photo") {
                            showingPhotoPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button("Save Family Member") {
                        let newMember = FamilyMember(
                            name: name,
                            relationship: relationship,
                            photoData: selectedPhoto?.jpegData(compressionQuality: 0.8),
                            dateAdded: Date(),
                            notes: notes
                        )
                        onSave(newMember)
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(selectedImage: $selectedPhoto)
            }
        }
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Family Member Card
struct FamilyMemberCard: View {
    let member: FamilyMember
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo
            if let photo = member.photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(30)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(member.relationship)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if !member.notes.isEmpty {
                    Text(member.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("Added \(member.dateAdded, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Family Members List View
struct FamilyMembersListView: View {
    @StateObject private var familyManager = FamilyMemberManager()
    @State private var showingAddMember = false
    @State private var selectedMember: FamilyMember?
    @State private var showingEditMember = false
    
    var body: some View {
        NavigationView {
            VStack {
                if familyManager.familyMembers.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Family Members Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text("Add your family members to enable face recognition and personalized reminders")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Add First Family Member") {
                            showingAddMember = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    // Family members list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(familyManager.familyMembers) { member in
                                FamilyMemberCard(
                                    member: member,
                                    onEdit: {
                                        selectedMember = member
                                        showingEditMember = true
                                    },
                                    onDelete: {
                                        familyManager.removeFamilyMember(member)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddMember = true
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView { newMember in
                    familyManager.addFamilyMember(
                        name: newMember.name,
                        relationship: newMember.relationship,
                        photo: newMember.photo,
                        notes: newMember.notes
                    )
                    showingAddMember = false
                }
            }
            .sheet(isPresented: $showingEditMember) {
                if let member = selectedMember {
                    EditFamilyMemberView(member: member) { updatedMember in
                        familyManager.updateFamilyMember(
                            updatedMember,
                            name: updatedMember.name,
                            relationship: updatedMember.relationship,
                            photo: updatedMember.photo,
                            notes: updatedMember.notes
                        )
                        showingEditMember = false
                    }
                }
            }
        }
    }
}

// MARK: - Edit Family Member View
struct EditFamilyMemberView: View {
    let member: FamilyMember
    let onSave: (FamilyMember) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var relationship: String
    @State private var notes: String
    @State private var selectedPhoto: UIImage?
    @State private var showingPhotoPicker = false
    
    init(member: FamilyMember, onSave: @escaping (FamilyMember) -> Void) {
        self.member = member
        self.onSave = onSave
        self._name = State(initialValue: member.name)
        self._relationship = State(initialValue: member.relationship)
        self._notes = State(initialValue: member.notes)
        self._selectedPhoto = State(initialValue: member.photo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Family Member Details") {
                    TextField("Name", text: $name)
                    TextField("Relationship", text: $relationship)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Photo") {
                    if let selectedPhoto = selectedPhoto {
                        HStack {
                            Image(uiImage: selectedPhoto)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                            
                            Button("Change Photo") {
                                showingPhotoPicker = true
                            }
                            .font(.caption)
                            
                            Spacer()
                        }
                    } else {
                        Button("Add Photo") {
                            showingPhotoPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        let updatedMember = FamilyMember(
                            name: name,
                            relationship: relationship,
                            photoData: selectedPhoto?.jpegData(compressionQuality: 0.8),
                            dateAdded: member.dateAdded,
                            notes: notes
                        )
                        onSave(updatedMember)
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
            .navigationTitle("Edit Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(selectedImage: $selectedPhoto)
            }
        }
    }
}



