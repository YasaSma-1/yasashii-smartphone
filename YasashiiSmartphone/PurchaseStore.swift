import Foundation
import Combine

/// 課金プラン種別
enum YasasumaPlan: String, CaseIterable, Identifiable {
    case monthly   // 月額
    case yearly    // 年額

    var id: String { rawValue }
}

/// やさしいスマホの課金状態を管理するストア
/// 今はシンプルに「購入済みかどうか」だけを扱う。
final class PurchaseStore: ObservableObject {

    /// 有料版がアンロックされているかどうか
    @Published var isProUnlocked: Bool {
        didSet {
            UserDefaults.standard.set(isProUnlocked, forKey: storageKey)
        }
    }

    private let storageKey = "yasasuma_isProUnlocked"

    init() {
        // 保存されていなければ false（無料版）として扱う
        self.isProUnlocked = UserDefaults.standard.bool(forKey: storageKey)
    }
}

