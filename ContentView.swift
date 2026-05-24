//
//  ContentView.swift
//  emocam
//
//  Created by 井上　希稟 on 2026/05/22.
//

import SwiftUI
import PhotosUI
import UIKit
import CoreImage

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
                Text("Choose Photo")
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(.capsule)
            }
        }
        .padding()
        .onChange(of: selectedItem) {
            loadImage()
        }
    }
    
    //    setting up frame
    var imageWithFrame: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(.white)
                    .frame(width: 350 * frameScale, height: 520 * frameScale)
                    .shadow(radius: 10)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: frameWidth, height: frameHeight)
                if let uiImage = selectedUIImage {
                    ZStack {
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
                                .onEnded { _ in lastScale = scale }
                        )
                        
                    }
                }

                VStack(spacing: 8) {
                    Text(selectedFilter)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(filterColors, id: \.name) { item in
                                Button(action: { selectedFilter = item.name }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(uiColor: item.color ?? .lightGray))
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedFilter == item.name ? Color.blue : Color.gray.opacity(0.3),
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
    }
    private func applyColorFilter(
        to image: UIImage,
        color: UIColor?
    ) -> UIImage {
        guard let color else {
            return image
        }

        guard let ciImage = CIImage(image: image) else {
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

        return UIImage(cgImage: cgImage)
    }

    private func loadImage() {
        guard let item = selectedItem else { return }

        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        selectedUIImage = uiImage
                    }
                }
            case .failure(let error):
                print("failed to get Image: \(error.localizedDescription)")
            }
        }
    }
}

class CustomFilter: CIFilter {
    var kernel: CIKernel!
    var inputImage: CIImage?

    override init() {
        super.init()
        self.kernel = createKernel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.kernel = createKernel()
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }

        let dod = inputImage.extent.insetBy(dx: -1, dy: -1)
        let args = [inputImage]

        return kernel.apply(
            extent: dod,
            roiCallback: { index, rect in
                return rect.insetBy(dx: -1, dy: -1)
            },
            arguments: args
        )
    }
    func applyColorFilter(to image: UIImage, filterName: String) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter: CIFilter?

        switch filterName {
        case "Vivid":
            filter = CIFilter(name: "CIColorControls")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(1.8, forKey: kCIInputSaturationKey)
            filter?.setValue(0.05, forKey: kCIInputBrightnessKey)
            filter?.setValue(1.25, forKey: kCIInputContrastKey)

        default:
            return image
        }

        guard let outputImage = filter?.outputImage else { return image }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    private func createKernel() -> CIKernel {
        let kernelString =
        """
        kernel vec4 RGB_to_GBR(sampler source_image)
        {
            vec4 originalColor, twistedColor;
            originalColor = sample(source_image, samplerCoord(source_image));
            twistedColor.r = originalColor.g;
            twistedColor.g = originalColor.b;
            twistedColor.b = originalColor.r;
            twistedColor.a = originalColor.a;
            return twistedColor;
        }
        """

        guard let kernel = CIKernel(source: kernelString) else {
            fatalError("Failed to create kernel")
        }

        return kernel
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

    #Preview {
        ContentView()
    }
