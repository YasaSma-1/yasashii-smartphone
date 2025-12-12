import SwiftUI

private let freeFavoriteLimit = 2

private enum FavoriteContactsSheet: Identifiable {
    case edit(FavoriteContact?)  // nil のときは新規
    case paywall

    var id: String {
        switch self {
        case .edit(let contact):
            if let c = contact { return "edit-\(c.id.uuidString)" }
            return "edit-new"
        case .paywall:
            return "paywall"
        }
    }
}

struct FavoriteContactsSettingsView: View {
    @EnvironmentObject var favoriteContactsStore: FavoriteContactsStore
    @EnvironmentObject var purchaseStore: PurchaseStore

    @Environment(\.editMode) private var editMode
    @State private var activeSheet: FavoriteContactsSheet?

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // タイトルの重複感を減らす（navigationTitleは残す）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("「電話」の画面に出す相手をここで編集します。")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Text("無料版では 2件 まで登録できます。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    VStack(spacing: 12) {
                        if favoriteContactsStore.favorites.isEmpty {
                            Text("まだ登録されていません。\n右上の＋ボタンから追加できます。")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            ForEach(favoriteContactsStore.favorites) { contact in
                                Button {
                                    activeSheet = .edit(contact)
                                } label: {
                                    FavoriteContactSettingsRow(contact: contact)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)
                }
            }
        }
        .navigationTitle("よくかける相手")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ✅ 右側： [編集] [＋] で「＋の左に編集」
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    withAnimation {
                        editMode?.wrappedValue = isEditing ? .inactive : .active
                    }
                }

                Button {
                    handleAddButtonTapped()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit(let editingContact):
                FavoriteContactEditSheet(
                    contact: editingContact,
                    onSave: { name, phone in
                        if let editing = editingContact {
                            favoriteContactsStore.update(contact: editing, name: name, phone: phone)
                        } else {
                            favoriteContactsStore.add(name: name, phone: phone)

                            if favoriteContactsStore.favorites.count >= 3 {
                                ReviewRequestManager.shared.maybeRequestReview(trigger: .addedFavoriteContacts)
                            }
                        }
                    },
                    onDelete: editingContact.map { contact in
                        { favoriteContactsStore.delete(contact: contact) }
                    }
                )

            case .paywall:
                PaywallView()
                    .environmentObject(purchaseStore)
            }
        }
    }

    private func handleAddButtonTapped() {
        if purchaseStore.isProUnlocked {
            activeSheet = .edit(nil)
            return
        }

        if favoriteContactsStore.favorites.count >= freeFavoriteLimit {
            activeSheet = .paywall
        } else {
            activeSheet = .edit(nil)
        }
    }
}


/// 設定用の電話帳1行カード
struct FavoriteContactSettingsRow: View {
    let contact: FavoriteContact

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.yasasumaGreen)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(contact.phone)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(.systemGray5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.8),
                        radius: 3,
                        x: -2,
                        y: -2)
                .shadow(color: .black.opacity(0.2),
                        radius: 4,
                        x: 2,
                        y: 3)
        )
    }
}

// MARK: - 追加・編集シート

struct FavoriteContactEditSheet: View {
    let contact: FavoriteContact?          // nil のときは新規
    let onSave: (String, String) -> Void   // (name, phone)
    let onDelete: (() -> Void)?           // 既存のときだけ有効

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phone: String = ""

    init(contact: FavoriteContact?,
         onSave: @escaping (String, String) -> Void,
         onDelete: (() -> Void)? = nil) {
        self.contact = contact
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: contact?.name ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("名前")) {
                    TextField("例：お母さん", text: $name)
                }

                Section(header: Text("電話番号")) {
                    TextField("数字だけで入力してください", text: $phone)
                        .keyboardType(.numberPad)
                }

                if let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Text("この相手を削除する")
                        }
                    }
                }
            }
            .navigationTitle(contact == nil ? "新しい相手を追加" : "相手を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else {
                            dismiss()
                            return
                        }
                        onSave(trimmedName, trimmedPhone)
                        dismiss()
                    }
                }
            }
        }
    }
}

