//
//  ContentView.swift
//  emocam
//
//  Created by XXX on 2026/05/22.
//

import SwiftUI
import PhotosUI
import UIKit
import CoreImage
import Mantis

class UIImageViewerView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()

    init(imageName: String) {
        super.init(frame: .zero)

        self.delegate = self
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 5.0
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false

        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

struct ContentView: View {
    //    setting up variables for selected image
    @State var selectUIImage: UIImage? = nil
    @State var frameWidth: CGFloat = 350
    @State var frameHeight: CGFloat = 420
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero /*alter size of image*/
    @State var selectedUIImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var frameScale: CGFloat = 1.0
    @State private var lastFrameScale: CGFloat = 1.0
    @State private var intensity: CGFloat = 0.1
    @State private var selectedFilter: String = "no filter"
    @State private var isCropViewShowing = false
    
    private let filterColors: [(name: String, color: UIColor?)] = [
        ("no filter", nil),
        ("hush", .systemBlue),
        ("drift", .systemMint),
        ("echo", .systemIndigo),
        ("muse", .systemPurple),
        ("haven", .systemOrange),
        ("solace", .systemPink)
    ]

    private var selectedColor: UIColor? {
        filterColors.first { $0.name == selectedFilter }?.color
    }
    
    var body: some View {
        VStack(spacing: 25) {
            imageWithFrame

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Choose Image")
                    .padding()
                    .background(.clear)
                    .foregroundStyle(.black)
                    .clipShape(.capsule)
            }

            Button("Crop Image") {
                isCropViewShowing = true
            }
            .padding()
            .background(selectedUIImage == nil ? .gray : .blue)
            .foregroundStyle(.black)
            .clipShape(.capsule)
            .disabled(selectedUIImage == nil)
        }
        .padding()
        .onChange(of: selectedItem) {
            loadImage()
        }
        .fullScreenCover(isPresented: $isCropViewShowing) {
            if let _ = selectedUIImage {
                ImageCropper(
                    image: $selectedUIImage,
                    isCropViewShowing: $isCropViewShowing
                )
                .ignoresSafeArea()
            }
        }
    }
    
    //    setting up frame
    var imageWithFrame: some View {
        VStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .fill(.white)
                    .frame(width: 350 * frameScale, height: 520 * frameScale)
                    .shadow(radius: 10)
               
                Rectangle()
                    .fill(.white)
                    .frame(width: frameWidth, height: frameHeight)

                if let uiImage = selectedUIImage {
                    Image(
                        uiImage: applyColorFilter(
                            to: uiImage,
                            color: selectedColor
                        )
                    )
                    .resizable()
                    .scaledToFill()
                    .frame(width: frameWidth, height: frameHeight)
                    .scaleEffect(scale)
                    .offset(offset)
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = min(max(newScale, 0.5), 5.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                }
            }

            // filter picker under the frame
            VStack(spacing: 8) {
                Text(selectedFilter)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(filterColors, id: \.name) { item in
                            Button(action: {
                                selectedFilter = item.name
                            }) {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(uiColor: item.color ?? .lightGray))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedFilter == item.name
                                                    ? Color.blue
                                                    : Color.gray.opacity(0.3),
                                                    lineWidth: 2
                                                )
                                        )

                                    Text(item.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 10)
        }
    }

    private func applyColorFilter(
        to image: UIImage,
        color: UIColor?
    ) -> UIImage {
        guard let color else {
            return image
        }

        let normalizedImage = image.normalizedForEditing()

        guard let ciImage = CIImage(image: normalizedImage) else {
            return image
        }

        let overlay = CIImage(
            color: CIColor(color: color)
        ).cropped(to: ciImage.extent)

        guard let filter = CIFilter(name: "CIMultiplyCompositing")
        else { return image }

        filter.setValue(overlay, forKey: kCIInputImageKey)
        filter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)

        guard let output = filter.outputImage else {
            return image
        }

        let context = CIContext()

        guard let cgImage = context.createCGImage(
            output,
            from: output.extent
        ) else {
            return image
        }

        return UIImage(
            cgImage: cgImage,
            scale: normalizedImage.scale,
            orientation: .up
        )
    }

    private func loadImage() {
        guard let item = selectedItem else { return }

        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        selectedUIImage = uiImage.normalizedForEditing()
                        selectedFilter = "no filter"
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            case .failure(let error):
                print("failed to get Image: \(error.localizedDescription)")
            }
        }
    }
}

struct ImageViewer: UIViewRepresentable {
    let imageName: String
    
    func makeUIView(context: Context) -> UIImageViewerView {
        let view = UIImageViewerView(imageName: imageName)
        return view
    }
    
    func updateUIView(_ uiView: UIImageViewerView, context: Context) {}
}

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isCropViewShowing: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CropViewController {
        var config = Mantis.Config()
        config.cropShapeType = .rect
        config.presetFixedRatioType = .canUseMultiplePresetFixedRatio()

        let cropViewController = Mantis.cropViewController(
            image: image?.normalizedForEditing() ?? UIImage(),
            config: config
        )
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {}

    final class Coordinator: NSObject, CropViewControllerDelegate {
        private let parent: ImageCropper

        init(_ parent: ImageCropper) {
            self.parent = parent
        }

        func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
            parent.isCropViewShowing = false
        }

        func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
            parent.isCropViewShowing = false
        }

        func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {}

        func cropViewControllerDidEndResize(
            _ cropViewController: CropViewController,
            original: UIImage,
            cropInfo: CropInfo
        ) {}

        func cropViewControllerDidCrop(
            _ cropViewController: CropViewController,
            cropped: UIImage,
            transformation: Transformation,
            cropInfo: CropInfo
        ) {
            parent.image = cropped.normalizedForEditing()
            parent.isCropViewShowing = false
        }
    }
}

private extension UIImage {
    func normalizedForEditing() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}


    #Preview {
        ContentView()
    }
