import SwiftUI

// 無料版で登録できる「よくかける相手」の上限
private let freeFavoriteLimit = 2

// シートの種類（編集 or ペイウォール）
private enum FavoriteContactsSheet: Identifiable {
    case edit(FavoriteContact?)  // nil のときは新規
    case paywall

    var id: String {
        switch self {
        case .edit(let contact):
            if let c = contact {
                return "edit-\(c.id.uuidString)"
            } else {
                return "edit-new"
            }
        case .paywall:
            return "paywall"
        }
    }
}

struct FavoriteContactsSettingsView: View {
    @EnvironmentObject var favoriteContactsStore: FavoriteContactsStore
    @EnvironmentObject var purchaseStore: PurchaseStore

    // どのシートを出すか
    @State private var activeSheet: FavoriteContactsSheet?

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("よくかける相手（電話帳）")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("「電話」の画面に出す相手をここで編集します。")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Text("無料版では、よくかける相手は 2件 まで登録できます。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)

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
                                    // 既存の相手は常に編集OK（制限なし）
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
            // 左：編集（削除 / 並び替え用）
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }

            // 右：＋ボタン（よくかける相手を追加）
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    handleAddButtonTapped()   // ← 関数名に揃える
                } label: {
                    Image(systemName: "plus")
                }
            }

        }

        // 追加・編集・ペイウォールのシート
        // 追加・編集・ペイウォールのシート
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit(let editingContact):
                FavoriteContactEditSheet(
                    contact: editingContact,
                    onSave: { name, phone in
                        if let editing = editingContact {
                            // 既存の連絡先を編集
                            favoriteContactsStore.update(
                                contact: editing,
                                name: name,
                                phone: phone
                            )
                        } else {
                            // 新規追加
                            favoriteContactsStore.add(name: name, phone: phone)

                            // ★ よくかける相手が複数件になったらレビュー依頼候補
                            if favoriteContactsStore.favorites.count >= 3 {
                                ReviewRequestManager.shared.maybeRequestReview(trigger: .addedFavoriteContacts)
                            }
                        }
                    },
                    onDelete: editingContact.map { contact in
                        {
                            favoriteContactsStore.delete(contact: contact)
                        }
                    }
                )

            case .paywall:
                PaywallView()
                    .environmentObject(purchaseStore)
            }
        }

    }

    // MARK: - 新規追加ボタンタップ時の制御

    private func handleAddButtonTapped() {
        // 有料版なら制限なし
        if purchaseStore.isProUnlocked {
            activeSheet = .edit(nil)
            return
        }

        // 無料版で 2件以上登録済み → ペイウォール
        if favoriteContactsStore.favorites.count >= freeFavoriteLimit {
            activeSheet = .paywall
        } else {
            // 2件未満なら新規追加OK
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

