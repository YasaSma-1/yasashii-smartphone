import Foundation
import SwiftUI
import Combine

struct FavoriteContact: Identifiable, Equatable {
    let id: UUID
    var name: String
    var phone: String

    init(id: UUID = UUID(), name: String, phone: String) {
        self.id = id
        self.name = name
        self.phone = phone
    }
}

final class FavoriteContactsStore: ObservableObject {
    @Published var favorites: [FavoriteContact]

    init() {
        // ✅ デフォルトは空（未登録は PhoneView の空状態で伝える）
        self.favorites = []
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

