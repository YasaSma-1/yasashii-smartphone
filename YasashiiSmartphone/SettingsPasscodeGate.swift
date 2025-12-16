import SwiftUI

/// 「設定ロック（パスコード）」を通して任意の画面へ遷移させるゲート
struct SettingsPasscodeGate<Destination: View>: View {
    @AppStorage("yasasumaPasscodeEnabled") private var isEnabled: Bool = false
    @AppStorage("yasasumaPasscodeValue") private var storedPasscode: String = ""

    @State private var input: String = ""
    @State private var isUnlocked: Bool = false
    @State private var showError: Bool = false
    @State private var showResetConfirm: Bool = false

    private let destination: Destination

    init(@ViewBuilder destination: () -> Destination) {
        self.destination = destination()
    }

    private var isLockActive: Bool {
        let digits = storedPasscode.filter { $0.isNumber }
        return isEnabled && digits.count == 4
    }

    var body: some View {
        if !isLockActive || isUnlocked {
            destination
        } else {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("パスコードを入力してください")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top, 32)

                    Text("設定をひらくための4桁の数字を入れます。")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    TextField("4桁の数字", text: $input)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(size: 28))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 32)
                        // iOS17+ 形式（あなたのターゲットが iOS18 ならこれでOK）
                        .onChange(of: input) { _, newValue in
                            let digits = newValue.filter { $0.isNumber }
                            input = String(digits.prefix(4))
                        }

                    Button { checkPasscode() } label: {
                        Text("つぎへ")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.yasasumaGreen)
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                    if showError {
                        Text("パスコードがちがいます。もう一度おためしください。")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    Button { showResetConfirm = true } label: {
                        Text("パスコードを忘れた")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .underline()
                    }
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .alert("パスコードをリセットします", isPresented: $showResetConfirm) {
                Button("キャンセル", role: .cancel) { }
                Button("リセットする", role: .destructive) { resetPasscode() }
            } message: {
                Text(
                    """
                    設定画面に入るための4桁のパスコードを消して、
                    パスコードのロックをやめます。

                    もう一度ロックをかけたいときは、
                    設定画面の「パスコードの設定」から
                    あたらしく登録してください。
                    """
                )
            }
        }
    }

    private func checkPasscode() {
        let stored = storedPasscode.filter { $0.isNumber }
        let entered = input.filter { $0.isNumber }
        if stored.count == 4 && stored == entered {
            isUnlocked = true
            showError = false
        } else {
            showError = true
        }
    }

    private func resetPasscode() {
        storedPasscode = ""
        isEnabled = false
        input = ""
        showError = false
        isUnlocked = true
    }
}

