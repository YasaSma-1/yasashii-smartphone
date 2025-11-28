//
//  YasashiiSmartphoneApp.swift
//  YasashiiSmartphone
//
//  Created by s002343 on 2025/11/29.
//

import SwiftUI
import CoreData

@main
struct YasashiiSmartphoneApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
