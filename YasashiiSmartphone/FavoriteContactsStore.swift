import Foundation
import SwiftUI
import Combine

// よくかける相手のモデル
struct FavoriteContact: Identifiable, Equatable {
    let id: UUID
    var name: String      // 表示名（例: お母さん）
    var phone: String     // 電話番号

    init(id: UUID = UUID(), name: String, phone: String) {
        self.id = id
        self.name = name
        self.phone = phone
    }
}

// アプリ全体で共有する「よくかける相手」のストア
final class FavoriteContactsStore: ObservableObject {
    @Published var favorites: [FavoriteContact]

    init() {
        // 初期データ（あとで設定画面から編集）
        self.favorites = [
            FavoriteContact(name: "自宅",    phone: "0312345678"),
            FavoriteContact(name: "お母さん", phone: "09011112222"),
            FavoriteContact(name: "お父さん", phone: "09033334444"),
            FavoriteContact(name: "病院",    phone: "04855556666")
        ]
    }

    func add(name: String, phone: String) {
        let newContact = FavoriteContact(name: name, phone: phone)
        favorites.append(newContact)
    }

    func update(contact: FavoriteContact, name: String, phone: String) {
        guard let index = favorites.firstIndex(where: { $0.id == contact.id }) else { return }
        favorites[index].name = name
        favorites[index].phone = phone
    }

    func delete(contact: FavoriteContact) {
        favorites.removeAll { $0.id == contact.id }
    }
}

