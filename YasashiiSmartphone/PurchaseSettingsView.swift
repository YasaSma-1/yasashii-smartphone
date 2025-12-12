import SwiftUI

struct PurchaseSettingsView: View {
    @EnvironmentObject var purchaseStore: PurchaseStore
    @Environment(\.openURL) private var openURL

    @State private var selectedPlan: YasasumaPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseErrorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    if purchaseStore.isProUnlocked {
                        subscribedContent
                    } else {
                        unsubscribedContent
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("有料プラン")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 課金前 UI

    private var unsubscribedContent: some View {
        VStack(spacing: 18) {

            Text("やさスマプレミアムでできること")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)

            FeatureComparisonCard()

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

            VStack(spacing: 24) {
                Button {
                    Task { await handleStartWithSelectedPlan() }
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
                .disabled(isPurchasing)

                if let message = purchaseErrorMessage {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await restorePurchases() }
                } label: {
                    Text("購入情報を復元する")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.yasasumaGreen)
                }
                .buttonStyle(.plain)

                Text("お支払いは Apple ID に請求されます。解約は iPhone の「サブスクリプション」設定から行えます。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 課金後 UI

    private var subscribedContent: some View {
        VStack(spacing: 24) {

            Text("サブスクリプションの状態")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                        Image(systemName: "phone.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("やさしいスマホ")
                            .font(.system(size: 16, weight: .semibold))
                        Text("やさスマ プレミアム")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    Image(systemName: "creditcard")
                        .imageScale(.medium)
                    Text(subscribedPlanDescription)
                        .font(.system(size: 15))
                }


                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .imageScale(.medium)
                    Text("自動更新：オン")
                        .font(.system(size: 15))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)

            Button {
                openSubscriptionSettings()
            } label: {
                Text("サブスクリプションを管理する")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                    )
            }
            .buttonStyle(.plain)

            Text("サブスクリプションのキャンセルや変更は、App Store の「サブスクリプション」画面で行えます。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                openSubscriptionSettings()
            } label: {
                Text("サブスクリプションとプライバシーについて")
                    .font(.system(size: 13))
                    .foregroundColor(Color.blue)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - ロジック

    private var buttonTitle: String {
        switch selectedPlan {
        case .monthly:
            return "月額プランでアップグレード"
        case .yearly:
            return "年額プランでアップグレード"
        }
    }
    /// 契約中プランの表示文言
        private var subscribedPlanDescription: String {
            switch purchaseStore.activePlan {
            case .monthly:
                return "月額 ￥480"
            case .yearly:
                return "年額 ￥3,900"
            case nil:
                return "プレミアムプラン"
            }
        }


    @MainActor
    func handleStartWithSelectedPlan() async {
        guard !isPurchasing else { return }

        isPurchasing = true
        purchaseErrorMessage = nil

        do {
            try await purchaseStore.purchase(plan: selectedPlan)
            isPurchasing = false

            // ✅ Proが有効になったら、レビュー依頼候補
            if purchaseStore.isProUnlocked {
                ReviewRequestManager.shared.maybeRequestReview(trigger: .purchasedPro)
            }
        } catch {
            isPurchasing = false

            if let localized = error as? LocalizedError,
               let description = localized.errorDescription {
                purchaseErrorMessage = description
            } else {
                purchaseErrorMessage = "購入に失敗しました。時間をおいて、もう一度お試しください。"
            }
        }
    }

    @MainActor
    private func restorePurchases() async {
        guard !isPurchasing else { return }

        isPurchasing = true
        purchaseErrorMessage = nil

        do {
            try await purchaseStore.restorePurchases()
            isPurchasing = false
        } catch {
            isPurchasing = false

            if let localized = error as? LocalizedError,
               let description = localized.errorDescription {
                purchaseErrorMessage = description
            } else {
                purchaseErrorMessage = "購入情報の復元に失敗しました。時間をおいて、もう一度お試しください。"
            }
        }
    }

    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            openURL(url)
        }
    }
}

// MARK: - 内部コンポーネント（比較表とプランカード）

extension PurchaseSettingsView {

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

