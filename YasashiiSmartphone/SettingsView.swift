import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // タイトル
                    Text("設定")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)

                    // 📞 電話の設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("電話の設定")
                            .font(.system(size: 20, weight: .bold))

                        VStack(spacing: 12) {
                            NavigationLink {
                                FavoriteContactsSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "person.2.fill",
                                    iconColor: Color.yasasumaGreen,
                                    title: "よくかける相手（電話帳）",
                                    subtitle: "「電話」画面に出す相手を確認できます。"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // 🗺️ 地図の設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("地図の設定")
                            .font(.system(size: 20, weight: .bold))

                        VStack(spacing: 12) {
                            NavigationLink {
                                DestinationSettingsView()
                            } label: {
                                SettingsMenuCard(
                                    iconName: "mappin.and.ellipse",
                                    iconColor: Color.yasasumaGreen,
                                    title: "よく行く場所",
                                    subtitle: "「道をみる」画面で使う行き先を設定できます。"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // 🔒 アプリの安全設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("アプリの安全設定")
                            .font(.system(size: 20, weight: .bold))

                        SettingsRowCard(
                            iconName: "lock.fill",
                            title: "設定画面に入る合言葉",
                            subtitle: "※あとで追加予定です。今はまだ使えません。"
                        )
                        .opacity(0.5)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24)
            }
        }
    }
}
    
    /// 設定の1行カード（スキューモーフィック気味）
    struct SettingsRowCard: View {
        let iconName: String
        let title: String
        let subtitle: String?
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(.systemGray5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.8),
                                radius: 2,
                                x: -1,
                                y: -1)
                        .shadow(color: .black.opacity(0.2),
                                radius: 3,
                                x: 2,
                                y: 2)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.yasasumaGreen)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(.systemGray5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.8),
                            radius: 3,
                            x: -2,
                            y: -2)
                    .shadow(color: .black.opacity(0.2),
                            radius: 4,
                            x: 2,
                            y: 3)
            )
        }
    }
    
    // 設定メニュー共通カード
    struct SettingsMenuCard: View {
        let iconName: String
        let iconColor: Color
        let title: String
        let subtitle: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(iconColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.label))
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.8),
                            radius: 3, x: -2, y: -2)
                    .shadow(color: .black.opacity(0.15),
                            radius: 4, x: 2, y: 3)
            )
        }
    }
    

