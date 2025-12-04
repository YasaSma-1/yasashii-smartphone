import SwiftUI

struct PurchaseSettingsView: View {
    @EnvironmentObject var purchaseStore: PurchaseStore

    var body: some View {
        Form {
            // 現在の状態
            Section("現在の状態") {
                HStack {
                    Text("プラン")
                    Spacer()
                    Text(purchaseStore.isProUnlocked ? "有料版（買い切り）" : "無料版")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(purchaseStore.isProUnlocked ? Color.yasasumaGreen : .secondary)
                }
            }

            // 無料版の説明
            Section("無料版でできること") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("・今日の予定を 1件 まで登録できます。")
                    Text("・電話の相手や、よく行く場所は制限なく登録できます。")
                    Text("・買い切りの購入をしなくても、そのまま使い続けられます。")
                }
                .font(.system(size: 15))
            }

            // 有料版の説明
            Section("有料版にすると") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("・予定を何件でも登録できます。")
                    Text("・通院、デイサービス、買い物など、1週間分の予定もまとめて管理できます。")
                    Text("・親御さんの「予定」を、家族で一緒に把握しやすくなります。")
                }
                .font(.system(size: 15))
            }

            // ★ 今はテスト用の手動切り替え
            Section("動作テスト（開発・検証用）") {
                Button {
                    purchaseStore.isProUnlocked.toggle()
                } label: {
                    Text(purchaseStore.isProUnlocked
                         ? "無料版に戻す（テスト用）"
                         : "有料版にした状態を試す（テスト用）")
                }
                .foregroundColor(Color.yasasumaGreen)
                .font(.system(size: 16, weight: .semibold))
            }

            // 今後の実装メモ
            Section {
                Text("※ 実際のリリース時には、ここに App Store の課金処理（買い切り）ボタンと「購入を復元」ボタンを追加します。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("課金・ライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

