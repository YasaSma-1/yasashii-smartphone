import Foundation
import Combine
import StoreKit

/// 課金プラン種別
enum YasasumaPlan: String, CaseIterable, Identifiable {
    case monthly   // 月額
    case yearly    // 年額

    var id: String { rawValue }

    /// App Store Connect で作成した Product ID に合わせてください
    var productID: String {
        switch self {
        case .monthly:
            return "yasasuma_premium_monthly"   // 例：月額480円
        case .yearly:
            return "yasasuma_premium_yearly"    // 例：年額3,900円
        }
    }

    /// StoreKit の transaction.productID から YasasumaPlan に逆変換
    static func from(productID: String) -> YasasumaPlan? {
        switch productID {
        case YasasumaPlan.monthly.productID:
            return .monthly
        case YasasumaPlan.yearly.productID:
            return .yearly
        default:
            return nil
        }
    }
}

/// やさしいスマホの課金状態を管理するストア
@MainActor
final class PurchaseStore: ObservableObject {

    /// 有料版がアンロックされているかどうか
    @Published private(set) var isProUnlocked: Bool {
        didSet {
            UserDefaults.standard.set(isProUnlocked, forKey: isProStorageKey)
        }
    }

    /// 現在アクティブなプラン（分かる範囲で）
    @Published private(set) var activePlan: YasasumaPlan? {
        didSet {
            if let plan = activePlan {
                UserDefaults.standard.set(plan.rawValue, forKey: planStorageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: planStorageKey)
            }
        }
    }

    private let isProStorageKey = "yasasuma_isProUnlocked"
    private let planStorageKey  = "yasasuma_activePlan"

    /// サブスクリプション更新を監視するタスク
    private var updatesTask: Task<Void, Never>?

    init() {
        // ローカル保存されている状態を一旦読み込む
        self.isProUnlocked = UserDefaults.standard.bool(forKey: isProStorageKey)

        if let raw = UserDefaults.standard.string(forKey: planStorageKey),
           let plan = YasasumaPlan(rawValue: raw) {
            self.activePlan = plan
        } else {
            self.activePlan = nil
        }

        // トランザクション更新の監視を開始
        updatesTask = observeTransactionUpdates()

        // 起動直後に最新のエンタイトルメントを取り直す
        Task {
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 公開 API

    /// 指定したプランを購入
    func purchase(plan: YasasumaPlan) async throws {
        let product = try await product(for: plan)
        let result  = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // 購入成功 → エンタイトルメント更新
            await refreshEntitlements()
            await transaction.finish()

        case .userCancelled, .pending:
            // キャンセル / 保留はエラー扱いにしない
            return

        @unknown default:
            return
        }
    }

    /// 購入情報の復元
    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    /// 現在のエンタイトルメントから isPro / activePlan を再計算
    func refreshEntitlements() async {
        var newIsPro = false
        var newPlan: YasasumaPlan?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if let plan = YasasumaPlan.from(productID: transaction.productID) {
                newIsPro = true
                newPlan  = plan
            }
        }

        self.isProUnlocked = newIsPro
        self.activePlan    = newPlan
    }

    // MARK: - プライベートヘルパ

    /// プランに対応する Product を取得
    private func product(for plan: YasasumaPlan) async throws -> Product {
        let ids: Set<String> = [
            YasasumaPlan.monthly.productID,
            YasasumaPlan.yearly.productID
        ]

        let products = try await Product.products(for: ids)
        guard let product = products.first(where: { $0.id == plan.productID }) else {
            throw StoreError.productNotFound
        }
        return product
    }

    /// トランザクション更新を監視
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                guard case .verified(let transaction) = result else { continue }

                if YasasumaPlan.from(productID: transaction.productID) != nil {
                    // 自分のプロダクトであれば状態を更新
                    await self.refreshEntitlements()
                }

                await transaction.finish()
            }
        }
    }

    /// App Store からの検証結果をチェック
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, _):
            throw StoreError.failedVerification
        }
    }

    // MARK: - エラー定義

    enum StoreError: LocalizedError {
        case failedVerification
        case productNotFound

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "購入情報の確認に失敗しました。通信状況を確認して、もう一度お試しください。"
            case .productNotFound:
                return "課金商品の情報が見つかりませんでした。アプリを再起動してからお試しください。"
            }
        }
    }
}

