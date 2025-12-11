import SwiftUI
import Combine

struct ContentView: View {
    // ⏰ 今の日時を持っておく
    @State private var now = Date()
    // 1秒ごとにイベントを流してくれるタイマー
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // 2列レイアウト
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    // ホームに表示するアプリ（デフォルトは全部 true）
    @AppStorage("yasasuma_showPhone")   private var showPhone: Bool   = true
    @AppStorage("yasasuma_showCalendar") private var showCalendar: Bool = true
    @AppStorage("yasasuma_showMap")     private var showMap: Bool     = true
    @AppStorage("yasasuma_showCamera")  private var showCamera: Bool  = true
    @AppStorage("yasasuma_showPhotos")  private var showPhotos: Bool  = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    VStack(spacing: 32) {
                        // ⏰ 時刻・日付（リアルタイム表示）
                        VStack(spacing: 8) {
                            Text(timeString)
                                .font(.system(size: 76,
                                              weight: .bold,
                                              design: .rounded))
                            Text(dateString)
                                .font(.system(size: 30,
                                              weight: .medium,
                                              design: .rounded))
                        }
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                        // 📱 2×N 正方形ボタン（表示ONのアプリだけ並べる）
                        LazyVGrid(columns: columns, spacing: 20) {

                            // 1段目：左 電話 / 右 予定
                            if showPhone {
                                NavigationLink {
                                    PhoneView()
                                } label: {
                                    BigIconButton(
                                        systemName: "phone.fill",
                                        title: "電話"
                                    )
                                }
                            }

                            if showCalendar {
                                NavigationLink {
                                    CalendarView()
                                } label: {
                                    BigIconButton(
                                        systemName: "calendar",
                                        title: "予定"
                                    )
                                }
                            }

                            // 2段目：左 カメラ / 右 写真
                            if showCamera {
                                NavigationLink {
                                    CameraView()
                                } label: {
                                    BigIconButton(
                                        systemName: "camera.fill",
                                        title: "カメラ"
                                    )
                                }
                            }

                            if showPhotos {
                                NavigationLink {
                                    PhotoLibraryView()
                                } label: {
                                    BigIconButton(
                                        systemName: "photo.fill.on.rectangle.fill",
                                        title: "写真"
                                    )
                                }
                            }

                            // 3段目：左 地図 / 右 設定
                            if showMap {
                                NavigationLink {
                                    MapView()
                                } label: {
                                    BigIconButton(
                                        systemName: "map.fill",
                                        title: "地図"
                                    )
                                }
                            }

                            // 設定は常に表示
                            NavigationLink {
                                SettingsGateView()
                            } label: {
                                BigIconButton(
                                    systemName: "gearshape.fill",
                                    title: "設定"
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
        // 🔁 タイマーから値が流れてきたら now を更新
        .onReceive(timer) { input in
            now = input
        }
    }

    // 「13:05」みたいな時刻文字列
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: now)
    }

    // 「2025年11月29日（土）」みたいな日付文字列
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（EEE）"
        return formatter.string(from: now)
    }
}

/// スキューモーフィックな正方形ボタン
struct BigIconButton: View {
    let systemName: String
    let title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yasasumaGreen.opacity(0.95),
                            Color.yasasumaGreen.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.6),
                        radius: 3,
                        x: -2,
                        y: -2)
                .shadow(color: .black.opacity(0.35),
                        radius: 6,
                        x: 4,
                        y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.45),
                                lineWidth: 1)
                )

            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 40, weight: .semibold))
                Text(title)
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.25),
                    radius: 2,
                    x: 0,
                    y: 1)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// Accentカラー #0F8200（ボタン専用）
extension Color {
    static let yasasumaGreen = Color(
        red: 15.0 / 255.0,
        green: 130.0 / 255.0,
        blue: 0.0 / 255.0
    )
}

