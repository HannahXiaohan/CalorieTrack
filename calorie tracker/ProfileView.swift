//
//  ProfileView.swift
//  Calorie Tracker
//
//  Created by Tao Jin on 2/26/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

// Enum for Unit System
enum UnitSystem: String, CaseIterable, Codable {
    case metric = "Metric"
    case imperial = "Imperial"
}

struct ProfileView: View {
    @State private var userName: String = ""
    @State private var age: String = ""
    @State private var metricHeightCm: Double = 0.0
    @State private var metricWeightKg: Double = 0.0
    @State private var metricTargetWeightKg: Double = 0.0
    @State private var displayHeight: String = ""
    @State private var displayWeight: String = ""
    @State private var displayTargetWeight: String = ""
    @State private var birthDate: Date = Date()
    @Binding var currentView: ContentView.AppView
    
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var unitSystem: UnitSystem = .metric
    
    private var heightUnit: String { unitSystem == .metric ? "cm" : "in" }
    private var weightUnit: String { unitSystem == .metric ? "kg" : "lb" }
    
    var body: some View {
        NavigationView {
            VStack {
                // Profile Image
                Button(action: { showImagePicker = true }) {
                    Group {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                    }
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
                }
                .padding(.vertical)
                
                // Profile Form
                Form {
                    Section(header: Text("Body Metrics")) {
                        ProfileRow(title: "User Name", value: $userName)
                        ProfileRow(title: "Age", value: $age, isNumeric: true)
                        ProfileRow(title: "Height", value: $displayHeight, unit: heightUnit, isDecimal: true)
                        ProfileRow(title: "Weight", value: $displayWeight, unit: weightUnit, isDecimal: true)
                        
                        HStack {
                            Text("Birth Date")
                            Spacer()
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        ProfileRow(title: "Target Weight", value: $displayTargetWeight, unit: weightUnit, isDecimal: true)
                    }
                    
                    Section(header: Text("Preferences")) {
                        Picker("Unit System", selection: $unitSystem) {
                            ForEach(UnitSystem.allCases, id: \.self) { system in
                                Text(system.rawValue).tag(system)
                            }
                        }
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
                .onChange(of: unitSystem) { _, _ in
                    updateDisplayValues()
                }
                .onChange(of: displayHeight) { _, newValue in
                    updateMetricHeight(from: newValue)
                }
                .onChange(of: displayWeight) { _, newValue in
                    updateMetricWeight(from: newValue)
                }
                .onChange(of: displayTargetWeight) { _, newValue in
                    updateMetricTargetWeight(from: newValue)
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
        .alert("Info", isPresented: $showAlert) {
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
            
            guard let data = snapshot?.data() else {
                updateDisplayValues()
                return
            }
            
            DispatchQueue.main.async {
                // Load preferences directly from the top level
                if let savedUnitSystem = data["unitSystem"] as? String,
                   let system = UnitSystem(rawValue: savedUnitSystem) {
                    unitSystem = system
                } else {
                    unitSystem = .metric // Default if not found or invalid
                }
                
                // Load profile data directly from the top level
                userName = data["userName"] as? String ?? ""
                age = "\(data["age"] as? Int ?? 0)"
                metricHeightCm = data["height"] as? Double ?? 0.0
                metricWeightKg = data["weight"] as? Double ?? 0.0
                metricTargetWeightKg = data["targetWeight"] as? Double ?? 0.0
                
                if let birthDateString = data["birthDate"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    birthDate = formatter.date(from: birthDateString) ?? Date()
                }
                
                if let imageString = data["profileImage"] as? String {
                    profileImage = decodeImage(from: imageString)
                }
                
                updateDisplayValues()
            }
        }
    }
    
    private func saveProfileData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        updateMetricHeight(from: displayHeight)
        updateMetricWeight(from: displayWeight)
        updateMetricTargetWeight(from: displayTargetWeight)
        
        isLoading = true
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Combine profile and preferences data into a single dictionary
        var combinedData: [String: Any] = [
            "userName": userName,
            "age": Int(age) ?? 0,
            "height": metricHeightCm,
            "weight": metricWeightKg,
            "birthDate": formatter.string(from: birthDate),
            "targetWeight": metricTargetWeightKg,
            "unitSystem": unitSystem.rawValue // Add unit system directly
        ]
        
        if let image = self.profileImage {
            if let imageString = self.encodeImage(image) {
                combinedData["profileImage"] = imageString // Add image directly
            }
        }
        
        // Save the flattened data structure
        userRef.setData(combinedData, merge: true) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.showAlert = true
                } else {
                    self.alertMessage = "Profile saved successfully."
                    self.showAlert = true
                }
            }
        }
    }
    
    private func updateDisplayValues() {
        if unitSystem == .metric {
            displayHeight = String(format: "%.1f", metricHeightCm)
            displayWeight = String(format: "%.1f", metricWeightKg)
            displayTargetWeight = String(format: "%.1f", metricTargetWeightKg)
        } else {
            displayHeight = String(format: "%.1f", cmToInches(metricHeightCm))
            displayWeight = String(format: "%.1f", kgToLbs(metricWeightKg))
            displayTargetWeight = String(format: "%.1f", kgToLbs(metricTargetWeightKg))
        }
        
        if Double(displayHeight) == 0 { displayHeight = "" }
        if Double(displayWeight) == 0 { displayWeight = "" }
        if Double(displayTargetWeight) == 0 { displayTargetWeight = "" }
    }
    
    private func updateMetricHeight(from displayValue: String) {
        guard let value = Double(displayValue) else {
            metricHeightCm = 0
            return
        }
        metricHeightCm = (unitSystem == .metric) ? value : inchesToCm(value)
    }
    
    private func updateMetricWeight(from displayValue: String) {
        guard let value = Double(displayValue) else {
            metricWeightKg = 0
            return
        }
        metricWeightKg = (unitSystem == .metric) ? value : lbsToKg(value)
    }
    
    private func updateMetricTargetWeight(from displayValue: String) {
        guard let value = Double(displayValue) else {
            metricTargetWeightKg = 0
            return
        }
        metricTargetWeightKg = (unitSystem == .metric) ? value : lbsToKg(value)
    }
    
    private func cmToInches(_ cm: Double) -> Double {
        return cm / 2.54
    }
    
    private func inchesToCm(_ inches: Double) -> Double {
        return inches * 2.54
    }
    
    private func kgToLbs(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    private func lbsToKg(_ lbs: Double) -> Double {
        return lbs / 2.20462
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
                TextField("Enter value", text: $value)
                    .keyboardType(isDecimal ? .decimalPad : (isNumeric ? .numberPad : .default))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.primary)
                if let unit = unit { Text(unit).foregroundColor(.gray) }
            }
            .frame(minWidth: 100)
        }
        .onChange(of: value) { oldValue, newValue in
            var filtered = newValue
            
            if isNumeric {
                filtered = newValue.filter { "0123456789".contains($0) }
            } else if isDecimal {
                filtered = newValue.filter { "0123456789.".contains($0) }
                if filtered.filter({ $0 == "." }).count > 1 {
                    if let secondDotIndex = filtered.indices.filter({ filtered[$0] == "." }).dropFirst().first {
                        filtered = String(filtered[..<secondDotIndex])
                    }
                }
                if filtered.starts(with: "00") {
                    filtered = String(filtered.dropFirst())
                }
                if filtered.starts(with: ".") {
                    filtered = "0" + filtered
                }
            }
            
            if filtered != newValue {
                DispatchQueue.main.async {
                    value = filtered
                }
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
