//
//  AuthenticationView.swift
//  LovedOnes
//
//  User authentication and onboarding
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: UserAuthManager
    @State private var isSignUp = true
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var dateOfBirth = Date()
    @State private var emergencyContact = ""
    @State private var medicalConditions = ""
    @State private var medications = ""
    @State private var allergies = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    @State private var agreedToPrivacy = false
    @State private var showDatePicker = false
    @State private var validationErrors: [String] = []
    @State private var isFormValid = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Authentication Form
                    formSection
                    
                    // Footer
                    footerSection
                }
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.1), Color.pink.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
        .onAppear {
            validateForm()
            print("🔍 AuthenticationView appeared - isAuthenticated: \(authManager.isAuthenticated)")
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            print("🔍 Authentication state changed: \(isAuthenticated)")
        }
        .onChange(of: isSignUp) { _, _ in
            clearForm()
            validateForm()
        }
        .onChange(of: [name, email, password, confirmPassword, phone, emergencyContact].map { $0 }) { _, _ in
            validateForm()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Logo and Title
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("LovedOnes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Caring for those who matter most")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Mode Toggle
            HStack(spacing: 0) {
                Button(action: { isSignUp = true }) {
                    Text("Sign Up")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSignUp ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(isSignUp ? Color.red : Color.clear)
                        )
                }
                
                Button(action: { isSignUp = false }) {
                    Text("Sign In")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(!isSignUp ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(!isSignUp ? Color.red : Color.clear)
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 24) {
            if isSignUp {
                signUpForm
            } else {
                signInForm
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: 20) {
            // Basic Information Section
            formSection(title: "Basic Information", icon: "person.fill") {
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "Full Name",
                        text: $name,
                        icon: "person",
                        placeholder: "Enter your full name",
                        validation: validateName
                    )
                    
                    CustomTextField(
                        title: "Email Address",
                        text: $email,
                        icon: "envelope",
                        placeholder: "Enter your email",
                        keyboardType: .emailAddress,
                        validation: validateEmail
                    )
                    
                    CustomTextField(
                        title: "Phone Number",
                        text: $phone,
                        icon: "phone",
                        placeholder: "Enter your phone number",
                        keyboardType: .phonePad,
                        isOptional: true,
                        validation: { _ in nil }
                    )
                    
                    CustomPasswordField(
                        title: "Password",
                        text: $password,
                        showPassword: $showPassword,
                        placeholder: "Create a strong password",
                        validation: validatePassword
                    )
                    
                    CustomPasswordField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        showPassword: $showConfirmPassword,
                        placeholder: "Confirm your password",
                        validation: validateConfirmPassword
                    )
                }
            }
            
            // Personal Information Section
            formSection(title: "Personal Information", icon: "calendar") {
                VStack(spacing: 16) {
                    DatePickerField(
                        title: "Date of Birth",
                        date: $dateOfBirth,
                        showDatePicker: $showDatePicker
                    )
                    
                    CustomTextField(
                        title: "Emergency Contact",
                        text: $emergencyContact,
                        icon: "phone.circle",
                        placeholder: "Emergency contact phone number",
                        keyboardType: .phonePad,
                        isOptional: true,
                        validation: { _ in nil }
                    )
                }
            }
            
            // Health Information Section
            formSection(title: "Health Information", icon: "heart.fill") {
                VStack(spacing: 16) {
                    CustomTextArea(
                        title: "Medical Conditions",
                        text: $medicalConditions,
                        placeholder: "List any medical conditions (optional)",
                        isOptional: true
                    )
                    
                    CustomTextArea(
                        title: "Current Medications",
                        text: $medications,
                        placeholder: "List current medications (optional)",
                        isOptional: true
                    )
                    
                    CustomTextArea(
                        title: "Allergies",
                        text: $allergies,
                        placeholder: "List any allergies (optional)",
                        isOptional: true
                    )
                }
            }
            
            // Terms and Conditions
            termsSection
            
            // Action Button
            actionButton
        }
    }
    
    // MARK: - Sign In Form
    private var signInForm: some View {
        VStack(spacing: 20) {
            formSection(title: "Sign In", icon: "person.circle") {
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "Email Address",
                        text: $email,
                        icon: "envelope",
                        placeholder: "Enter your email",
                        keyboardType: .emailAddress,
                        validation: validateEmail
                    )
                    
                    CustomPasswordField(
                        title: "Password",
                        text: $password,
                        showPassword: $showPassword,
                        placeholder: "Enter your password",
                        validation: validateSignInPassword
                    )
                }
            }
            
            // Quick Login Section
            VStack(spacing: 16) {
                Text("Quick Demo Access")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // David (Patient) Login
                    Button(action: {
                        authManager.loginAsDavid()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                            Text("David")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Patient")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        )
                        .foregroundColor(.green)
                    }
                    
                    // Alex (Caregiver) Login
                    Button(action: {
                        authManager.loginAsAlex()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.circle.fill")
                                .font(.title2)
                            Text("Alex")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Caregiver")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        )
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
            
            // Action Button
            actionButton
        }
    }
    
    // MARK: - Form Section Helper
    private func formSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.red)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: { agreedToTerms.toggle() }) {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? .red : .gray)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree to the")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    +
                    Text(" Terms of Service")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .underline()
                    +
                    Text(" and")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    +
                    Text(" Privacy Policy")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .underline()
                }
            }
            
            HStack(alignment: .top, spacing: 12) {
                Button(action: { agreedToPrivacy.toggle() }) {
                    Image(systemName: agreedToPrivacy ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToPrivacy ? .red : .gray)
                        .font(.title3)
                }
                
                Text("I consent to the collection and processing of my health data for emergency and care purposes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        VStack(spacing: 16) {
            Button(action: handleAuthentication) {
                HStack(spacing: 12) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isSignUp ? "person.badge.plus" : "person.circle")
                            .font(.headline)
                    }
                    
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isFormValid ? [Color.red, Color.pink] : [Color.gray]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(color: isFormValid ? .red.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            }
            .disabled(authManager.isLoading || !isFormValid)
            .scaleEffect(authManager.isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: authManager.isLoading)
            
            // Error Messages
            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(validationErrors, id: \.self) { error in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
            }
            
            // Debug Button
            Button("Test Authentication (Debug)") {
                authManager.isAuthenticated = true
                authManager.currentUser = User(
                    id: "test-id",
                    name: "Test User",
                    email: "test@example.com",
                    phone: nil,
                    createdAt: "2025-01-01T00:00:00Z"
                )
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Handle terms
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Privacy Policy") {
                        // Handle privacy
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.bottom, 30)
        .padding(.top, 20)
    }
    
    private func handleAuthentication() {
        Task {
            if isSignUp {
                await authManager.signUp(
                    name: name,
                    email: email,
                    phone: phone.isEmpty ? nil : phone
                )
            } else {
                await authManager.signIn(email: email)
            }
        }
    }
    
    // MARK: - Validation Functions
    private func validateForm() {
        validationErrors.removeAll()
        
        if isSignUp {
            validateSignUpForm()
        } else {
            validateSignInForm()
        }
        
        isFormValid = validationErrors.isEmpty && (isSignUp ? agreedToTerms && agreedToPrivacy : true)
    }
    
    private func validateSignUpForm() {
        if name.isEmpty {
            validationErrors.append("Full name is required")
        }
        
        if email.isEmpty {
            validationErrors.append("Email address is required")
        } else if !isValidEmail(email) {
            validationErrors.append("Please enter a valid email address")
        }
        
        if password.isEmpty {
            validationErrors.append("Password is required")
        } else if password.count < 8 {
            validationErrors.append("Password must be at least 8 characters long")
        }
        
        if confirmPassword.isEmpty {
            validationErrors.append("Please confirm your password")
        } else if password != confirmPassword {
            validationErrors.append("Passwords do not match")
        }
        
        if !phone.isEmpty && !isValidPhone(phone) {
            validationErrors.append("Please enter a valid phone number")
        }
        
        if !emergencyContact.isEmpty && !isValidPhone(emergencyContact) {
            validationErrors.append("Please enter a valid emergency contact number")
        }
    }
    
    private func validateSignInForm() {
        if email.isEmpty {
            validationErrors.append("Email address is required")
        } else if !isValidEmail(email) {
            validationErrors.append("Please enter a valid email address")
        }
        
        if password.isEmpty {
            validationErrors.append("Password is required")
        }
    }
    
    private func validateName(_ text: String) -> String? {
        if text.isEmpty {
            return "Full name is required"
        }
        if text.count < 2 {
            return "Name must be at least 2 characters"
        }
        return nil
    }
    
    private func validateEmail(_ text: String) -> String? {
        if text.isEmpty {
            return "Email address is required"
        }
        if !isValidEmail(text) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    private func validatePassword(_ text: String) -> String? {
        if text.isEmpty {
            return "Password is required"
        }
        if text.count < 8 {
            return "Password must be at least 8 characters"
        }
        if !hasUppercase(text) {
            return "Password must contain at least one uppercase letter"
        }
        if !hasLowercase(text) {
            return "Password must contain at least one lowercase letter"
        }
        if !hasNumber(text) {
            return "Password must contain at least one number"
        }
        return nil
    }
    
    private func validateConfirmPassword(_ text: String) -> String? {
        if text.isEmpty {
            return "Please confirm your password"
        }
        if text != password {
            return "Passwords do not match"
        }
        return nil
    }
    
    private func validateSignInPassword(_ text: String) -> String? {
        if text.isEmpty {
            return "Password is required"
        }
        return nil
    }
    
    // MARK: - Helper Functions
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone.replacingOccurrences(of: " ", with: ""))
    }
    
    private func hasUppercase(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    private func hasLowercase(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .lowercaseLetters) != nil
    }
    
    private func hasNumber(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private func clearForm() {
        name = ""
        email = ""
        phone = ""
        password = ""
        confirmPassword = ""
        emergencyContact = ""
        medicalConditions = ""
        medications = ""
        allergies = ""
        agreedToTerms = false
        agreedToPrivacy = false
        validationErrors.removeAll()
    }
}

// MARK: - Custom UI Components

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isOptional: Bool = false
    var validation: (String) -> String?
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isOptional {
                    Text("(Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let error = errorMessage {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                } else if !text.isEmpty && validation(text) == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .onChange(of: text) { _, _ in
                        if !text.isEmpty {
                            validateField()
                        }
                    }
                    .onSubmit {
                        validateField()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 2)
                    )
            )
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func validateField() {
        errorMessage = validation(text)
    }
}

struct CustomPasswordField: View {
    let title: String
    @Binding var text: String
    @Binding var showPassword: Bool
    let placeholder: String
    var validation: (String) -> String?
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let error = errorMessage {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                } else if !text.isEmpty && validation(text) == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .frame(width: 20)
                
                if showPassword {
                    TextField(placeholder, text: $text)
                        .onChange(of: text) { _, _ in
                            if !text.isEmpty {
                                validateField()
                            }
                        }
                        .onSubmit {
                            validateField()
                        }
                } else {
                    SecureField(placeholder, text: $text)
                        .onChange(of: text) { _, _ in
                            if !text.isEmpty {
                                validateField()
                            }
                        }
                        .onSubmit {
                            validateField()
                        }
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 2)
                    )
            )
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func validateField() {
        errorMessage = validation(text)
    }
}

struct CustomTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isOptional: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isOptional {
                    Text("(Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            VStack {
                                HStack {
                                    Text(placeholder)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }
}

struct DatePickerField: View {
    let title: String
    @Binding var date: Date
    @Binding var showDatePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Button(action: { showDatePicker.toggle() }) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .frame(width: 20)
                    
                    Text(dateFormatter.string(from: date))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    DatePicker("Select Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarItems(
                            leading: Button("Cancel") { showDatePicker = false },
                            trailing: Button("Done") { showDatePicker = false }
                        )
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(UserAuthManager())
    }
}
