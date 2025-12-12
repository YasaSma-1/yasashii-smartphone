import SwiftUI
import MapKit
import CoreLocation

private let freeDestinationLimit = 2

private enum DestinationSheet: Identifiable {
    case edit(Destination?)   // nil = 新規
    case paywall

    var id: String {
        switch self {
        case .edit(let d):
            return d.map { "edit-\($0.id.uuidString)" } ?? "edit-new"
        case .paywall:
            return "paywall"
        }
    }
}

struct DestinationSettingsView: View {
    @EnvironmentObject var destinationStore: DestinationStore
    @EnvironmentObject var purchaseStore: PurchaseStore

    @State private var editMode: EditMode = .inactive
    @State private var activeSheet: DestinationSheet?

    // ✅ 複数選択
    @State private var selection: Set<UUID> = []
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { editMode == .active }

    var body: some View {
        List(selection: $selection) {
            Section {
                if destinationStore.destinations.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("まだ登録されていません")
                            .font(.system(size: 16, weight: .semibold))

                        Text("右上の「＋」から追加できます。")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(destinationStore.destinations) { destination in
                        if isEditing {
                            DestinationSettingsRow(destination: destination, showChevron: false)
                                .tag(destination.id)
                        } else {
                            Button {
                                activeSheet = .edit(destination)
                            } label: {
                                DestinationSettingsRow(destination: destination, showChevron: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("「地図」画面に出す場所を設定します。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("無料版では 2件 まで登録できます。")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .textCase(nil)
                .padding(.top, 6)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6))
        .navigationTitle("よく行く場所")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .onChange(of: editMode) { _, newValue in
            if newValue == .inactive { selection.removeAll() }
        }
        .toolbar {
            // 右上：編集（＋の左）
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        editMode = isEditing ? .inactive : .active
                    }
                }
                .font(.system(size: 16, weight: .semibold))
            }

            // 右上：＋（右端）※右余白確保
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    handleAddTapped()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.trailing, 10)
                }
                .disabled(isEditing)
            }

            // ✅ 編集モードのみ：下ツールバーに削除
            if isEditing {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
        .confirmationDialog(
            "選択した \(selection.count) 件を削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { deleteSelected() }
            Button("キャンセル", role: .cancel) { }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit(let editing):
                DestinationEditSheet(
                    destination: editing,
                    onSave: { name, detail, coordinate in
                        if let editing {
                            if let idx = destinationStore.destinations.firstIndex(where: { $0.id == editing.id }) {
                                destinationStore.destinations[idx].name = name
                                destinationStore.destinations[idx].detail = detail
                                destinationStore.destinations[idx].coordinate = coordinate
                            }
                        } else {
                            destinationStore.destinations.append(
                                Destination(name: name, detail: detail, coordinate: coordinate)
                            )

                            if destinationStore.destinations.count >= 3 {
                                ReviewRequestManager.shared.maybeRequestReview(trigger: .addedDestinations)
                            }
                        }
                    },
                    onDelete: editing.map { target in
                        {
                            destinationStore.destinations.removeAll { $0.id == target.id }
                        }
                    }
                )

            case .paywall:
                PaywallView()
                    .environmentObject(purchaseStore)
            }
        }
    }

    private func handleAddTapped() {
        if purchaseStore.isProUnlocked {
            activeSheet = .edit(nil)
            return
        }

        if destinationStore.destinations.count >= freeDestinationLimit {
            activeSheet = .paywall
        } else {
            activeSheet = .edit(nil)
        }
    }

    private func deleteSelected() {
        let ids = selection
        destinationStore.destinations.removeAll { ids.contains($0.id) }
        selection.removeAll()
    }
}

// MARK: - Row

private struct DestinationSettingsRow: View {
    let destination: Destination
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yasasumaGreen)
                    .frame(width: 34, height: 34)
                Image(systemName: "mappin")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(destination.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                if !destination.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(destination.detail)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Edit Sheet（削除あり / 地図選択の名称も表示）

private struct DestinationEditSheet: View {
    let destination: Destination?
    let onSave: (String, String, CLLocationCoordinate2D) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var detail: String
    @State private var coordinate: CLLocationCoordinate2D?

    @State private var isPickerPresented = false
    @State private var pickedPlaceName: String? = nil
    @State private var showDeleteConfirm = false

    init(
        destination: Destination?,
        onSave: @escaping (String, String, CLLocationCoordinate2D) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.destination = destination
        self.onSave = onSave
        self.onDelete = onDelete

        _name = State(initialValue: destination?.name ?? "")
        _detail = State(initialValue: destination?.detail ?? "")
        _coordinate = State(initialValue: destination?.coordinate)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && coordinate != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("場所")) {
                    NavigationLink(isActive: $isPickerPresented) {
                        MapSearchPickerView(initialCoordinate: coordinate) { item in
                            let coord = item.yasasumaCoordinate
                            coordinate = coord

                            // まずは即時に name（見た目用）
                            pickedPlaceName = item.name ?? "選択した場所"

                            // 住所っぽいのは逆ジオで上書き（丸の内1丁目9みたいなやつ）
                            resolvePickedPlaceName(from: coord)

                            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                name = item.name ?? "選択した場所"
                            }
                        }
                    } label: {
                        // ✅ 右「選択済み/未選択」をセルの縦中央へ
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("地図から場所を選ぶ")
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)

                                if let pickedPlaceName, !pickedPlaceName.isEmpty {
                                    Text(pickedPlaceName)
                                        .font(.system(size: 17, weight: .semibold)) // ✅ secondary 17 semibold
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else if coordinate != nil {
                                    Text("（場所は選択済み）")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer(minLength: 12)

                            VStack {
                                Spacer(minLength: 0)
                                Text(coordinate == nil ? "未選択" : "選択済み")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("表示名")) {
                    TextField("例：病院 / スーパー / 駅", text: $name)
                }

                Section(header: Text("メモ")) {
                    TextField("例：かかりつけの病院", text: $detail)
                }

                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("削除")
                        }
                    }
                }
            }
            .navigationTitle(destination == nil ? "場所を追加" : "場所を編集")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 既存編集で coordinate はあるが pickedPlaceName がない時に埋める
                if pickedPlaceName == nil, let c = coordinate {
                    resolvePickedPlaceName(from: c)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let coordinate else { return }
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            detail.trimmingCharacters(in: .whitespacesAndNewlines),
                            coordinate
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "この場所を削除しますか？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) { }
            }
        }
    }

    private func resolvePickedPlaceName(from coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            DispatchQueue.main.async {
                guard let p = placemarks?.first else { return }
                let line =
                    [p.subLocality, p.thoroughfare, p.subThoroughfare]
                        .compactMap { $0 }
                        .joined(separator: "")
                if !line.isEmpty {
                    pickedPlaceName = line
                } else if let name = p.name, !name.isEmpty {
                    pickedPlaceName = name
                }
            }
        }
    }
}

//
// MARK: - 地図から行き先を選ぶ（検索＋既存スポット）
//

private struct MapSearchAnnotation: Identifiable {
    let id = UUID()
    let item: MKMapItem
    let coordinate: CLLocationCoordinate2D
}

struct MapSearchPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion
    @State private var searchText: String = ""
    @State private var results: [MKMapItem] = []

    @State private var selectedItem: MKMapItem? = nil
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil

    let onSelect: (MKMapItem) -> Void

    init(initialCoordinate: CLLocationCoordinate2D?,
         onSelect: @escaping (MKMapItem) -> Void) {
        self.onSelect = onSelect

        let center = initialCoordinate ?? CLLocationCoordinate2D(
            latitude: 35.6812,
            longitude: 139.7671
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
                        Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
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

    private var annotations: [MapSearchAnnotation] {
        let items: [MKMapItem] = results.isEmpty ? (selectedItem.map { [$0] } ?? []) : results
        return items.map { item in
            MapSearchAnnotation(item: item, coordinate: item.yasasumaCoordinate)
        }
    }

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

        results = []
        selectedItem = nil
        selectedCoordinate = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region

        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                if let response = response {
                    results = response.mapItems
                    if let first = response.mapItems.first {
                        region.center = first.yasasumaCoordinate
                    }
                } else {
                    results = []
                }
            }
        }
    }
}

// MARK: - MKMapItem helper（エラー回避版）

private extension MKMapItem {
    var yasasumaCoordinate: CLLocationCoordinate2D {
        if #available(iOS 26.0, *) {
            // ✅ location が non-optional なので ? を使わない（エラー回避）
            return self.location.coordinate
        } else {
            return self.placemark.coordinate
        }
    }
}

