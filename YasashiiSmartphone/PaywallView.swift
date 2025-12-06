import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchaseStore: PurchaseStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: YasasumaPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // タイトルのみ（キャプションなし）
                        Text("やさスマプレミアムでできること")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // 比較表
                        FeatureComparisonCard()

                        // プラン選択
                        VStack(alignment: .leading, spacing: 12) {
                            Text("プランを選ぶ")
                                .font(.system(size: 18, weight: .semibold))

                            VStack(spacing: 12) {
                                SelectablePlanRow(
                                    title: "月額プラン",
                                    priceMain: "￥480 / 月",
                                    caption: "月ごとのお支払い。",
                                    isSelected: selectedPlan == .monthly,
                                    badge: nil
                                ) {
                                    selectedPlan = .monthly
                                }

                                SelectablePlanRow(
                                    title: "年額プラン",
                                    priceMain: "￥3,900 / 年",
                                    caption: "12ヶ月分（￥5,760）より約33％お得。",
                                    isSelected: selectedPlan == .yearly,
                                    badge: "おすすめ"
                                ) {
                                    selectedPlan = .yearly
                                }
                            }
                        }

                        // CTA
                        VStack(spacing: 8) {
                            Button {
                                Task { await handlePurchase() }
                            } label: {
                                Text(buttonTitle)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(Color.yasasumaGreen)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing || purchaseStore.isProUnlocked)

                            if purchaseStore.isProUnlocked {
                                Text("現在プレミアム版をご利用中です。")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if let message = purchaseErrorMessage {
                                Text(message)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Text("お支払いは Apple ID に請求されます。いつでも解約できます。")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("プレミアム版")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("とじる") { dismiss() }
                }
            }
        }
    }

    private var buttonTitle: String {
        if purchaseStore.isProUnlocked {
            return "プレミアム版をご利用中です"
        }
        switch selectedPlan {
        case .monthly:
            return "月額プランでアップグレード"
        case .yearly:
            return "年額プランでアップグレード"
        }
    }

    private func handlePurchase() async {
        guard !isPurchasing, !purchaseStore.isProUnlocked else { return }

        await MainActor.run {
            isPurchasing = true
            purchaseErrorMessage = nil
        }

        // TODO: StoreKit 2 で selectedPlan に応じた課金処理を実装
        // switch selectedPlan {
        // case .monthly:
        //     try await purchaseStore.purchaseMonthly()
        // case .yearly:
        //     try await purchaseStore.purchaseYearly()
        // }

        // ダミー実装
        await MainActor.run {
            purchaseStore.isProUnlocked = true
            isPurchasing = false
        }
    }
}

// MARK: - PaywallView 内部コンポーネント

extension PaywallView {

    struct FeatureComparisonCard: View {

        struct Row: Identifiable {
            let id = UUID()
            let feature: String
            let freeText: String
            let proText: String
        }

        private let rows: [Row] = [
            .init(feature: "1日に登録できる予定の件数",
                  freeText: "1件まで",
                  proText: "無制限"),
            .init(feature: "「よくかける相手」の件数",
                  freeText: "2件まで",
                  proText: "無制限"),
            .init(feature: "「よく行く場所」の件数",
                  freeText: "2件まで",
                  proText: "無制限")
        ]

        var body: some View {
            VStack(spacing: 0) {
                // ヘッダー行（行全体グリーン＋角丸が効くように後で clip）
                HStack {
                    Text("機能")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("無料")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 80, alignment: .center)

                    Text("プレミアム")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 90, alignment: .center)
                }
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.yasasumaGreen.opacity(0.5))

                Divider()

                ForEach(rows) { row in
                    HStack(alignment: .center) {
                        Text(row.feature)
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(row.freeText)
                            .font(.system(size: 15))
                            .frame(width: 80, alignment: .center)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.yasasumaGreen)
                                .imageScale(.small)
                            Text(row.proText)
                        }
                        .font(.system(size: 15))
                        .frame(width: 90, alignment: .center)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    if row.id != rows.last?.id {
                        Divider()
                    }
                }
            }
            // カード全体に白背景＋角丸＋clip でヘッダーも一緒に丸める
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        }
    }

    struct SelectablePlanRow: View {
        let title: String
        let priceMain: String
        let caption: String
        let isSelected: Bool
        let badge: String?
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {

                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray3), lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(Color.yasasumaGreen)
                                .frame(width: 14, height: 14)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 16, weight: .semibold))

                            if let badge = badge {
                                Text(badge)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.yasasumaGreen.opacity(0.15))
                                    )
                                    .foregroundColor(Color.yasasumaGreen)
                            }
                        }

                        Text(caption)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(priceMain)
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.yasasumaGreen : Color.clear,
                                        lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

