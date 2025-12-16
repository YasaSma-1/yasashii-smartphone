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
    @State private var showCurrentLocationMap = false

    // 空状態に🔒を出すため
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
                    Text("行き先をえらぶ")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))

                    Text("行きたい場所をえらぶと、つぎの画面で地図と道順を表示します。")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    if destinationStore.destinations.isEmpty {
                        MapEmptyStateCard(isLocked: isSettingsLocked)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(destinationStore.destinations) { destination in
                                NavigationLink {
                                    DestinationMapView(destination: destination)
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
                    showCurrentLocationMap = true
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("今いる場所の地図をひらく")
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
        .sheet(isPresented: $showCurrentLocationMap) {
            CurrentLocationMapView()
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
                 ? "お子さんが「設定」で登録すると、ここに表示されます。"
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
                Text(destination.detail)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            Spacer()
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

// MARK: - 現在地マップ
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

struct CurrentLocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct CurrentLocationMapView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    private var annotations: [CurrentLocationAnnotation] {
        if let loc = locationManager.lastLocation {
            return [CurrentLocationAnnotation(coordinate: loc.coordinate)]
        } else {
            return []
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: annotations) { item in
                    MapMarker(coordinate: item.coordinate, tint: Color.yasasumaGreen)
                }
                .ignoresSafeArea(edges: .bottom)

                if locationManager.lastLocation == nil {
                    VStack {
                        Text("現在地をよみこんでいます…")
                            .font(.system(size: 18))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.9))
                            )
                        Spacer().frame(height: 40)
                    }
                }
            }
            .onReceive(locationManager.$lastLocation) { loc in
                guard let loc else { return }
                region = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            .navigationTitle("今いる場所の地図")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("とじる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 行き先ごとの地図＆ナビ
struct DestinationMapView: View {
    let destination: Destination
    @Environment(\.openURL) private var openURL

    @State private var region: MKCoordinateRegion

    @AppStorage("hasSeenMapReturnHint") private var hasSeenMapReturnHint: Bool = false
    @State private var showReturnHint = false

    init(destination: Destination) {
        self.destination = destination
        _region = State(initialValue: MKCoordinateRegion(
            center: destination.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(spacing: 16) {
                Map(coordinateRegion: $region, annotationItems: [destination]) { dest in
                    MapMarker(coordinate: dest.coordinate, tint: Color.yasasumaGreen)
                }
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .frame(height: 300)

                VStack(alignment: .leading, spacing: 8) {
                    Text(destination.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    if !destination.detail.isEmpty {
                        Text(destination.detail)
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }

                    Text("下のボタンを押すと、「Appleマップ」で道順を表示します。")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    if hasSeenMapReturnHint {
                        openInAppleMaps()
                    } else {
                        showReturnHint = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("この場所への道順をひらく")
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
        .navigationTitle(destination.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Appleマップをひらきます", isPresented: $showReturnHint) {
            Button("やめる", role: .cancel) { }
            Button("ひらく") {
                hasSeenMapReturnHint = true
                openInAppleMaps()
            }
        } message: {
            Text(
                """
                このあと「Appleマップ」がひらきます。

                道案内がおわったら、
                ・画面左上の「戻る」ボタン か
                ・ホーム画面からもう一度「やさしいスマホ」
                をひらくと、元の画面にもどれます。
                """
            )
        }
    }

    private func openInAppleMaps() {
        let lat = destination.coordinate.latitude
        let lon = destination.coordinate.longitude
        let urlString = "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=w"
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
}

