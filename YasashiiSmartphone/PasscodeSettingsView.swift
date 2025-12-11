import SwiftUI

struct PasscodeSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // パスコード機能のON/OFF
    @AppStorage("yasasumaPasscodeEnabled") private var isEnabled: Bool = false
    // 実際の4桁パスコード
    @AppStorage("yasasumaPasscodeValue") private var storedPasscode: String = ""

    @State private var tempPasscode: String = ""
    @State private var showInvalidAlert = false
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // 🔵 1つの島にまとめたパスコード設定
                Section(
                    header: Text("パスコード設定"),
                    footer: footerText
                ) {
                    Toggle(isOn: $isEnabled) {
                        Text("パスコードを使う")
                    }
                    .font(.system(size: 18))

                    if isEnabled {
                        TextField("4桁の数字を入力してください", text: $tempPasscode)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.system(size: 24))
                            .multilineTextAlignment(.center)
                            .onChange(of: tempPasscode) { newValue in
                                // 数字以外を削除＆4桁まで
                                let digits = newValue.filter { $0.isNumber }
                                tempPasscode = String(digits.prefix(4))
                            }

                        Text("例：1234、0523 など。忘れない数字にしてください。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("パスコードの設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 「保存」だけ
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            // 4桁じゃないとき
            .alert("4桁の数字を入力してください", isPresented: $showInvalidAlert) {
                Button("OK", role: .cancel) { }
            }
            // 保存完了（文言は「保存しました」だけ）
            .alert("保存しました", isPresented: $showSavedAlert) {
                Button("OK") { dismiss() }
            }
            .onAppear {
                tempPasscode = storedPasscode
            }
        }
    }

    // フッターテキスト（説明文）
    private var footerText: some View {
        Text("オンにすると、設定画面を開く前に4桁の数字を入力する画面が出ます。")
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func save() {
        // パスコードを使わない場合は、現在のトグル状態だけ保存して閉じてもOK
        guard isEnabled else {
            showSavedAlert = true
            return
        }

        let digits = tempPasscode.filter { $0.isNumber }
        guard digits.count == 4 else {
            showInvalidAlert = true
            return
        }

        storedPasscode = digits
        showSavedAlert = true
    }
}

