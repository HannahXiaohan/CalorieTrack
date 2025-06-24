//
//  MainTabView.swift
//  calorie tracker
//
//  Created by Chris'💻 on 2025/2/7.
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
