import SwiftUI

struct FavoriteContactsSettingsView: View {
    @EnvironmentObject var favoriteContactsStore: FavoriteContactsStore

    @State private var editingContact: FavoriteContact?
    @State private var isPresentingEditor = false

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("よくかける相手（電話帳）")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top, 24)

                    Text("「電話」の画面に出す相手をここで編集します。\nお子さんなどが一緒に設定してあげることを想定しています。")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
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
                                    // 編集モードでシートを開く
                                    editingContact = contact
                                    isPresentingEditor = true
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
            // 右上の＋ボタン → 新規追加
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingContact = nil
                    isPresentingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // 追加・編集シート
        .sheet(isPresented: $isPresentingEditor) {
            FavoriteContactEditSheet(
                contact: editingContact,
                onSave: { name, phone in
                    if let editing = editingContact {
                        favoriteContactsStore.update(contact: editing, name: name, phone: phone)
                    } else {
                        favoriteContactsStore.add(name: name, phone: phone)
                    }
                    editingContact = nil
                },
                onDelete: editingContact.map { contact in
                    {
                        favoriteContactsStore.delete(contact: contact)
                        editingContact = nil
                    }
                }
            )
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
                            // ざっくり：空なら何もしないで戻る
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

