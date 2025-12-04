import SwiftUI
import Foundation

struct PaywallView: View {
    @EnvironmentObject var purchaseStore: PurchaseStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPurchaseSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("有料版のご案内")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, 24)
                    
                    // メイン説明
                    Text("無料版では、つぎのような制限があります。")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("・予定")
                            .font(.system(size: 17, weight: .semibold))
                        Text("　少ない件数のみ登録できます。たくさんの予定管理には向いていません。")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("・よくかける相手（電話帳）")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.top, 4)
                        Text("　無料版では 2件 まで登録できます。3人目以降を登録するには有料版が必要です。")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("・よく行く場所")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.top, 4)
                        Text("　登録できる行き先の数に上限があります。")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // おすすめ文
                    VStack(alignment: .leading, spacing: 8) {
                        Text("こんな方におすすめ")
                            .font(.system(size: 18, weight: .semibold))
                        Text("""
・家族や病院など、よくかける相手をたくさん登録したい
・病院やスーパーなど、よく行く場所をいくつも登録したい
・通院やデイサービス、買い物などの予定をまとめて管理したい
"""
                        )
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    }
                    
                    // 課金画面へのボタン
                    Button {
                        showPurchaseSheet = true
                    } label: {
                        Text("課金・ライセンス画面を開く")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.yasasumaGreen)
                            )
                    }
                    .padding(.top, 8)
                    
                    Text("購入手続きは、ふだんスマホの管理をしているご家族の方にお願いする想定です。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("とじる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPurchaseSheet) {
                NavigationStack {
                    PurchaseSettingsView()
                        .environmentObject(purchaseStore)
                }
            }
        }
    }
}
