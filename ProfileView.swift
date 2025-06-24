//
//  ProfileView.swift
//  Calorie Tracker
//
//  
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var userName: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var birthDate: Date = Date()
    @State private var targetWeight: String = ""
    @Binding var currentView: ContentView.AppView
    
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Profile Image
                Button(action: { showImagePicker = true }) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Profile Form
                Form {
                    Section(header: Text("Body Metrics")) {
                        ProfileRow(title: "User Name", value: $userName)
                        ProfileRow(title: "Age", value: $age, isNumeric: true)
                        ProfileRow(title: "Height", value: $height, unit: "cm", isDecimal: true)
                        ProfileRow(title: "Weight", value: $weight, unit: "kg", isDecimal: true)
                        
                        HStack {
                            Text("Birth Date")
                            Spacer()
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        ProfileRow(title: "Target Weight", value: $targetWeight, unit: "kg", isDecimal: true)
                    }
                    
                    Section(header: Text("Preferences")) {
                        Text("Unit System: Metric")
                        Text("Notifications: Enabled")
                    }
                    
                    Section {
                        Button(action: logout) {
                            Text("Logout")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    }
                }
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveProfileData()
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                }
            }
        }
        .onAppear(perform: loadProfileData)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $profileImage)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadProfileData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Failed to load profile: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let data = snapshot?.data(),
                  let profile = data["profile"] as? [String: Any] else {
                // New user, no profile data yet
                return
            }
            
            DispatchQueue.main.async {
                userName = profile["userName"] as? String ?? ""
                age = "\(profile["age"] as? Int ?? 0)"
                height = String(format: "%.1f", profile["height"] as? Double ?? 0.0)
                weight = String(format: "%.1f", profile["weight"] as? Double ?? 0.0)
                targetWeight = String(format: "%.1f", profile["targetWeight"] as? Double ?? 0.0)
                
                if let birthDateString = profile["birthDate"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    birthDate = formatter.date(from: birthDateString) ?? Date()
                }
                
                if let imageString = profile["profileImage"] as? String {
                    profileImage = decodeImage(from: imageString)
                }
            }
        }
    }
    
    private func saveProfileData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var profileData: [String: Any] = [
            "profile": [
                "userName": userName,
                "age": Int(age) ?? 0,
                "height": Double(height) ?? 0.0,
                "weight": Double(weight) ?? 0.0,
                "birthDate": formatter.string(from: birthDate),
                "targetWeight": Double(targetWeight) ?? 0.0
            ]
        ]
        
        // Add image if available
        if let image = profileImage {
            if let imageString = encodeImage(image) {
                if var profile = profileData["profile"] as? [String: Any] {
                    profile["profileImage"] = imageString
                    profileData["profile"] = profile
                }
            }
        }
        
        userRef.setData(profileData, merge: true) { error in
            isLoading = false
            if let error = error {
                alertMessage = "Failed to save profile: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func encodeImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
        return imageData.base64EncodedString()
    }
    
    private func decodeImage(from base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: imageData)
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            currentView = .login
        } catch {
            alertMessage = "Logout failed: \(error.localizedDescription)"
            showAlert = true
        }
    }
}


struct ProfileRow: View {
    let title: String
    @Binding var value: String
    var unit: String? = nil
    var isNumeric: Bool = false
    var isDecimal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack {
                TextField("", text: $value)
                    .keyboardType(isDecimal ? .decimalPad : (isNumeric ? .numberPad : .default))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.gray)
                
                if let unit = unit {
                    Text(unit)
                        .foregroundColor(.gray)
                }
            }
        }
        .onChange(of: value) { oldValue, newValue in
            var filtered = newValue
            
            if isNumeric {
                filtered = newValue.filter { "0123456789".contains($0) }
            } else if isDecimal {
                filtered = newValue.filter { "0123456789.".contains($0) }
                let components = filtered.components(separatedBy: ".")
                if components.count > 2 {
                    filtered = components[0] + "." + components[1]
                }
            }
            
            if filtered != newValue {
                value = filtered
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
    }
}
