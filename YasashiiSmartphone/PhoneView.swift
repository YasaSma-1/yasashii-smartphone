import SwiftUI



// MARK: - 「電話」トップ画面

// 「電話」トップ画面：よくかける相手 ＋ 「番号を押して電話する」ボタン
struct PhoneView: View {
    @EnvironmentObject var favoriteContactsStore: FavoriteContactsStore

    // ✅ お気に入り用の pendingNumber / showCallConfirm は削除
    @State private var showErrorAlert = false

    @Environment(\.openURL) private var openURL

    private let favColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // タイトル
                Text("電話")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 24)

                // 🧑‍🤝‍🧑 よくかける相手（メインUI）
                VStack(alignment: .leading, spacing: 12) {
                    Text("よくかける相手")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))

                    if favoriteContactsStore.favorites.isEmpty {
                        Text("まだ登録されていません。\n「設定」から相手を追加できます。")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    } else {
                        LazyVGrid(columns: favColumns, spacing: 12) {
                            ForEach(favoriteContactsStore.favorites) { contact in
                                FavoriteContactButton(contact: contact) {
                                    // ✅ そのまま発信（確認ダイアログなし）
                                    call(number: contact.phone)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // 🔢 その他の番号にかける → 別画面へ
                NavigationLink {
                    ManualDialView()
                } label: {
                    HStack {
                        Image(systemName: "circle.grid.3x3.fill")
                        Text("番号を押して電話する")
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.yasasumaGreen)
                            .shadow(color: .black.opacity(0.3),
                                    radius: 5,
                                    x: 0,
                                    y: 3)
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        // ✅ お気に入りの確認アラートは削除
        .alert("電話をかけられません", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("番号を確認してください。")
        }
    }

    // 発信処理
    private func call(number: String) {
        let digitsOnly = number.filter { $0.isNumber }
        guard !digitsOnly.isEmpty,
              let url = URL(string: "tel://\(digitsOnly)") else {
            showErrorAlert = true
            return
        }
        openURL(url)
    }
}

/// 「よくかける相手」ボタン（2列の大きいカード）
struct FavoriteContactButton: View {
    let contact: FavoriteContact
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(contact.phone)
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
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
        .buttonStyle(.plain)
    }
}

// MARK: - 「番号を押して電話」画面

struct ManualDialView: View {
    @State private var phoneNumber: String = ""
    @State private var showErrorAlert = false

    @Environment(\.openURL) private var openURL

    // 0 が 8 の真下にくる配置
    private let keypad: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["",  "0", ""]
    ]

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("番号を押して電話")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 24)

                // ✅ 番号表示エリア（高さ固定＋×ボタンは delete.left.fill）
                HStack(spacing: 8) {
                    Text(phoneNumber.isEmpty ? "番号を入力してください" : phoneNumber)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !phoneNumber.isEmpty {
                        Button {
                            phoneNumber.removeLast()
                        } label: {
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        .accessibilityLabel("数字を1文字消す")
                    }
                }
                .frame(height: 44) // ✅ 入力前後で高さを固定
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.12),
                                radius: 4,
                                x: 0,
                                y: 2)
                )
                .padding(.horizontal, 24)

                Spacer()

                // キーパッド（0 が 8 の真下）
                VStack(spacing: 16) {
                    ForEach(0..<keypad.count, id: \.self) { rowIndex in
                        HStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { colIndex in
                                let label = keypad[rowIndex][colIndex]
                                if label.isEmpty {
                                    Spacer()
                                } else {
                                    DialButton(label: label) {
                                        handleTap(label: label)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                // ✅ 通話ボタン：確認ダイアログなしで即発信
                Button {
                    callCurrentNumber()
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("この番号に電話する")
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(phoneNumber.isEmpty
                                  ? Color.gray.opacity(0.5)
                                  : Color.yasasumaGreen)
                            .shadow(color: .black.opacity(0.3),
                                    radius: 5,
                                    x: 0,
                                    y: 3)
                    )
                }
                .disabled(phoneNumber.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        // エラーだけアラート表示（確認ダイアログは削除）
        .alert("電話をかけられません", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("番号を確認してください。")
        }
    }

    private func handleTap(label: String) {
        if phoneNumber.count < 11 {
            phoneNumber.append(label)
        }
    }

    private func callCurrentNumber() {
        let digitsOnly = phoneNumber.filter { $0.isNumber }
        guard !digitsOnly.isEmpty,
              let url = URL(string: "tel://\(digitsOnly)") else {
            showErrorAlert = true
            return
        }
        openURL(url)
    }
}

/// 立体感のある丸いダイヤルボタン
struct DialButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
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
                    .shadow(color: .black.opacity(0.25),
                            radius: 4,
                            x: 3,
                            y: 3)

                Text(label)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 80, height: 80)
    }
}

