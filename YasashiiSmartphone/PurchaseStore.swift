// PurchaseStore.swift

import Foundation
import Combine

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

