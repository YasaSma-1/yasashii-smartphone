import SwiftUI
import MapKit
import CoreLocation
import Contacts

// このファイルは `Destination` / `DestinationStore` が他ファイル（MapView.swift等）で定義済み前提です。

// MARK: - DestinationSettingsView

struct DestinationSettingsView: View {
    @EnvironmentObject var destinationStore: DestinationStore
    @Environment(\.editMode) private var editMode

    @State private var activeSheet: Sheet? = nil

    // ✅ 複数選択用
    @State private var selectedIDs: Set<UUID> = []
    @State private var showBulkDeleteConfirm = false

    private var isEditing: Bool { editMode?.wrappedValue == .active }

    private enum Sheet: Identifiable {
        case add
        case edit(Destination)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let d): return "edit-\(d.id.uuidString)"
            }
        }
    }

    var body: some View {
        List {
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
                        row(destination)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // ✅ 編集モード中はスワイプ削除も出さない（赤丸マイナスも出ない）
                                if !isEditing {
                                    Button(role: .destructive) {
                                        deleteOne(destination.id)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                    }
                    // ✅ 並び替えはそのまま
                    .onMove(perform: move)
                }
            } header: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("「地図」画面に出す場所を設定します。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
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
        .toolbar {
            // 右上：編集 + 追加
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()

                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                }
                .disabled(isEditing)
                .opacity(isEditing ? 0.4 : 1.0)
            }

            // ✅ 画面下：一括削除（テキストで赤字）
            if isEditing {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showBulkDeleteConfirm = true
                    } label: {
                        Text("削除する")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .tint(.red)
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
        // ✅ 編集モードが終わったら選択クリア
        .onChange(of: editMode?.wrappedValue) { newValue in
            if newValue != .active {
                selectedIDs.removeAll()
            }
        }
        .confirmationDialog(
            "選択した場所を削除しますか？",
            isPresented: $showBulkDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { bulkDeleteSelected() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("選択した \(selectedIDs.count) 件を削除します。")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                DestinationEditSheetStyled(
                    mode: .add,
                    initial: nil,
                    onSave: { name, memo, coordinate in
                        destinationStore.destinations.append(
                            Destination(name: name, detail: memo, coordinate: coordinate)
                        )
                    },
                    onDelete: nil
                )

            case .edit(let d):
                DestinationEditSheetStyled(
                    mode: .edit,
                    initial: d,
                    onSave: { name, memo, coordinate in
                        if let idx = destinationStore.destinations.firstIndex(where: { $0.id == d.id }) {
                            destinationStore.destinations[idx].name = name
                            destinationStore.destinations[idx].detail = memo
                            destinationStore.destinations[idx].coordinate = coordinate
                        }
                    },
                    onDelete: {
                        destinationStore.destinations.removeAll { $0.id == d.id }
                    }
                )
            }
        }
    }

    // MARK: - Row（編集中は複数選択 / 通常は編集シート）

    @ViewBuilder
    private func row(_ destination: Destination) -> some View {
        let isSelected = selectedIDs.contains(destination.id)

        HStack(spacing: 12) {
            // ✅ 編集中だけチェックUI
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? Color.yasasumaGreen : Color(.systemGray3))
                    .padding(.trailing, 2)
            }

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

            if !isEditing {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                toggleSelection(for: destination.id)
            } else {
                activeSheet = .edit(destination)
            }
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func bulkDeleteSelected() {
        destinationStore.destinations.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
    }

    private func deleteOne(_ id: UUID) {
        destinationStore.destinations.removeAll { $0.id == id }
    }

    private func move(from source: IndexSet, to destination: Int) {
        destinationStore.destinations.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - 追加/編集シート（画像寄せ）

private struct DestinationEditSheetStyled: View {
    enum Mode { case add, edit }

    let mode: Mode
    let initial: Destination?
    let onSave: (String, String, CLLocationCoordinate2D) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var pickedName: String = ""
    @State private var pickedAddress: String = ""
    @State private var memo: String = ""
    @State private var coordinate: CLLocationCoordinate2D? = nil

    @State private var isPickerPresented = false
    @State private var showDeleteConfirm = false

    init(
        mode: Mode,
        initial: Destination?,
        onSave: @escaping (String, String, CLLocationCoordinate2D) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.mode = mode
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete

        _pickedName = State(initialValue: initial?.name ?? "")
        _memo = State(initialValue: initial?.detail ?? "")
        _coordinate = State(initialValue: initial?.coordinate)
        _pickedAddress = State(initialValue: "")
    }

    private var canSave: Bool {
        coordinate != nil && !pickedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("場所")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    Button { isPickerPresented = true } label: {
                        placeCard
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    Text("メモ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    memoField
                        .padding(.horizontal, 16)

                    Spacer()

                    if onDelete != nil, mode == .edit {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("削除")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white)
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.top, 14)
            }
            .navigationTitle(mode == .add ? "場所を追加" : "場所を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let coordinate else { return }
                        let name = pickedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let memoTrim = memo.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(name, memoTrim, coordinate)
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
                Button("キャンセル", role: .cancel) {}
            }
            .navigationDestination(isPresented: $isPickerPresented) {
                MapSearchPickerView(initialCoordinate: coordinate) { item in
                    let coord = item.yasasumaCoordinate
                    coordinate = coord

                    // ✅ 選び直しでも表示名（場所名）を更新
                    let title = (item.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    pickedName = title.isEmpty ? "選択した場所" : title

                    // ✅ 住所も更新
                    pickedAddress = item.yasasumaAddressLine
                    if pickedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        resolveAddressFallback(from: coord)
                    }

                    isPickerPresented = false
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("とじる") { isPickerPresented = false }
                    }
                }
            }
            .onAppear {
                if pickedAddress.isEmpty, let c = coordinate {
                    resolveAddressFallback(from: c)
                }
            }
        }
    }

    // ✅ 未選択の時は空白のリストを出さない
    private var placeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("地図から場所を選ぶ")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(coordinate == nil ? "未選択" : "選択済み")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if coordinate != nil {
                Divider().padding(.leading, 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text(pickedName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(pickedAddress)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22).fill(Color.white)
        )
    }

    private var memoField: some View {
        TextField("例：かかりつけの病院", text: $memo)
            .font(.system(size: 17))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
            )
    }

    private func resolveAddressFallback(from coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            DispatchQueue.main.async {
                guard let p = placemarks?.first else { return }
                let line = [
                    p.administrativeArea,
                    p.locality,
                    p.subLocality,
                    p.thoroughfare,
                    p.subThoroughfare
                ]
                .compactMap { $0 }
                .joined()
                if !line.isEmpty { pickedAddress = line }
            }
        }
    }
}

// MARK: - MapSearchPickerView（検索→ピンをタップ→決定）

private struct MapSearchAnnotation: Identifiable {
    let id = UUID()
    let item: MKMapItem
    let coordinate: CLLocationCoordinate2D
}

private struct MapSearchPickerView: View {
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
        let center = initialCoordinate ?? CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
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
                    .buttonStyle(.plain)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 10) {
                if let selectedItem {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedItem.name ?? "名称なし")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        let addr = selectedItem.yasasumaAddressLine
                        if !addr.isEmpty {
                            Text(addr)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(2)
                        }
                    }
                } else {
                    Text("ピンをタップして行き先を選択してください。")
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
                .tint(Color.yasasumaGreen)
                .disabled(selectedItem == nil)
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("地図から場所を選ぶ")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "名称や住所で検索")
        .onSubmit(of: .search) { performSearch() }
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
        return selected.latitude == annotation.coordinate.latitude &&
               selected.longitude == annotation.coordinate.longitude
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
                guard let response else {
                    results = []
                    return
                }
                results = response.mapItems
                if let first = response.mapItems.first {
                    region.center = first.yasasumaCoordinate
                }
            }
        }
    }
}

// MARK: - MKMapItem helper

private extension MKMapItem {
    var yasasumaCoordinate: CLLocationCoordinate2D {
        self.placemark.coordinate
    }

    var yasasumaAddressLine: String {
        let pm = self.placemark

        if let postal = pm.postalAddress {
            var line = ""
            if !postal.state.isEmpty { line += postal.state }
            if !postal.city.isEmpty { line += postal.city }
            if !postal.subLocality.isEmpty { line += postal.subLocality }
            if !postal.street.isEmpty { line += postal.street }
            return line
        }

        return [
            pm.administrativeArea,
            pm.locality,
            pm.subLocality,
            pm.thoroughfare,
            pm.subThoroughfare
        ]
        .compactMap { $0 }
        .joined()
    }
}

