//
//  HomeView.swift
//  calorie tracker
//
//  
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
}

struct HomeView: View {
    @State private var searchText = ""
    @State private var foodItems: [String] = []
    @Binding var currentView: ContentView.AppView

    @StateObject private var nutritionVM = NutritionViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ZStack {
                        Color.blue
                            .edgesIgnoringSafeArea(.top)
                            .frame(height: 160)

                        VStack {
                            HStack {
                                Text("Calorie Tracker")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search food information", text: $searchText, onCommit: {
                                    searchFood()
                                })
                                .submitLabel(.search)
                            }
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    FourRingsView(vm: nutritionVM)

                    if !foodItems.isEmpty {
                        VStack {
                            ForEach(foodItems, id: \ .self) { food in
                                Text(food)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    VStack {
                        SectionBox(title: "Exercise", icon: "flame", value: "0 kcal", subValue: "0 Minutes")
                        SectionBox(title: "Weight data", icon: "scalemass", value: "70 kg", subValue: "Recent trend")
                    }
                    .padding(.top)

                    Spacer()
                }
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    nutritionVM.listenToNutritionData()
                    nutritionVM.fetchIntakeForToday()
                }
            }
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
        VStack(spacing: 20) {
            Text("Today's Nutrition Rings")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ZStack {
                Ring(progress: animateRings ? progress(vm.consumedWater, vm.waterGoal) : 0, size: 200, color: .blue)
                Ring(progress: animateRings ? progress(vm.consumedFat, vm.fatGoal) : 0, size: 160, color: .orange)
                Ring(progress: animateRings ? progress(vm.consumedProtein, vm.proteinGoal) : 0, size: 120, color: .green)
                Ring(progress: animateRings ? progress(vm.consumedCalories, vm.calorieGoal) : 0, size: 80, color: .red)
            }
            .padding()
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateRings = true
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                legendRow(color: .blue, label: "Water", value: "\(vm.consumedWater)/\(vm.waterGoal) ml")
                legendRow(color: .orange, label: "Fat", value: "\(vm.consumedFat)/\(vm.fatGoal) g")
                legendRow(color: .green, label: "Protein", value: "\(vm.consumedProtein)/\(vm.proteinGoal) g")
                legendRow(color: .red, label: "Calories", value: "\(vm.consumedCalories)/\(vm.calorieGoal) kcal")
            }
            .padding(.horizontal)
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

struct SectionBox: View {
    var title: String
    var icon: String
    var value: String
    var subValue: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "plus")
            }
            .padding(.horizontal)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(value)
                    .font(.title2)
                Spacer()
                Text(subValue)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
