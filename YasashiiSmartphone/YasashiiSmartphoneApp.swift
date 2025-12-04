import SwiftUI

@main
struct YasashiiSmartphoneApp: App {
    @StateObject private var favoriteContactsStore = FavoriteContactsStore()
    @StateObject private var destinationStore = DestinationStore()   // ← 追加
    @StateObject private var eventsStore           = EventsStore()   // ★ 追加
    @StateObject private var purchaseStore         = PurchaseStore()   // ★ 追加



    var body: some Scene {
        WindowGroup {
            ContentView()   // あなたのタブのルート
                .environmentObject(favoriteContactsStore)
                .environmentObject(destinationStore)                 // ← 追加
                .environmentObject(eventsStore)   // ★ 追加
                .environmentObject(purchaseStore)   // ★ 追加

        }
    }
}
