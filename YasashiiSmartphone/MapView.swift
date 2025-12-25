import SwiftUI
import MapKit
import Combine
import CoreLocation

// MARK: - 行き先データ
struct Destination: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var detail: String
    var coordinate: CLLocationCoordinate2D

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }
}

// ✅ デフォルトは空（設定から追加）
final class DestinationStore: ObservableObject {
    @Published var destinations: [Destination] = []
}

// MARK: - ① 行き先一覧（タブの「地図」）
struct MapView: View {
    @EnvironmentObject var destinationStore: DestinationStore
    @State private var showUnifiedMapSheet = false

    // 空状態に🔒を出すため（プロジェクト側のキーに合わせて）
    @AppStorage("yasasumaPasscodeEnabled") private var passcodeEnabled: Bool = false
    @AppStorage("yasasumaPasscodeValue") private var storedPasscode: String = ""

    private var isSettingsLocked: Bool {
        passcodeEnabled && storedPasscode.filter { $0.isNumber }.count == 4
    }

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("道をみる")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("よく行く場所")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))

                    Text("行きたい場所をえらぶと、地図がひらきます。")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    if destinationStore.destinations.isEmpty {
                        MapEmptyStateCard(isLocked: isSettingsLocked)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(destinationStore.destinations) { destination in
                                NavigationLink {
                                    UnifiedMapView(destination: destination)
                                } label: {
                                    DestinationRow(destination: destination)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    showUnifiedMapSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "map.fill")
                        Text("地図をひらく")
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.yasasumaGreen)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showUnifiedMapSheet) {
            UnifiedMapSheet()
        }
    }
}

// MARK: - 空状態カード（地図）
private struct MapEmptyStateCard: View {
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.yasasumaGreen))

                Text("行き先がまだありません")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }

            Text(isLocked
                 ? "サポートする人が「設定」で登録すると、ここに表示されます。"
                 : "「設定」で登録すると、ここに表示されます。")
            .font(.system(size: 15))
            .foregroundColor(.secondary)

            NavigationLink {
                SettingsPasscodeGate {
                    DestinationSettingsView()
                }
            } label: {
                HStack(spacing: 10) {
                    if isLocked { Image(systemName: "lock.fill") }
                    Image(systemName: "gearshape.fill")
                    Text("設定で登録する")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.yasasumaGreen)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
}

// MARK: - 行き先カード
struct DestinationRow: View {
    let destination: Destination

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 26))
                .foregroundColor(.white)
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.yasasumaGreen)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(destination.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                if !destination.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(destination.detail)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.8), radius: 3, x: -2, y: -2)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 3)
        )
    }
}

// MARK: - Location
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { self.lastLocation = location }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}

// MARK: - 共通の地図（現在地 / 目的地）
private enum PinKind { case destination }

private struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let kind: PinKind
}

struct UnifiedMapView: View {
    let destination: Destination?   // nil = 「地図をひらく」から来た

    @Environment(\.openURL) private var openURL
    @StateObject private var locationManager = LocationManager()

    @State private var region: MKCoordinateRegion
    @State private var hasCenteredOnce = false
    @State private var userHasInteracted = false

    @AppStorage("hasSeenMapReturnHint") private var hasSeenMapReturnHint: Bool = false
    @State private var showReturnHint = false
    @State private var pendingRouteCoordinate: CLLocationCoordinate2D? = nil

    init(destination: Destination?) {
        self.destination = destination
        if let dest = destination {
            _region = State(initialValue: MKCoordinateRegion(
                center: dest.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private var activeDestinationCoordinate: CLLocationCoordinate2D? {
        destination?.coordinate
    }

    private var pins: [MapPinItem] {
        var items: [MapPinItem] = []
        if let dest = destination {
            items.append(MapPinItem(coordinate: dest.coordinate, kind: .destination))
        }
        return items
    }

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: pins
            ) { item in
                MapMarker(coordinate: item.coordinate, tint: Color.yasasumaGreen)
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 1).onChanged { _ in userHasInteracted = true }
            )
            .simultaneousGesture(
                MagnificationGesture().onChanged { _ in userHasInteracted = true }
            )
            .onReceive(locationManager.$lastLocation) { loc in
                guard let loc else { return }
                guard !hasCenteredOnce else { return }
                guard !userHasInteracted else { return }

                if let dest = activeDestinationCoordinate {
                    region = regionFitting(user: loc.coordinate, dest: dest)
                } else {
                    region = MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                hasCenteredOnce = true
            }

            // ✅ 右下：現在地に戻る（「道順をひらく」が出る画面では非表示）
            if destination == nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { recenterToUser() } label: {
                            Label("現在地に戻る", systemImage: "location.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.yasasumaGreen)
                                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                                )
                                .opacity(locationManager.lastLocation == nil ? 0.5 : 1.0)
                        }
                        .disabled(locationManager.lastLocation == nil)
                        .padding(.trailing, 16)
                        .padding(.bottom, 24)
                    }
                }
            }

            if let destination {
                destinationBottomPanel(destination: destination)
            }

            if locationManager.lastLocation == nil {
                VStack {
                    Text("現在地をよみこんでいます…")
                        .font(.system(size: 18))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.92))
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        )
                    Spacer()
                }
                .padding(.top, 88)
            }
        }
        .navigationTitle("地図")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ✅ 「現在地と行き先を見る」＝ナビバーに（プライマリーカラー）
            if activeDestinationCoordinate != nil, locationManager.lastLocation != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { focusToUserAndDestination() } label: {
                        Text("現在地と行き先")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .tint(Color.yasasumaGreen)
                }
            }
        }
        .alert("Appleマップをひらきます", isPresented: $showReturnHint) {
            Button("やめる", role: .cancel) { pendingRouteCoordinate = nil }
            Button("ひらく") {
                hasSeenMapReturnHint = true
                if let coord = pendingRouteCoordinate { openInAppleMaps(to: coord) }
                pendingRouteCoordinate = nil
            }
        } message: {
            Text(
                """
                このあと「Appleマップ」がひらきます。

                もどるときは、
                ・画面左上の「戻る」ボタン か
                ・ホーム画面からもう一度「やさしいスマホ」
                をひらいてください。
                """
            )
        }
    }

    // MARK: - 下パネル（保存目的地）
    @ViewBuilder
    private func destinationBottomPanel(destination: Destination) -> some View {
        VStack(spacing: 12) {
            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(destination.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                if !destination.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(destination.detail)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 16)

            Button { startRoute(to: destination.coordinate) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                    Text("道順をひらく")
                }
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.yasasumaGreen)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Actions
    private func recenterToUser() {
        guard let user = locationManager.lastLocation?.coordinate else { return }
        region = MKCoordinateRegion(
            center: user,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        hasCenteredOnce = true
    }

    private func focusToUserAndDestination() {
        guard let user = locationManager.lastLocation?.coordinate else { return }
        guard let dest = activeDestinationCoordinate else { return }
        region = regionFitting(user: user, dest: dest)
        hasCenteredOnce = true
    }

    private func startRoute(to coordinate: CLLocationCoordinate2D) {
        pendingRouteCoordinate = coordinate
        if hasSeenMapReturnHint {
            openInAppleMaps(to: coordinate)
            pendingRouteCoordinate = nil
        } else {
            showReturnHint = true
        }
    }

    private func openInAppleMaps(to coordinate: CLLocationCoordinate2D) {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let urlString = "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=w"
        if let url = URL(string: urlString) { openURL(url) }
    }

    private func regionFitting(user: CLLocationCoordinate2D, dest: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let points = [MKMapPoint(user), MKMapPoint(dest)]
        var rect = MKMapRect.null
        for p in points {
            rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 0.1, height: 0.1))
        }
        rect = rect.insetBy(dx: -rect.size.width * 0.6, dy: -rect.size.height * 0.6)
        return MKCoordinateRegion(rect)
    }
}

// MARK: - sheet用（ナビバーに閉じるボタン）
private struct UnifiedMapSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            UnifiedMapView(destination: nil)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("とじる") { dismiss() }
                    }
                }
        }
    }
}

