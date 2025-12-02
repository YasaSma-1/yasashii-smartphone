// EventsStore.swift

import Foundation
import Combine   // ★ これがないと ObservableObject と @Published が使えない

// 予定データ（保存できるように Codable も採用）
struct YasasumaEvent: Identifiable, Codable {
    let id: UUID
    var date: Date
    var title: String

    init(id: UUID = UUID(), date: Date, title: String) {
        self.id = id
        self.date = date
        self.title = title
    }
}

// 予定リストをアプリ全体で共有＆UserDefaultsに保存
final class EventsStore: ObservableObject {
    @Published var events: [YasasumaEvent] = [] {
        didSet {
            saveEvents()
        }
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

