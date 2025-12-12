import Foundation
import StoreKit
import UIKit

/// App Store レビュー依頼を一元管理するマネージャ
@MainActor
final class ReviewRequestManager {

    static let shared = ReviewRequestManager()

    // MARK: - 内部状態

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let launchCount           = "yasasuma_review_launchCount"
        static let firstLaunchDate       = "yasasuma_review_firstLaunchDate"
        static let lastReviewPromptDate  = "yasasuma_review_lastReviewPromptDate"
        static let reviewPromptCountYear = "yasasuma_review_promptCountYear"
        static let lastReviewYear        = "yasasuma_review_lastReviewYear"
        static let reviewPromptDisabled  = "yasasuma_review_promptDisabled"
    }

    /// ロジック用のパラメータ（必要なら後で調整）
    private let minDaysSinceFirstLaunch = 3      // 初回起動から最低 3日
    private let minLaunchCount          = 3      // 起動回数 3回以上
    private let maxPromptsPerYear       = 4      // 1年に最大 4回まで
    private let minDaysBetweenPrompts   = 30     // 最低 30日間は間隔を空ける

    /// どのイベントから呼ばれたか（今はログ用の意味合いが強い）
    enum Trigger {
        case addedEvents
        case addedFavoriteContacts
        case addedDestinations
        case purchasedPro
    }

    private init() {
        // 初回起動日が未保存なら、ここで保存しておく
        if defaults.object(forKey: Keys.firstLaunchDate) as? Date == nil {
            defaults.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }

    // MARK: - 公開 API

    /// アプリ起動（もしくはホーム画面表示）時に呼ぶ
    func notifyAppLaunched() {
        let current = defaults.integer(forKey: Keys.launchCount)
        defaults.set(current + 1, forKey: Keys.launchCount)

        if defaults.object(forKey: Keys.firstLaunchDate) as? Date == nil {
            defaults.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }

    /// レビュー依頼を出すかどうかを判定して、条件を満たせば SKStoreReviewController を呼ぶ
    func maybeRequestReview(trigger: Trigger) {
        // 将来「今後表示しない」対応するためのフラグ（今は false のまま）
        if defaults.bool(forKey: Keys.reviewPromptDisabled) {
            return
        }

        let now = Date()
        let calendar = Calendar.current

        // 初回起動日
        guard let firstLaunchDate = defaults.object(forKey: Keys.firstLaunchDate) as? Date else {
            defaults.set(now, forKey: Keys.firstLaunchDate)
            return
        }

        // 初回起動からの日数
        let daysSinceFirstLaunch = now.timeIntervalSince(firstLaunchDate) / (60 * 60 * 24)
        guard daysSinceFirstLaunch >= Double(minDaysSinceFirstLaunch) else {
            return
        }

        // 起動回数
        let launchCount = defaults.integer(forKey: Keys.launchCount)
        guard launchCount >= minLaunchCount else { return }

        // 年ごとの回数制限
        let thisYear = calendar.component(.year, from: now)
        var storedYear = defaults.integer(forKey: Keys.lastReviewYear)
        var countThisYear = defaults.integer(forKey: Keys.reviewPromptCountYear)

        // 年が変わったらカウントリセット
        if storedYear == 0 || storedYear != thisYear {
            storedYear = thisYear
            countThisYear = 0
        }

        guard countThisYear < maxPromptsPerYear else { return }

        // 直近の表示からの日数制限
        if let lastPromptDate = defaults.object(forKey: Keys.lastReviewPromptDate) as? Date {
            let daysSinceLastPrompt = now.timeIntervalSince(lastPromptDate) / (60 * 60 * 24)
            if daysSinceLastPrompt < Double(minDaysBetweenPrompts) {
                return
            }
        }

        // ここまで来たら、実際にレビュー依頼
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)

        // 状態更新
        defaults.set(now, forKey: Keys.lastReviewPromptDate)
        defaults.set(thisYear, forKey: Keys.lastReviewYear)
        defaults.set(countThisYear + 1, forKey: Keys.reviewPromptCountYear)
    }

    /// 将来的に「今後表示しない」ボタンを付ける場合用（今は未使用）
    func disableReviewPrompt() {
        defaults.set(true, forKey: Keys.reviewPromptDisabled)
    }
}

