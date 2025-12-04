import SwiftUI
import MapKit

// MARK: - 設定 > よく行く場所 一覧

struct DestinationSettingsView: View {
    @EnvironmentObject var destinationStore: DestinationStore
    @EnvironmentObject var purchaseStore: PurchaseStore      // ★ 課金状態

    @State private var showingAddSheet = false
    @State private var showingPaywall = false                // ★ ペイウォール表示

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
                        handleAddTapped()        // ★ ここで制御
                    }
                }
            }
        }
        // 追加フォーム
        .sheet(isPresented: $showingAddSheet) {
            EditDestinationView { newDest in
                destinationStore.destinations.append(newDest)
            }
        }
        // ペイウォール
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
                    .environmentObject(purchaseStore)
            }
        }
    }

    private var footerText: some View {
        Text("削除する場合は、行を左にスワイプしてください。")
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func deleteDestinations(at offsets: IndexSet) {
        destinationStore.destinations.remove(atOffsets: offsets)
    }

    // MARK: - 追加ボタン押下時の制御（無料版は2件まで）

    private func handleAddTapped() {
        if purchaseStore.isProUnlocked {
            // 有料版なら制限なし
            showingAddSheet = true
            return
        }

        // 無料版：2件までは追加OK
        if destinationStore.destinations.count < 2 {
            showingAddSheet = true
        } else {
            // 3件目以降はペイウォールへ
            showingPaywall = true
        }
    }
}

// MARK: - 場所追加フォーム（場所 → 名前 → メモ）

struct EditDestinationView: View {
    @Environment(\.dismiss) private var dismiss

    // 選ばれた場所
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var locationLabel: String = ""   // 名称のみ

    // 基本情報
    @State private var name: String = ""
    @State private var detail: String = ""

    let onSave: (Destination) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // ① 場所
                Section("場所") {
                    if coordinate != nil {
                        Text(locationLabel.isEmpty ? "選択した場所" : locationLabel)
                            .font(.subheadline)
                    } else {
                        Text("下の「場所を選択」から、よく行く場所を選んでください。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink {
                        MapSearchPickerView(initialCoordinate: coordinate) { item in
                            // 場所確定：座標と名称のみ保存
                            coordinate = item.placemark.coordinate
                            locationLabel = item.name ?? ""

                            // 場所の名前が空なら自動入力
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty, let itemName = item.name {
                                name = itemName
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "map")
                            Text("場所を選択")
                        }
                        .foregroundColor(Color.yasasumaGreen)   // アクセントカラー
                    }
                }

                // ② 場所の名前
                Section("場所の名前") {
                    TextField("例：病院、スーパー、駅など", text: $name)
                }

                // ③ メモ
                Section("メモ") {
                    TextField("例：かかりつけの病院、いつも行くスーパー など", text: $detail)
                }
            }
            .navigationTitle("よく行く場所を追加")
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

    // 保存条件：場所が決まっていて、名前がある
    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return coordinate != nil && !trimmed.isEmpty
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
}

// MARK: - 地図から行き先を選ぶ（検索＋既存スポット）

private struct MapSearchAnnotation: Identifiable {
    let id = UUID()
    let item: MKMapItem

    var coordinate: CLLocationCoordinate2D {
        item.placemark.coordinate
    }
}

struct MapSearchPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion
    @State private var searchText: String = ""
    @State private var results: [MKMapItem] = []

    @State private var selectedItem: MKMapItem? = nil
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil  // ★選択中座標
    @State private var isSearching: Bool = false

    let onSelect: (MKMapItem) -> Void

    init(initialCoordinate: CLLocationCoordinate2D?,
         onSelect: @escaping (MKMapItem) -> Void) {
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
        ZStack(alignment: .bottom) {
            Map(
                coordinateRegion: $region,
                annotationItems: annotations
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    Button {
                        select(annotation: annotation)
                    } label: {
                        let isSelected = isAnnotationSelected(annotation)
                        Image(systemName: isSelected ? "mappin.circle.fill"
                                                     : "mappin.circle")
                            .font(.system(size: 28))
                            .foregroundColor(isSelected ? .red : Color.yasasumaGreen)
                            .shadow(radius: 3)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 8) {
                if let selectedItem {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedItem.name ?? "名称なし")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text("上の検索欄で名称や住所を検索し、地図上のピンをタップして行き先を選択してください。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    if let selectedItem {
                        onSelect(selectedItem)
                        dismiss()
                    }
                } label: {
                    Text("この行き先を設定")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedItem == nil)
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("地図から行き先を選ぶ")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer,
            prompt: "名称や住所で検索"
        )
        .onSubmit(of: .search) {
            performSearch()
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                results = []
                selectedItem = nil
                selectedCoordinate = nil
            }
        }
    }

    // ピンとして表示する候補
    private var annotations: [MapSearchAnnotation] {
        if results.isEmpty, let selectedItem {
            return [MapSearchAnnotation(item: selectedItem)]
        } else {
            return results.map { MapSearchAnnotation(item: $0) }
        }
    }

    // このアノテーションが選択中かどうか（座標の緯度・経度で判定）
    private func isAnnotationSelected(_ annotation: MapSearchAnnotation) -> Bool {
        guard let selected = selectedCoordinate else { return false }
        return selected.latitude == annotation.coordinate.latitude
        && selected.longitude == annotation.coordinate.longitude
    }

    private func select(annotation: MapSearchAnnotation) {
        selectedItem = annotation.item
        selectedCoordinate = annotation.coordinate
        region.center = annotation.coordinate
    }

    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        results = []
        selectedItem = nil
        selectedCoordinate = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    results = response.mapItems
                    if let first = response.mapItems.first {
                        region.center = first.placemark.coordinate
                    }
                } else {
                    results = []
                }
            }
        }
    }
}

