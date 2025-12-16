import SwiftUI

// MARK: - 「電話」トップ画面
struct PhoneView: View {
    @EnvironmentObject var favoriteContactsStore: FavoriteContactsStore

    @State private var showErrorAlert = false
    @Environment(\.openURL) private var openURL

    // 設定ロック状態（空状態に🔒を出すため）
    @AppStorage("yasasumaPasscodeEnabled") private var passcodeEnabled: Bool = false
    @AppStorage("yasasumaPasscodeValue") private var storedPasscode: String = ""

    private var isSettingsLocked: Bool {
        passcodeEnabled && storedPasscode.filter { $0.isNumber }.count == 4
    }

    private let favColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("電話")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("よくかける相手")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))

                    if favoriteContactsStore.favorites.isEmpty {
                        PhoneEmptyStateCard(isLocked: isSettingsLocked)
                    } else {
                        LazyVGrid(columns: favColumns, spacing: 12) {
                            ForEach(favoriteContactsStore.favorites) { contact in
                                FavoriteContactButton(contact: contact) {
                                    call(number: contact.phone)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

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
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("電話をかけられません", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("番号を確認してください。")
        }
    }

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

// MARK: - 空状態カード（電話）
private struct PhoneEmptyStateCard: View {
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.yasasumaGreen))

                Text("まだ登録されていません")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }

            Text(isLocked
                 ? "お子さんが「設定」で登録すると、ここに大きく表示されます。"
                 : "「設定」で登録すると、ここに大きく表示されます。")
            .font(.system(size: 15))
            .foregroundColor(.secondary)

            NavigationLink {
                SettingsPasscodeGate {
                    FavoriteContactsSettingsView()
                }
            } label: {
                HStack(spacing: 10) {
                    if isLocked { Image(systemName: "lock.fill") }
                    Image(systemName: "gearshape.fill")
                    Text("設定で登録する")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.yasasumaGreen)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
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
                            colors: [Color.white, Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.8), radius: 3, x: -2, y: -2)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 3)
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
                .frame(height: 44)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 16) {
                    ForEach(0..<keypad.count, id: \.self) { rowIndex in
                        HStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { colIndex in
                                let label = keypad[rowIndex][colIndex]
                                if label.isEmpty {
                                    Spacer()
                                } else {
                                    DialButton(label: label) { handleTap(label: label) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Button { callCurrentNumber() } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("この番号に電話する")
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(phoneNumber.isEmpty ? Color.gray.opacity(0.5) : Color.yasasumaGreen)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                }
                .disabled(phoneNumber.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .alert("電話をかけられません", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("番号を確認してください。")
        }
    }

    private func handleTap(label: String) {
        if phoneNumber.count < 11 { phoneNumber.append(label) }
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

struct DialButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.8), radius: 3, x: -2, y: -2)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 3, y: 3)

                Text(label)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 80, height: 80)
    }
}

