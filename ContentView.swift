//
//  ContentView.swift
//  CareCircle
//
//  Created on March 17, 2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            VaultView()
                .tabItem {
                    Label("Vault", systemImage: "folder.fill")
                }
            
            FamilyView()
                .tabItem {
                    Label("Family", systemImage: "person.3.fill")
                }
            
            FinancesView()
                .tabItem {
                    Label("Finances", systemImage: "dollarsign.circle.fill")
                }
        }
        .tint(.teal)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            ParentProfile.self,
            Appointment.self,
            Task.self,
            Document.self,
            FamilyMember.self,
            Expense.self,
            ExpenseAccount.self,
            UpdateFeedItem.self
        ])
}
