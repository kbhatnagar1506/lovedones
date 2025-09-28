//
//  ProfessionalAuthView.swift
//  lovedones
//
//  Created by Krishna Bhatnagar on 9/28/25.
//

import SwiftUI
import PhotosUI
import AuthenticationServices

struct ProfessionalAuthView: View {
    @EnvironmentObject var authManager: UserAuthManager
    @State private var isSignUp = false
    @State private var currentStep = 0
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    
    // Form Data
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var relationship = ""
    @State private var emergencyContact = ""
    @State private var medicalConditions = ""
    @State private var medications = ""
    @State private var allergies = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = ""
    @State private var preferredLanguage = "English"
    @State private var timeZone = "UTC"
    @State private var notificationPreferences = true
    @State private var dataSharing = false
    @State private var termsAccepted = false
    
    let relationshipOptions = [
        "Spouse", "Child", "Parent", "Sibling", "Grandparent", 
        "Grandchild", "Cousin", "Friend", "Caregiver", "Other"
    ]
    
    let languageOptions = [
        "English", "Spanish", "French", "German", "Italian", 
        "Portuguese", "Chinese", "Japanese", "Korean", "Arabic"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Match Dashboard
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
                    VStack(spacing: 30) {
                        // Header - Match Dashboard Design
                        VStack(spacing: LovedOnesDesignSystem.spaceL) {
                            // Logo
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .scaleEffect(logoScale)
                                .animation(.spring(response: 0.7, dampingFraction: 0.5, blendDuration: 0.5), value: logoScale)
                            
                            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(LovedOnesDesignSystem.titleFont)
                                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                    .opacity(textOpacity)
                                    .animation(.easeIn(duration: 1.0).delay(0.5), value: textOpacity)
                                
                                Text(isSignUp ? "Join the LovedOnes family" : "Sign in to continue")
                                    .font(LovedOnesDesignSystem.subheadingFont)
                                    .foregroundColor(LovedOnesDesignSystem.textSecondary)
                                    .opacity(textOpacity)
                                    .animation(.easeIn(duration: 1.0).delay(0.8), value: textOpacity)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Progress Indicator (for signup) - Match Dashboard
                        if isSignUp {
                            ProgressView(value: Double(currentStep), total: 4)
                                .progressViewStyle(LinearProgressViewStyle(tint: LovedOnesDesignSystem.primaryRed))
                                .scaleEffect(y: 2)
                                .padding(.horizontal, LovedOnesDesignSystem.spaceXL)
                        }
                        
                        // Form Content - Match Dashboard Spacing
                        VStack(spacing: LovedOnesDesignSystem.spaceL) {
                            if isSignUp {
                                SignUpFormView(
                                    currentStep: $currentStep,
                                    email: $email,
                                    password: $password,
                                    confirmPassword: $confirmPassword,
                                    fullName: $fullName,
                                    phoneNumber: $phoneNumber,
                                    dateOfBirth: $dateOfBirth,
                                    relationship: $relationship,
                                    emergencyContact: $emergencyContact,
                                    medicalConditions: $medicalConditions,
                                    medications: $medications,
                                    allergies: $allergies,
                                    address: $address,
                                    city: $city,
                                    state: $state,
                                    zipCode: $zipCode,
                                    country: $country,
                                    preferredLanguage: $preferredLanguage,
                                    timeZone: $timeZone,
                                    notificationPreferences: $notificationPreferences,
                                    dataSharing: $dataSharing,
                                    termsAccepted: $termsAccepted,
                                    profileImage: $profileImage,
                                    showingImagePicker: $showingImagePicker,
                                    relationshipOptions: relationshipOptions,
                                    languageOptions: languageOptions
                                )
                            } else {
                                SignInFormView(
                                    email: $email,
                                    password: $password
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Toggle Auth Mode
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                                currentStep = 0
                            }
                        }) {
                            HStack {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(.white.opacity(0.8))
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 16))
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                profileImage = image
            }
        }
        .onAppear {
            logoScale = 1.0
            textOpacity = 1.0
        }
    }
}

// MARK: - Sign In Form
struct SignInFormView: View {
    @EnvironmentObject var authManager: UserAuthManager
    @Binding var email: String
    @Binding var password: String
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceL) {
            // Email Field
            VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
                Text("Email Address")
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(ProfessionalTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
                Text("Password")
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(ProfessionalTextFieldStyle())
            }
            
            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    // Handle forgot password
                }
                .font(LovedOnesDesignSystem.captionFont)
                .foregroundColor(LovedOnesDesignSystem.textSecondary)
            }
            
            // Sign In Button
            Button(action: {
                Task {
                    await authManager.signIn(email: email)
                }
            }) {
                Text("Sign In")
                    .font(LovedOnesDesignSystem.buttonFont)
                    .foregroundColor(LovedOnesDesignSystem.pureWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LovedOnesDesignSystem.spaceM)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                LovedOnesDesignSystem.primaryRed,
                                LovedOnesDesignSystem.secondaryRed
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(LovedOnesDesignSystem.radiusM)
            }
            .shadow(
                color: LovedOnesDesignSystem.primaryRed.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            
            // Divider
            HStack {
                Rectangle()
                    .fill(LovedOnesDesignSystem.mediumGray)
                    .frame(height: 1)
                
                Text("or")
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.textSecondary)
                    .padding(.horizontal, LovedOnesDesignSystem.spaceM)
                
                Rectangle()
                    .fill(LovedOnesDesignSystem.mediumGray)
                    .frame(height: 1)
            }
            .padding(.vertical, LovedOnesDesignSystem.spaceM)
            
            // Sign in with Apple
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            let userIdentifier = appleIDCredential.user
                            let fullName = appleIDCredential.fullName
                            let email = appleIDCredential.email
                            
                            // Handle successful Apple Sign In
                            print("Apple Sign In successful: \(userIdentifier)")
                            // You can add your authentication logic here
                            
                        default:
                            break
                        }
                    case .failure(let error):
                        print("Apple Sign In failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(LovedOnesDesignSystem.radiusM)
        }
    }
}

// MARK: - Sign Up Form
struct SignUpFormView: View {
    @EnvironmentObject var authManager: UserAuthManager
    @Binding var currentStep: Int
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var fullName: String
    @Binding var phoneNumber: String
    @Binding var dateOfBirth: Date
    @Binding var relationship: String
    @Binding var emergencyContact: String
    @Binding var medicalConditions: String
    @Binding var medications: String
    @Binding var allergies: String
    @Binding var address: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var country: String
    @Binding var preferredLanguage: String
    @Binding var timeZone: String
    @Binding var notificationPreferences: Bool
    @Binding var dataSharing: Bool
    @Binding var termsAccepted: Bool
    @Binding var profileImage: UIImage?
    @Binding var showingImagePicker: Bool
    let relationshipOptions: [String]
    let languageOptions: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            switch currentStep {
            case 0:
                BasicInfoStep(
                    email: $email,
                    password: $password,
                    confirmPassword: $confirmPassword,
                    fullName: $fullName,
                    phoneNumber: $phoneNumber,
                    dateOfBirth: $dateOfBirth,
                    profileImage: $profileImage,
                    showingImagePicker: $showingImagePicker
                )
            case 1:
                RelationshipStep(
                    relationship: $relationship,
                    emergencyContact: $emergencyContact,
                    relationshipOptions: relationshipOptions
                )
            case 2:
                MedicalInfoStep(
                    medicalConditions: $medicalConditions,
                    medications: $medications,
                    allergies: $allergies
                )
            case 3:
                LocationStep(
                    address: $address,
                    city: $city,
                    state: $state,
                    zipCode: $zipCode,
                    country: $country,
                    preferredLanguage: $preferredLanguage,
                    timeZone: $timeZone,
                    languageOptions: languageOptions
                )
            case 4:
                PreferencesStep(
                    notificationPreferences: $notificationPreferences,
                    dataSharing: $dataSharing,
                    termsAccepted: $termsAccepted
                )
            default:
                EmptyView()
            }
            
            // Navigation Buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
                
                Button(currentStep == 4 ? "Create Account" : "Next") {
                    if currentStep < 4 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    } else {
                        // Handle account creation
                        Task {
                            await authManager.signUp(
                                name: fullName,
                                email: email,
                                phone: phoneNumber
                            )
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isStepValid)
            }
        }
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password == confirmPassword
        case 1:
            return !relationship.isEmpty && !emergencyContact.isEmpty
        case 2:
            return true // Medical info is optional
        case 3:
            return !address.isEmpty && !city.isEmpty
        case 4:
            return termsAccepted
        default:
            return false
        }
    }
}

// MARK: - Step Views
struct BasicInfoStep: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var fullName: String
    @Binding var phoneNumber: String
    @Binding var dateOfBirth: Date
    @Binding var profileImage: UIImage?
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Basic Information")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            // Profile Photo
            VStack(spacing: 12) {
                Button(action: { showingImagePicker = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                Text("Add Photo")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                Text("Tap to add profile photo")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Form Fields
            VStack(spacing: 16) {
                ProfessionalTextField(
                    title: "Full Name",
                    text: $fullName,
                    placeholder: "Enter your full name"
                )
                
                ProfessionalTextField(
                    title: "Email Address",
                    text: $email,
                    placeholder: "Enter your email",
                    keyboardType: .emailAddress
                )
                
                ProfessionalTextField(
                    title: "Phone Number",
                    text: $phoneNumber,
                    placeholder: "Enter your phone number",
                    keyboardType: .phonePad
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                ProfessionalTextField(
                    title: "Password",
                    text: $password,
                    placeholder: "Create a password",
                    isSecure: true
                )
                
                ProfessionalTextField(
                    title: "Confirm Password",
                    text: $confirmPassword,
                    placeholder: "Confirm your password",
                    isSecure: true
                )
            }
            
            // Divider
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 16)
            
            // Sign in with Apple
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            let userIdentifier = appleIDCredential.user
                            let fullName = appleIDCredential.fullName
                            let email = appleIDCredential.email
                            
                            // Handle successful Apple Sign In
                            print("Apple Sign In successful: \(userIdentifier)")
                            // You can add your authentication logic here
                            
                        default:
                            break
                        }
                    case .failure(let error):
                        print("Apple Sign In failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(8)
        }
    }
}

struct RelationshipStep: View {
    @Binding var relationship: String
    @Binding var emergencyContact: String
    let relationshipOptions: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Relationship & Emergency Contact")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relationship to Patient")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Picker("Relationship", selection: $relationship) {
                        ForEach(relationshipOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                
                ProfessionalTextField(
                    title: "Emergency Contact",
                    text: $emergencyContact,
                    placeholder: "Name and phone number"
                )
            }
        }
    }
}

struct MedicalInfoStep: View {
    @Binding var medicalConditions: String
    @Binding var medications: String
    @Binding var allergies: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Medical Information (Optional)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                ProfessionalTextField(
                    title: "Medical Conditions",
                    text: $medicalConditions,
                    placeholder: "List any medical conditions",
                    isMultiline: true
                )
                
                ProfessionalTextField(
                    title: "Current Medications",
                    text: $medications,
                    placeholder: "List current medications",
                    isMultiline: true
                )
                
                ProfessionalTextField(
                    title: "Allergies",
                    text: $allergies,
                    placeholder: "List any allergies",
                    isMultiline: true
                )
            }
        }
    }
}

struct LocationStep: View {
    @Binding var address: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var country: String
    @Binding var preferredLanguage: String
    @Binding var timeZone: String
    let languageOptions: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Location & Preferences")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                ProfessionalTextField(
                    title: "Address",
                    text: $address,
                    placeholder: "Street address"
                )
                
                HStack(spacing: 12) {
                    ProfessionalTextField(
                        title: "City",
                        text: $city,
                        placeholder: "City"
                    )
                    
                    ProfessionalTextField(
                        title: "State",
                        text: $state,
                        placeholder: "State"
                    )
                }
                
                HStack(spacing: 12) {
                    ProfessionalTextField(
                        title: "ZIP Code",
                        text: $zipCode,
                        placeholder: "ZIP"
                    )
                    
                    ProfessionalTextField(
                        title: "Country",
                        text: $country,
                        placeholder: "Country"
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Language")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Picker("Language", selection: $preferredLanguage) {
                        ForEach(languageOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct PreferencesStep: View {
    @Binding var notificationPreferences: Bool
    @Binding var dataSharing: Bool
    @Binding var termsAccepted: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Preferences & Terms")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                Toggle("Enable Notifications", isOn: $notificationPreferences)
                    .toggleStyle(ProfessionalToggleStyle())
                
                Toggle("Share Data for Research", isOn: $dataSharing)
                    .toggleStyle(ProfessionalToggleStyle())
                
                Toggle("I agree to Terms & Conditions", isOn: $termsAccepted)
                    .toggleStyle(ProfessionalToggleStyle())
            }
        }
    }
}

// MARK: - Custom Components
struct ProfessionalTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            } else if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(ProfessionalTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(ProfessionalTextFieldStyle())
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
    }
}

struct ProfessionalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(LovedOnesDesignSystem.spaceM)
            .background(LovedOnesDesignSystem.lightGray)
            .cornerRadius(LovedOnesDesignSystem.radiusS)
            .foregroundColor(LovedOnesDesignSystem.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusS)
                    .stroke(LovedOnesDesignSystem.mediumGray, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LovedOnesDesignSystem.buttonFont)
            .foregroundColor(LovedOnesDesignSystem.pureWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LovedOnesDesignSystem.spaceM)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        LovedOnesDesignSystem.primaryRed,
                        LovedOnesDesignSystem.secondaryRed
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(LovedOnesDesignSystem.radiusM)
            .shadow(
                color: LovedOnesDesignSystem.primaryRed.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LovedOnesDesignSystem.buttonFont)
            .foregroundColor(LovedOnesDesignSystem.primaryRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LovedOnesDesignSystem.spaceM)
            .background(LovedOnesDesignSystem.lightGray)
            .cornerRadius(LovedOnesDesignSystem.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                    .stroke(LovedOnesDesignSystem.primaryRed, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ProfessionalToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Spacer()
            
            Toggle("", isOn: configuration.$isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.white))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Image Picker (using existing one from FaceRegistrationView)

// MARK: - PREVIEW
struct ProfessionalAuthView_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalAuthView()
    }
}
