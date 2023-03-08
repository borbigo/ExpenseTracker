//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Bastien Orbigo on 3/6/23.
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject var TransactionListVM = TransactionListViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(TransactionListVM)
        }
    }
}
