import SwiftUI
import Photos
import Combine

// MARK: - ViewModel

@MainActor
final class PhotoLibraryViewModel: ObservableObject {
    @Published var status: PHAuthorizationStatus = .notDetermined
    @Published var assets: [PHAsset] = []

    /// サムネイル用にキャッシュ付きマネージャ
    let manager = PHCachingImageManager()

    func requestIfNeeded() {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        status = current

        switch current {
        case .authorized, .limited:
            loadAssets()

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.status = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        self.loadAssets()
                    }
                }
            }

        case .denied, .restricted:
            break

        @unknown default:
            break
        }
    }

    private func loadAssets() {
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            // 必要なら上限をかける
            // options.fetchLimit = 1000

            let result = PHAsset.fetchAssets(with: .image, options: options)
            var tmp: [PHAsset] = []
            tmp.reserveCapacity(result.count)

            result.enumerateObjects { asset, _, _ in
                tmp.append(asset)
            }

            DispatchQueue.main.async {
                self.assets = tmp
            }
        }
    }
}

// MARK: - サムネイル（正方形セル）

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let side: CGFloat
    let manager: PHCachingImageManager

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: side, height: side)
                    .overlay(
                        ProgressView().scaleEffect(0.7)
                    )
            }
        }
        .onAppear {
            loadIfNeeded()
        }
    }

    private func loadIfNeeded() {
        guard image == nil else { return }

        let targetSize = CGSize(width: side * 2, height: side * 2)

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                DispatchQueue.main.async {
                    self.image = result
                }
            }
        }
    }
}

// MARK: - 詳細表示（タップ後フルスクリーン）

struct PhotoDetailView: View {
    let asset: PHAsset
    let manager: PHCachingImageManager

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            loadIfNeeded()
        }
    }

    private func loadIfNeeded() {
        guard image == nil else { return }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            if let result {
                DispatchQueue.main.async {
                    self.image = result
                }
            }
        }
    }
}

// MARK: - アルバム本体（3列・正方形グリッド）

struct PhotoLibraryView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let spacing: CGFloat = 1
            let side = (totalWidth - spacing * 2) / 3

            Group {
                switch viewModel.status {
                case .notDetermined:
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("写真へのアクセスを確認しています…")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .denied, .restricted:
                    VStack(spacing: 12) {
                        Text("写真へのアクセスが許可されていません")
                            .font(.headline)

                        Text("iPhoneの「設定」アプリ → プライバシー → 写真 から、\n「やさスマ」のアクセスを許可してください。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .authorized, .limited:
                    if viewModel.assets.isEmpty {
                        VStack(spacing: 8) {
                            Text("写真がありません")
                                .foregroundColor(.secondary)
                            Text("カメラで撮影すると、ここに表示されます。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: spacing) {
                                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                                    NavigationLink {
                                        PhotoDetailView(
                                            asset: asset,
                                            manager: viewModel.manager
                                        )
                                    } label: {
                                        PhotoThumbnailView(
                                            asset: asset,
                                            side: side,
                                            manager: viewModel.manager
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                @unknown default:
                    Text("写真を読み込めませんでした")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.requestIfNeeded()
        }
    }
}

