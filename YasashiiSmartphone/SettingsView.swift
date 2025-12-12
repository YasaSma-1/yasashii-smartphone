import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {

                    settingsSection(title: "電話") {
                        NavigationLink {
                            FavoriteContactsSettingsView()
                        } label: {
                            SettingsMenuCard(
                                iconName: "person.2.fill",
                                iconColor: .yasasumaGreen,
                                title: "よくかける相手（電話帳）",
                                subtitle: "電話に出す相手を編集します。"
                            )
                        }
                    }

                    settingsSection(title: "地図") {
                        NavigationLink {
                            DestinationSettingsView()
                        } label: {
                            SettingsMenuCard(
                                iconName: "mappin.and.ellipse",
                                iconColor: .yasasumaGreen,
                                title: "よく行く場所",
                                subtitle: "地図で使う行き先を編集します。"
                            )
                        }
                    }

                    settingsSection(title: "ホーム") {
                        NavigationLink {
                            HomeAppsSettingsView()
                        } label: {
                            SettingsMenuCard(
                                iconName: "square.grid.2x2",
                                iconColor: .yasasumaGreen,
                                title: "ホームに表示するアプリ",
                                subtitle: "ホームに出すアプリを選べます。"
                            )
                        }
                    }

                    settingsSection(title: "安全") {
                        NavigationLink {
                            PasscodeSettingsView()
                        } label: {
                            SettingsMenuCard(
                                iconName: "lock.fill",
                                iconColor: .yasasumaGreen,
                                title: "設定画面のパスコード（4桁）",
                                subtitle: "設定を開く前に4桁の入力を求めます。"
                            )
                        }
                    }

                    settingsSection(title: "課金") {
                        NavigationLink {
                            PurchaseSettingsView()
                        } label: {
                            SettingsMenuCard(
                                iconName: "creditcard.fill",
                                iconColor: .yasasumaGreen,
                                title: "有料プラン（やさスマプレミアム）",
                                subtitle: "プランの確認・アップグレード。"
                            )
                        }
                    }

                    Spacer(minLength: 28)
                }
                .padding(.top, 18)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section Wrapper

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                content()
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 10)
    }
}

// MARK: - 共通カードUI

struct SettingsMenuCard: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15),
                            radius: 3, x: 0, y: 2)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08),
                        radius: 3, x: 0, y: 2)
        )
    }
}

