import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 📞 電話の設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("電話の設定")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            NavigationLink {
                                FavoriteContactsSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "person.2.fill",
                                    iconColor: Color.yasasumaGreen,
                                    title: "よくかける相手（電話帳）",
                                    subtitle: "「電話」画面に出す相手を確認・変更できます。"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // 🗺 地図の設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("地図の設定")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            NavigationLink {
                                DestinationSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "mappin.and.ellipse",
                                    iconColor: Color.yasasumaGreen,
                                    title: "よく行く場所",
                                    subtitle: "「地図」画面で使う行き先を設定できます。"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // 🏠 ホーム画面に表示するアプリ
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ホーム画面")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            NavigationLink {
                                HomeAppsSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "square.grid.2x2",
                                    iconColor: Color.yasasumaGreen,
                                    title: "ホームに表示するアプリ",
                                    subtitle: "ホーム画面に出すアプリをえらべます。"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // 🔒 アプリの安全設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("アプリの安全設定")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            NavigationLink {
                                PasscodeSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "lock.fill",
                                    iconColor: Color.yasasumaGreen,
                                    title: "設定画面に入るパスコード（4桁）",
                                    subtitle: "設定画面をひらく前に4桁の数字を入力させるかどうかを設定できます。"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // 💳 アプリのご利用と課金（いちばん下）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("アプリのご利用と課金")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            NavigationLink {
                                PurchaseSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "creditcard.fill",
                                    iconColor: Color.yasasumaGreen,
                                    title: "有料プラン（やさスマ プレミアム）",
                                    subtitle: "無料版の制限と、ご利用中のプランを確認できます。"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 24)
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
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
            // アイコン
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

            // タイトル＋サブタイトル
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 14))
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

