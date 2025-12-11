import SwiftUI

struct HomeAppsSettingsView: View {
    @AppStorage("yasasuma_showPhone") private var showPhone = true
    @AppStorage("yasasuma_showCalendar") private var showCalendar = true
    @AppStorage("yasasuma_showMap") private var showMap = true
    @AppStorage("yasasuma_showCamera") private var showCamera = false
    @AppStorage("yasasuma_showPhotos") private var showPhotos = false

    var body: some View {
        Form {
            Section(
                header: Text("ホームに表示するアプリ")
            ) {
                Toggle("電話", isOn: $showPhone)
                Toggle("予定", isOn: $showCalendar)
                Toggle("地図", isOn: $showMap)
                Toggle("カメラ", isOn: $showCamera)
                Toggle("写真", isOn: $showPhotos)
            }

            Section(footer:
                Text("ホーム画面に表示するアプリを、必要なものだけにしぼれます。")
                    .font(.footnote)
            ) {
                EmptyView()
            }
        }
        .navigationTitle("ホームに表示するアプリ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

