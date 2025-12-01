import SwiftUI
import MapKit

// MARK: - 設定 > よく行く場所 一覧

struct DestinationSettingsView: View {
    @EnvironmentObject var destinationStore: DestinationStore

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section(
                    footer: footerText
                ) {
                    if destinationStore.destinations.isEmpty {
                        Text("まだ登録されていません。")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(destinationStore.destinations) { dest in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dest.name)
                                    .font(.body.bold())
                                if !dest.detail.isEmpty {
                                    Text(dest.detail)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteDestinations)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("よく行く場所")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        showingAddSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            EditDestinationView { newDest in
                destinationStore.destinations.append(newDest)
            }
        }
    }

    private var footerText: some View {
        Text("削除するには、行を左にスワイプします。")
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func deleteDestinations(at offsets: IndexSet) {
        destinationStore.destinations.remove(atOffsets: offsets)
    }
}


// MARK: - 場所追加フォーム（シンプル版）

import SwiftUI
import MapKit

// MARK: - 場所追加フォーム（標準UI版）

struct EditDestinationView: View {
    @Environment(\.dismiss) private var dismiss

    // 基本情報
    @State private var name: String = ""
    @State private var detail: String = ""

    // 場所（どこをえらんだか）
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var locationLabel: String = ""   // 住所などの表示用

    let onSave: (Destination) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // ① 場所の名前
                Section("場所の名前") {
                    TextField("例：病院、スーパー、駅など", text: $name)
                }

                // ② 場所のえらび方
                Section("場所") {
                    if let coordinate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(locationLabel.isEmpty ? "場所がえらばれました" : locationLabel)
                                .font(.subheadline)

                            Text(String(format: "緯度 %.4f / 経度 %.4f",
                                        coordinate.latitude,
                                        coordinate.longitude))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("ことばでさがすか、地図から場所をえらんでください。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    // ことばでさがす（Appleマップの検索結果リスト）
                    NavigationLink("ことばでさがす") {
                        NameSearchView { item in
                            coordinate = item.placemark.coordinate
                            locationLabel = makeLabel(from: item)

                            // 名前がまだ空なら、候補の名称をそのまま使う
                            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               let itemName = item.name {
                                name = itemName
                            }
                        }
                    }

                    // 地図からえらぶ（地図中心の位置を選択）
                    NavigationLink("地図からえらぶ") {
                        MapPickerView(initialCoordinate: coordinate) { coord in
                            coordinate = coord
                            // 住所は逆引きしない。とりあえず「場所がえらばれました」とだけ表示。
                            locationLabel = ""
                        }
                    }
                }

                // ③ メモ
                Section("メモ（どこの場所か）") {
                    TextField("例：〇〇クリニック、△△スーパーなど", text: $detail)
                }
            }
            .navigationTitle("場所を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // 保存できる条件：名前あり ＋ 場所が決まっている
    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && coordinate != nil
    }

    private func save() {
        guard let coordinate else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let dest = Destination(
            name: trimmedName,
            detail: detail,
            coordinate: coordinate
        )
        onSave(dest)
        dismiss()
    }

    // 検索結果から表示用のラベルをつくる
    private func makeLabel(from item: MKMapItem) -> String {
        if let name = item.name, let title = item.placemark.title {
            if title.contains(name) {
                return title
            } else {
                return "\(name) / \(title)"
            }
        } else {
            return item.placemark.title ?? ""
        }
    }
}

// MARK: - 名前で場所をさがす画面

struct NameSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var keyword: String = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching: Bool = false

    let onSelect: (MKMapItem) -> Void

    var body: some View {
        List {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView("検索中…")
                    Spacer()
                }
            } else if results.isEmpty && !keyword.isEmpty {
                Text("場所が見つかりませんでした。")
                    .foregroundColor(.secondary)
            } else {
                ForEach(results, id: \.self) { item in
                    Button {
                        onSelect(item)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "名称なし")
                                .font(.body)
                            if let title = item.placemark.title {
                                Text(title)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("ことばでさがす")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $keyword,
                    placement: .navigationBarDrawer,
                    prompt: "住所や施設名")
        .onSubmit(of: .search) {
            search()
        }
        .onChange(of: keyword) { newValue in
            if newValue.isEmpty {
                results = []
            }
        }
    }

    private func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        results = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    results = response.mapItems
                } else {
                    results = []
                }
            }
        }
    }
}

// MARK: - 地図から場所をえらぶ画面

struct MapPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion

    let onSelect: (CLLocationCoordinate2D) -> Void

    init(initialCoordinate: CLLocationCoordinate2D?,
         onSelect: @escaping (CLLocationCoordinate2D) -> Void) {

        self.onSelect = onSelect

        let center = initialCoordinate ?? CLLocationCoordinate2D(
            latitude: 35.6812,
            longitude: 139.7671   // 東京駅あたり
        )

        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Map(coordinateRegion: $region)
                    .ignoresSafeArea(edges: .bottom)

                // 画面中央のピン（地図だけ動く）
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.yasasumaGreen)
                    .shadow(radius: 4)
            }

            VStack(spacing: 8) {
                Text("地図を動かして、ピンの場所を決めてください。")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button {
                    onSelect(region.center)
                    dismiss()
                } label: {
                    Text("この場所をえらぶ")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("地図からえらぶ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
