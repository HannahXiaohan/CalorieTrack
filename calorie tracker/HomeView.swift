//
//  HomeView.swift
//  calorie tracker
//
//  Created by Chris'💻 on 2025/2/7.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class NutritionViewModel: ObservableObject {
    @Published var calorieGoal: Int = 0
    @Published var consumedCalories: Int = 0
    @Published var proteinGoal: Int = 0
    @Published var fatGoal: Int = 0
    @Published var waterGoal: Int = 0
    @Published var consumedProtein: Int = 0
    @Published var consumedFat: Int = 0
    @Published var consumedWater: Int = 0

    private var db = Firestore.firestore()

    func listenToNutritionData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid)
            .addSnapshotListener { snapshot, error in
                if let data = snapshot?.data(),
                   let goals = data["goals"] as? [String: Any] {

                    DispatchQueue.main.async {
                        self.calorieGoal = goals["calories"] as? Int ?? 0
                        self.proteinGoal = goals["protein"] as? Int ?? 0
                        self.fatGoal = goals["fat"] as? Int ?? 0
                        self.waterGoal = goals["water"] as? Int ?? 0

                    }
                }
            }
    }
    func fetchIntakeForToday() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())

            db.collection("users").document(uid).collection("intake").document(today)
                .getDocument { snapshot, error in
                    if let data = snapshot?.data() {
                        DispatchQueue.main.async {
                            self.consumedCalories = data["calories"] as? Int ?? 0
                            self.consumedProtein = data["protein"] as? Int ?? 0
                            self.consumedFat = data["fat"] as? Int ?? 0
                            self.consumedWater = data["water"] as? Int ?? 0
                        }
                    }
                }
        }

    func listenToIntakeForToday() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        db.collection("users").document(uid).collection("intake").document(today)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let data = snapshot?.data() {
                        self.consumedCalories = data["calories"] as? Int ?? 0
                        self.consumedProtein = data["protein"] as? Int ?? 0
                        self.consumedFat = data["fat"] as? Int ?? 0
                        self.consumedWater = data["water"] as? Int ?? 0
                    } else {
                        self.consumedCalories = 0
                        self.consumedProtein = 0
                        self.consumedFat = 0
                        self.consumedWater = 0
                        if let error = error {
                            print("Error listening to intake document: \(error.localizedDescription)")
                        }
                    }
                }
            }
    }

    func addIntake(calories: Int, protein: Int, fat: Int, water: Int, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AppError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."]))
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let intakeRef = db.collection("users").document(uid).collection("intake").document(today)
        
        intakeRef.setData([
            "calories": FieldValue.increment(Int64(calories)),
            "protein": FieldValue.increment(Int64(protein)),
            "fat": FieldValue.increment(Int64(fat)),
            "water": FieldValue.increment(Int64(water))
        ], merge: true) { error in
            completion(error)
        }
    }
}

struct HomeView: View {
    @State private var searchText = ""
    @State private var foodItems: [String] = []
    @Binding var currentView: ContentView.AppView

    @EnvironmentObject var nutritionVM: NutritionViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .edgesIgnoringSafeArea(.top)
                            .frame(height: 180)

                        VStack(spacing: 15) {
                            HStack {
                                Text("Calorie Tracker")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.top, 40)
                            .padding(.horizontal)

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search food information", text: $searchText, onCommit: {
                                    searchFood()
                                })
                                .submitLabel(.search)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }

                    GroupBox {
                        FourRingsView(vm: nutritionVM)
                    } label: {
                        Text("Today's Nutrition")
                           .font(.title2)
                           .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.top, -20)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)

                    Divider().padding(.horizontal)

                    if !foodItems.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Search Results")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            ForEach(foodItems, id: \.self) { food in
                                HStack {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.green)
                                    Text(food)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        Divider().padding(.horizontal)
                    }

                    GroupBox {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(.orange)
                                Text("0 kcal")
                                    .font(.title2)
                                Spacer()
                                Text("0 Minutes")
                                    .foregroundColor(.gray)
                            }
                        }
                    } label: {
                        HStack {
                           Text("Exercise")
                               .font(.headline)
                           Spacer()
                           Image(systemName: "plus")
                       }
                    }
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .padding(.vertical, 5)

                    GroupBox {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundColor(.purple)
                                Text("70 kg")
                                    .font(.title2)
                                Spacer()
                                Text("Recent trend")
                                    .foregroundColor(.gray)
                            }
                        }
                    } label: {
                         HStack {
                           Text("Weight data")
                               .font(.headline)
                           Spacer()
                           Image(systemName: "plus")
                       }
                    }
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .padding(.bottom, 5)

                    Spacer()
                }
                .onAppear {
                    nutritionVM.listenToNutritionData()
                    nutritionVM.listenToIntakeForToday()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private func searchFood() {
        let sampleData = ["Apple", "Banana", "Orange", "Chicken", "Rice"]
        foodItems = sampleData.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
}

struct FourRingsView: View {
    @ObservedObject var vm: NutritionViewModel
    @State private var animateRings = false

    var body: some View {
        ZStack {
            Ring(progress: animateRings ? progress(vm.consumedWater, vm.waterGoal) : 0, size: 80, color: .blue)
            Ring(progress: animateRings ? progress(vm.consumedFat, vm.fatGoal) : 0, size: 160, color: .orange)
            Ring(progress: animateRings ? progress(vm.consumedProtein, vm.proteinGoal) : 0, size: 120, color: .green)
            Ring(progress: animateRings ? progress(vm.consumedCalories, vm.calorieGoal) : 0, size: 200, color: .red)
        }
        .padding(.vertical)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateRings = true
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            legendRow(color: .red, label: "Calories", value: "\(vm.consumedCalories)/\(vm.calorieGoal) kcal")
            legendRow(color: .blue, label: "Water", value: "\(vm.consumedWater)/\(vm.waterGoal) ml")
            legendRow(color: .orange, label: "Fat", value: "\(vm.consumedFat)/\(vm.fatGoal) g")
            legendRow(color: .green, label: "Protein", value: "\(vm.consumedProtein)/\(vm.proteinGoal) g")
        }
    }

    func legendRow(color: Color, label: String, value: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .frame(width: 70, alignment: .leading)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    func progress(_ value: Int, _ goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(value) / Double(goal), 1.0)
    }
}

struct Ring: View {
    var progress: Double
    var size: CGFloat
    var color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 12)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}
