// CameraView.swift

import SwiftUI
import AVFoundation
import Photos
import Combine

// MARK: - カメラ ViewModel

final class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "yasasuma.camera.session")
    private let photoOutput = AVCapturePhotoOutput()

    /// 左下サムネ＆プレビュー用
    @Published var lastPhoto: UIImage?

    override init() {
        super.init()
        configureSession()
        loadLatestPhotoThumbnail()
    }

    // 権限チェック + セッション構成
    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                self.setupSession()

            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setupSession()
                    }
                }

            case .denied, .restricted:
                break

            @unknown default:
                break
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo   // 4:3 ベース

        // 既存入力をクリア
        for input in session.inputs {
            session.removeInput(input)
        }

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input),
            session.canAddOutput(photoOutput)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true

        session.commitConfiguration()
        startSessionIfNeeded()
    }

    func startSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // 撮影
    func capture() {
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // 撮影完了 → そのまま保存（クロップしない）
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            print("capture error:", error)
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else { return }

        DispatchQueue.main.async {
            self.lastPhoto = image
        }

        saveToLibrary(image: image)
    }

    // 写真アプリに保存
    private func saveToLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: nil)
        }
    }

    // 最新写真のサムネイル読み込み
    private func loadLatestPhotoThumbnail() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { return }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1

        let result = PHAsset.fetchAssets(with: .image, options: options)
        guard let asset = result.firstObject else { return }

        let manager = PHImageManager.default()
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: 80 * scale, height: 80 * scale)

        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        ) { image, _ in
            if let image {
                DispatchQueue.main.async {
                    self.lastPhoto = image
                }
            }
        }
    }
}

// MARK: - カメラプレビュー

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.session)
        previewLayer.videoGravity = .resizeAspect   // 4:3 プレビューをそのまま表示
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - 撮った写真の全画面プレビュー（中央寄せ）

struct CameraPhotoPreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                // 画像を画面中央に表示
                VStack {
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: proxy.size.width,
                               maxHeight: proxy.size.height)
                    Spacer()
                }

                // 閉じるボタン（ナビバー位置に）
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 12)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - カメラ画面本体

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingLastPhoto = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            // 4:3 のカメラプレビュー
            let previewHeight = width * (4.0 / 3.0)
            let controlsHeight: CGFloat = 140

            // ベースのセンタリング
            let baseTopPadding = max((height - previewHeight) / 2, 0)
            let baseBottomPadding = max(baseTopPadding - controlsHeight, 0)

            // プレビューを「少しだけ上」に寄せるためのシフト量
            let verticalShift: CGFloat = 24

            let topPadding = max(baseTopPadding - verticalShift, 0)
            let bottomPadding = max(baseBottomPadding + verticalShift, 0)

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 上の黒背景
                    Spacer()
                        .frame(height: topPadding)

                    // カメラプレビュー（中央より少し上）
                    CameraPreview(viewModel: viewModel)
                        .frame(width: width, height: previewHeight)
                        .clipped()

                    // プレビューとコントロールの間の黒背景
                    Spacer()
                        .frame(height: bottomPadding)

                    // 下部コントロール（サムネ・シャッター）
                    HStack {
                        if let image = viewModel.lastPhoto {
                            Button {
                                showingLastPhoto = true
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                    )
                            }
                        } else {
                            Color.clear.frame(width: 60, height: 60)
                        }

                        Spacer()

                        Button {
                            viewModel.capture()
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.9), lineWidth: 4)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .fill(Color.white.opacity(0.95))
                                    .frame(width: 68, height: 68)
                            }
                        }

                        Spacer()

                        Color.clear.frame(width: 60, height: 60)
                    }
                    .frame(height: controlsHeight)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // 戻るボタンを「ナビゲーションバー位置」に固定
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, 16)

                        Spacer()
                    }
                    .padding(.top, 12)

                    Spacer()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.startSessionIfNeeded() }
        .onDisappear { viewModel.stopSessionIfNeeded() }
        .fullScreenCover(isPresented: $showingLastPhoto) {
            if let image = viewModel.lastPhoto {
                CameraPhotoPreviewView(image: image)
            }
        }
    }
}

