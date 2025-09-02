//
//  ContentView.swift
//  EkVastu
//
//  Created by Venkata Avula  on 8/29/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ItemsView(viewContext: viewContext)
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#ECD2BE"), Color(hex: "#FEA45A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                Text("Welcome to EkVastu")
                    .font(.largeTitle)
                    .padding()
                
                Image("splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            }
            }
            .navigationTitle("Home")
        }
    }
}

struct ItemsView: View {
    var viewContext: NSManagedObjectContext
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#ECD2BE"), Color(hex: "#FEA45A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Text("No items to display")
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Button(action: {}) {
                        Label("Add New Item", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Items")
        }
    }
    
    // Helper function to format date for iOS 14 compatibility
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
