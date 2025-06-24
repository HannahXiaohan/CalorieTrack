//
//  ScanMealView.swift
//  Calorie Tracker
//
//  
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
struct NutritionData {
    static private var calorieMap: [String: Int] = [:]
    static private var waterMap: [String: Int] = [:]
    static private var fatMap: [String: Int] = [:]
    static private var proteinMap: [String: Int] = [:]
    
    static func initialize() {
        let csvContent = """
        Categories ,Calories,Water,Fat,Proteins
        This table describes the nutritional values for food per 100 grams.   Units: Calories: gcal; Water: g; Fat: g; Proteins: g,,,,
        Apple Pie  ,237,52,11,1.9
        Baby Back Ribs  ,277,59.8,23.4,15.5
        Baklava  ,428,25.5,29.03,6.7
        Beef Carpaccio  ,119,74.5,2.6,22.3
        Beef Tartare  ,210,66.2,14.6,17.8
        Beet Salad  ,25,88,0.2,1
        Beignets  ,348,8.81,9.1,2.5
        Bibimbap  ,113,83.2,2.6,4.2
        Bread Pudding  ,153,56.5,4.74,5.27
        Breakfast Burrito  ,202,48.9,12.3,10.72
        Bruschetta  ,100,38.7,4.5,2.5
        Caesar Salad  ,265,43.4,9.5,13
        Cannoli  ,254,43.4,11.04,8.7
        Caprese Salad  ,153,76.1,11.9,7.5
        Carrot Cake  ,415,3.6,9.8,5.1
        Ceviche  ,69,84.5,0.79,11.5
        Cheesecake  ,321,45.6,22.5,5.5
        Cheese Plate  ,538,38.2,35,25
        Chicken Curry  ,124,83.5,6.67,11.47
        Chicken Quesadilla  ,294,44,15,15
        Chicken Wings  ,288,46.2,19.3,26.64
        Chocolate Cake  ,371,24.2,15,5.3
        Chocolate Mousse  ,209,63.5,15.11,4.16
        Churros  ,447,16,28.28,2.79
        Clam Chowder  ,67,84.5,2.39,3.62
        Club Sandwich  ,210,44,10,12
        Crab Cakes  ,168,71.6,7.98,22.23
        Creme Brulee  ,336,45.6,25.4,4.3
        Croque Madame  ,271,45,17.9,13
        Cup Cakes  ,343,32,8.3,2.8
        Deviled Eggs  ,201,64.3,16.23,11.57
        Donuts  ,421,24.5,22.85,5.7
        Dumplings  ,124,70,3.21,3.3
        Edamame  ,121,72.8,5.2,11.9
        Eggs Benedict  ,276,55.8,21.6,11.96
        Escargots  ,80,80.4,1,16
        Falafel  ,333,35.5,17.8,13.3
        Filet Mignon  ,170,55.6,8.41,21.97
        Fish And Chips  ,170,55,9,10
        Foie Gras  ,462,37,43.8,11.4
        French Fries  ,274,43.3,14.06,3.48
        French Onion Soup  ,36,93,2,2
        French Toast  ,229,54.7,11,7.7
        Fried Calamari  ,125,54.9,2.17,15.13
        Fried Rice  ,168,65,6.23,6.3
        Frozen Yogurt  ,127,61,4,3
        Garlic Bread  ,330,35,12.78,7.75
        Gnocchi  ,133,47.2,6.24,2.36
        Greek Salad  ,101,85,6.93,6.66
        Grilled Cheese Sandwich  ,350,35.5,19,11
        Grilled Salmon  ,179,66,10.4,19.9
        Guacamole  ,157,74.8,14.31,1.96
        Gyoza  ,256,50,14.8,7.8
        Hamburger  ,295,42.7,14,17
        Hot And Sour Soup  ,40,89,1.3,2.2
        Hot Dog  ,290,46,23,11
        Huevos Rancheros  ,126,69.2,7.1,6.1
        Hummus  ,166,59,9.6,7.9
        Ice Cream  ,207,61.4,11,3.5
        Lasagna  ,135,66,5.86,8.68
        Lobster Bisque  ,84,84.2,4.6,3.7
        Lobster Roll Sandwich  ,236,51.6,13.2,10.8
        Macaroni And Cheese  ,164,64.5,6.6,6
        Macarons  ,413,16.2,18,5
        Miso Soup  ,31,91.2,1.1,2
        Mussels  ,172,66.3,4.5,24
        Nachos  ,326,34.5,19.3,7.1
        Omelette  ,154,74,11,11
        Onion Rings  ,411,41.8,22.9,4.1
        Oysters  ,68,89,2.5,7
        Pad Thai  ,240,50.8,10,9.5
        Paella  ,158,64.5,5.8,10.4
        Pancakes  ,227,52.7,10.1,6
        Panna Cotta  ,223,69.5,18.1,3.5
        Peking Duck  ,337,49.6,28.3,17.5
        Pho  ,64,87.5,1.2,5.3
        Pizza  ,266,41.7,10,11
        Pork Chop  ,199,62.2,10.9,24.4
        Poutine  ,260,48,15,6.5
        Prime Rib  ,351,51.5,30.7,17
        Pulled Pork Sandwich  ,242,52.8,11.4,15.1
        Ramen  ,436,75,17.6,10
        Ravioli  ,146,64.7,5.2,5.6
        Red Velvet Cake  ,390,27.8,17.4,3.6
        Risotto  ,130,71.2,4,2.5
        Samosa  ,262,43.5,17,4.9
        Sashimi  ,117,74.2,4,19.5
        Scallops  ,111,76.3,0.8,20.5
        Seaweed Salad  ,70,86.5,4,1.6
        Shrimp And Grits  ,148,65.4,7.2,9.6
        Spaghetti Bolognese  ,134,67.8,4.9,6.5
        Spaghetti Carbonara  ,157,56.5,7.2,7.1
        Spring Rolls  ,207,58.5,10,8.5
        Steak  ,217,61,11.8,26.1
        Strawberry Shortcake  ,283,49.5,16.7,3.3
        Sushi  ,143,61.3,0.42,4.3
        Tacos  ,226,57,13,8.9
        Takoyaki  ,160,20,7,8
        Tiramisu  ,297,34.5,20,6.4
        Tuna Tartare  ,357,17,24,32
        Waffles  ,291,32.9,14.1,7.9
        """
        
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 2 else { return }
        
        for line in lines[2...] {
            let components = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard components.count >= 5 else { continue }
            
            let foodKey = components[0].lowercased()
            
            if let calories = Int(components[1]) {
                calorieMap[foodKey] = calories
            }
            if let water = Int(components[2]) {
                waterMap[foodKey] = water
            }
            if let fat = Int(components[3]) {
                fatMap[foodKey] = fat
            }
            if let protein = Int(components[4]) {
                proteinMap[foodKey] = protein
            }
        }
    }
    
    static func calories(for food: String) -> Int {
        return calorieMap[food.lowercased()] ?? 0
    }
    
    static func water(for food: String) -> Int {
        return waterMap[food.lowercased()] ?? 0
    }
    
    static func fat(for food: String) -> Int {
        return fatMap[food.lowercased()] ?? 0
    }
    
    static func protein(for food: String) -> Int {
        return proteinMap[food.lowercased()] ?? 0
    }
}

struct ScanMealView: View {
    @State private var recognizedFood = "No food detected"
    @State private var detectedCalories = 0
    @State private var detectedWater = 0
    @State private var detectedFat = 0
    @State private var detectedProtein = 0
    @Binding var currentView: ContentView.AppView
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    // Core ML properties
    private let modelFileName = "FoodClassifier"
    private let inputSize = CGSize(width: 224, height: 224)
    
    var body: some View {
        VStack {
            Text("Scan Your Meal")
                .font(.largeTitle)
                .bold()
                .padding(.top, 30)
            
            ZStack {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "camera.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            Button(action: { showCamera = true }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Capture Meal")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .padding()
            }
            
            if !recognizedFood.isEmpty {
                VStack(spacing: 15) {
                    Text("Detection Results")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text("Food:")
                            .font(.headline)
                        Text(recognizedFood)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Calories:")
                            .font(.headline)
                        Text("\(detectedCalories) kcal")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                    HStack {
                        Text("Water:")
                            .font(.headline)
                        Text("\(detectedWater) ml")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                    HStack {
                        Text("Fat:")
                            .font(.headline)
                        Text("\(detectedFat) g")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                    HStack {
                        Text("Protein:")
                            .font(.headline)
                        Text("\(detectedProtein) g")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Meal Scanner")
        .onAppear(perform: checkCameraPermissions)
        .sheet(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                processImage(image)
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    
    private func processImage(_ image: UIImage) {
        isLoading = true
        recognizedFood = "Processing..."
        detectedCalories = 0
        detectedWater = 0
        detectedFat = 0
        detectedProtein = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let config = MLModelConfiguration()
                let foodModel = try FoodClassifier(configuration: config)
                let visionModel = try VNCoreMLModel(for: foodModel.model)
                
                // Use fixed orientation image
                let fixedImage = image.fixedOrientation
                guard let resizedImage = fixedImage.resized(to: self.inputSize),
                      let ciImage = CIImage(image: resizedImage) else {
                    throw NSError(domain: "ImageError", code: 1, userInfo: nil)
                }
                
                let request = VNCoreMLRequest(model: visionModel) { request, error in
                    DispatchQueue.main.async {
                        self.handleClassification(request.results, error: error)
                    }
                }
                request.imageCropAndScaleOption = .centerCrop
                
                let handler = VNImageRequestHandler(ciImage: ciImage)
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Processing error: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }

    private func handleClassification(_ results: [Any]?, error: Error?) {
        isLoading = false
        
        if let error = error {
            alertMessage = "Analysis failed: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        guard let results = results as? [VNClassificationObservation],
              let topResult = results.first else {
            alertMessage = "No results found"
            showAlert = true
            return
        }
        
        // Add confidence threshold
        let confidenceThreshold: Float = 0.2
        guard topResult.confidence >= confidenceThreshold else {
            recognizedFood = "Uncertain detection"
            detectedCalories = 0
            detectedWater = 0
            detectedFat = 0
            detectedProtein = 0
            return
        }
        
        recognizedFood = topResult.identifier
        detectedCalories = caloriesForFood(topResult.identifier)
        detectedWater = waterForFood(topResult.identifier)
        detectedFat = fatForFood(topResult.identifier)
        detectedProtein = proteinForFood(topResult.identifier)
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        self.alertMessage = "Camera access required for scanning meals"
                        self.showAlert = true
                    }
                }
            }
        default:
            alertMessage = "Enable camera access in Settings → Privacy → Camera"
            showAlert = true
        }
    }
    
    private func caloriesForFood(_ food: String) -> Int {
        return NutritionData.calories(for: food)
    }

    private func waterForFood(_ food: String) -> Int {
        return NutritionData.water(for: food)
    }

    private func fatForFood(_ food: String) -> Int {
        return NutritionData.fat(for: food)
    }

    private func proteinForFood(_ food: String) -> Int {
        return NutritionData.protein(for: food)
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
    }
}

// MARK: - Image Processing Extensions
extension UIImage {
    var fixedOrientation: UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return self
        }
        return image
    }
    
    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
