//
//  MainTabView.swift
//  calorie tracker
//
//  
//

import SwiftUI

struct MainTabView: View {
        @Binding var currentView: ContentView.AppView
        var body: some View {
            TabView {
                HomeView(currentView: $currentView)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                
                ScanMealView(currentView: $currentView)
                    .tabItem {
                        Image(systemName: "camera.viewfinder")
                        Text("Scan")
                    }
                
                ProfileView(currentView: $currentView)
                    .tabItem {
                        Image(systemName: "person")
                        Text("Profile")
                    }
            }
        }
    }
