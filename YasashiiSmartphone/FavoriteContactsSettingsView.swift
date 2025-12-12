import SwiftUI

private let freeFavoriteLimit = 2

private enum FavoriteContactsSheet: Identifiable {
    case edit(FavoriteContact?)  // nil = 新規
    case paywall

    var id: String {
        switch self {
        case .edit(let contact):
            return contact.map { "edit-\($0.id.uuidString)" } ?? "edit-new"
        case .paywall:
            return "paywall"
        }
    }
}

struct FavoriteContactsSettingsView: View {
    @EnvironmentObject var favoriteContactsStore: FavoriteContactsStore
    @EnvironmentObject var purchaseStore: PurchaseStore

    @State private var editMode: EditMode = .inactive
    @State private var activeSheet: FavoriteContactsSheet?

    // ✅ 複数選択
    @State private var selection: Set<UUID> = []
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { editMode == .active }

    var body: some View {
        List(selection: $selection) {
            Section {
                if favoriteContactsStore.favorites.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("まだ登録されていません")
                            .font(.system(size: 16, weight: .semibold))

                        Text("右上の「＋」から追加できます。")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(favoriteContactsStore.favorites) { contact in
                        if isEditing {
                            FavoriteContactSettingsRow(contact: contact, showChevron: false)
                                .tag(contact.id)
                        } else {
                            Button {
                                activeSheet = .edit(contact)
                            } label: {
                                FavoriteContactSettingsRow(contact: contact, showChevron: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("「電話」画面に出す相手を設定します。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("無料版では 2件 まで登録できます。")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .textCase(nil)
                .padding(.top, 6)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6))
        .navigationTitle("よくかける相手")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .onChange(of: editMode) { _, newValue in
            if newValue == .inactive { selection.removeAll() }
        }
        .toolbar {
            // 右上：編集（＋の左）
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        editMode = isEditing ? .inactive : .active
                    }
                }
                .font(.system(size: 16, weight: .semibold))
            }

            // 右上：＋（右端）※右余白確保
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    handleAddTapped()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.trailing, 8)
                }
                .disabled(isEditing)
            }

            // ✅ 編集モードのときだけ「削除」を下に出す
            if isEditing {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
        .confirmationDialog(
            "選択した \(selection.count) 件を削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { deleteSelected() }
            Button("キャンセル", role: .cancel) { }
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
                    onDelete: editingContact.map { target in
                        { favoriteContactsStore.delete(contact: target) }
                    }
                )

            case .paywall:
                PaywallView()
                    .environmentObject(purchaseStore)
            }
        }
    }

    private func handleAddTapped() {
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

    private func deleteSelected() {
        let ids = selection
        let targets = favoriteContactsStore.favorites.filter { ids.contains($0.id) }
        targets.forEach { favoriteContactsStore.delete(contact: $0) }
        selection.removeAll()
    }
}

// MARK: - Row（Destination とデザイン統一）

private struct FavoriteContactSettingsRow: View {
    let contact: FavoriteContact
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yasasumaGreen)
                    .frame(width: 34, height: 34)
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(contact.phone)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Edit Sheet（削除あり）

private struct FavoriteContactEditSheet: View {
    let contact: FavoriteContact?
    let onSave: (String, String) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var phone: String
    @State private var showDeleteConfirm = false

    init(
        contact: FavoriteContact?,
        onSave: @escaping (String, String) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.contact = contact
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: contact?.name ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("削除")
                        }
                    }
                }
            }
            .navigationTitle(contact == nil ? "新しい相手を追加" : "相手を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }
                        onSave(trimmedName, trimmedPhone)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "この相手を削除しますか？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) { }
            }
        }
    }
}

