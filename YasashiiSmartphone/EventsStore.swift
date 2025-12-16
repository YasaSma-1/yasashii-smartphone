import Foundation
import Combine

// 予定データ（UserDefaults保存のため Codable）
struct YasasumaEvent: Identifiable, Codable {
    let id: UUID
    var date: Date
    var title: String
    var memo: String? = nil   // ✅ メモ

    init(id: UUID = UUID(), date: Date, title: String, memo: String? = nil) {
        self.id = id
        self.date = date
        self.title = title
        self.memo = memo
    }
}

// 予定リストを共有＆UserDefaultsに保存
final class EventsStore: ObservableObject {
    @Published var events: [YasasumaEvent] = [] {
        didSet { saveEvents() }
    }

    private let storageKey = "yasasuma_events"

    init() {
        loadEvents()
    }

    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save events:", error)
        }
    }

    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            events = try JSONDecoder().decode([YasasumaEvent].self, from: data)
        } catch {
            print("Failed to load events:", error)
        }
    }
}

