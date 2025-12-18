import SwiftUI

struct PurchaseSettingsView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore

    @State private var selectedPlan: YasasumaPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseErrorMessage: String?

    // ✅ Review用：機能するリンク（バイナリ内）
    private let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/1-vFWUYwsOLUemHcwBM9GqYjAmHi8x8w-TbAUmj8aUmg/edit?usp=sharing")
    private let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {

                    Text("やさスマプレミアムでできること")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)

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
                            ) { selectedPlan = .monthly }

                            SelectablePlanRow(
                                title: "年額プラン",
                                priceMain: "￥3,900 / 年",
                                caption: "12ヶ月分（￥5,760）より約33％お得。",
                                isSelected: selectedPlan == .yearly,
                                badge: "おすすめ"
                            ) { selectedPlan = .yearly }
                        }
                    }

                    VStack(spacing: 18) {
                        Button {
                            Task { await handleStartWithSelectedPlan() }
                        } label: {
                            Text(buttonTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 26)
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

                        Text("お支払いは Apple ID に請求されます。いつでも解約できます。")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // ✅ ここだけ：リンク（中央揃え）＋注意文は削除
                        HStack(spacing: 12) {
                            if let url = privacyPolicyURL {
                                Link("プライバシーポリシー", destination: url)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.yasasumaGreen)
                            }

                            Text("・")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            if let url = eulaURL {
                                Link("利用規約（EULA）", destination: url)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.yasasumaGreen)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("有料プラン（やさスマプレミアム）")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var buttonTitle: String {
        switch selectedPlan {
        case .monthly: return "月額プランでアップグレード"
        case .yearly:  return "年額プランでアップグレード"
        }
    }

    @MainActor
    private func handleStartWithSelectedPlan() async {
        guard !isPurchasing else { return }

        isPurchasing = true
        purchaseErrorMessage = nil

        do {
            try await purchaseStore.purchase(plan: selectedPlan)
            isPurchasing = false

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
}

// MARK: - 内部コンポーネント
extension PurchaseSettingsView {

    struct FeatureComparisonCard: View {
        private struct Row: Identifiable {
            let id = UUID()
            let icon: String
            let title: String
            let description: String
            let freeText: String
            let proText: String
        }

        private let rows: [Row] = [
            .init(icon: "calendar", title: "予定", description: "各日に登録できる予定の件数", freeText: "1件まで", proText: "無制限"),
            .init(icon: "phone",    title: "電話", description: "登録できる「よく電話をかける相手」の件数", freeText: "2件まで", proText: "無制限"),
            .init(icon: "map",      title: "地図", description: "登録できる「よく行く場所」の件数", freeText: "2件まで", proText: "無制限")
        ]

        private let freeWidth: CGFloat = 86
        private let proWidth: CGFloat = 124

        private let lineColor = Color(.systemGray4)
        private let freeValueBG = Color(.systemGray6)

        var body: some View {
            VStack(spacing: 0) {
                headerRow
                ForEach(rows) { row in
                    Divider().background(lineColor)
                    tableRow(row)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(lineColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        }

        private var headerRow: some View {
            HStack(spacing: 0) {
                Text("機能")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)

                verticalDivider

                Text("無料")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: freeWidth)
                    .padding(.vertical, 12)

                verticalDivider

                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                    Text("プレミアム")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                .frame(width: proWidth)
                .padding(.vertical, 12)
            }
            .frame(minHeight: 44)
        }

        private func tableRow(_ row: Row) -> some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: row.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.yasasumaGreen)
                            .frame(width: 22)

                        Text(row.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.yasasumaGreen)
                    }

                    Text(row.description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)

                verticalDivider

                ZStack {
                    Rectangle().fill(freeValueBG)
                    Text(row.freeText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .frame(width: freeWidth)
                .frame(maxHeight: .infinity)

                verticalDivider

                ZStack {
                    Color.clear
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.yasasumaGreen)
                        Text(row.proText)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .frame(width: proWidth)
                .frame(maxHeight: .infinity)
            }
        }

        private var verticalDivider: some View {
            Rectangle()
                .fill(lineColor)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
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
                                    .background(Capsule().fill(Color.yasasumaGreen.opacity(0.15)))
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
                                .stroke(isSelected ? Color.yasasumaGreen : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

