//
//  RegisterView.swift
//  calorie tracker
//
//  Created by Tao Jin on 2/17/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Binding var currentView: ContentView.AppView
    
    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding()
            
            VStack(alignment: .leading) {
                Text("Email")
                    .font(.headline)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(isLoading)

                Text("Password")
                    .font(.headline)
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
            }
            .padding()
            
            Button(action: loginWithEmail) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isLoading)
            .padding()
            
            VStack {
                Button("Register Now") {
                    currentView = .register
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading)
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func loginWithEmail() {
            if email.isEmpty || password.isEmpty {
                errorMessage = "Email and Password cannot be empty"
                return
            }
            
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                errorMessage = "Please enter a valid email address"
                return
            }
            
            isLoading = true
            errorMessage = nil
            
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                // Login successful - check for existing goals
                checkUserOnboardingStatus()
            }
        }
        
        private func checkUserOnboardingStatus() {
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User not found"
                return
            }
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)
            
            userRef.getDocument { snapshot, error in
                if let error = error {
                    errorMessage = "Error checking user status: \(error.localizedDescription)"
                    return
                }
                
                if let data = snapshot?.data(),
                   let goals = data["goals"] as? [String: Any],
                   let _ = goals["calories"] as? Double,
                   let _ = goals["protein"] as? Double,
                   let _ = goals["water"] as? Double {
                    // User has completed onboarding
                    DispatchQueue.main.async {
                        currentView = .main
                    }
                } else {
                    // User needs to complete onboarding
                    DispatchQueue.main.async {
                        currentView = .onboarding
                    }
                }
            }
        }
    }
